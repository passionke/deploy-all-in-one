#!/usr/bin/env bash
# Panel 节点一键部署：全部从 ACR 拉取，无需业务仓 git — Author: kejiqing
#
# 项目坐标：e2bserver（公开仓 passionke/deploy-all-in-one）
#
#   curl -fsSL https://cdn.jsdelivr.net/gh/passionke/deploy-all-in-one@main/e2bserver/bootstrap-panel.sh \
#     -o bootstrap-panel.sh
#   E2B_IMAGE_TAG=release-v1.0.1 bash bootstrap-panel.sh
#
# 配置单一真相：INSTALL_DIR/config/deploy.toml
#   - 文件已存在 → 只升级二进制/镜像并重启，绝不覆盖配置
#   - 首次安装 → 写默认 deploy.toml（域名等请直接改这个文件，然后重启）
#
# Env（尽量少）：
#   E2B_IMAGE_TAG          推荐：release-v1.0.1
#   E2B_INSTALL_DIR        默认 /opt/e2bserver
#   E2B_CONTAINER_RUNTIME  默认 docker
#   ACR_USERNAME / ACR_PASSWORD  仅私有 ACR 需要
# script-rev: 2026-07-14-config-first
set -euo pipefail

RUNTIME="${E2B_CONTAINER_RUNTIME:-docker}"
export E2B_CONTAINER_RUNTIME="$RUNTIME"
INSTALL_DIR="${E2B_INSTALL_DIR:-/opt/e2bserver}"
TOKEN_FILE="$INSTALL_DIR/config/.worker-token"
PANEL_CONFIG="$INSTALL_DIR/config/deploy.toml"
PANEL_LOG="$INSTALL_DIR/e2bserver.log"
ACR_REGISTRY="${ACR_REGISTRY:-crpi-cf9vxpq3n8or17mw.cn-hangzhou.personal.cr.aliyuncs.com/passionke}"

die() { echo "error: $*" >&2; exit 1; }

if [[ "$(uname -s)" == "Darwin" ]]; then
  die "macOS cannot use ACR Linux binary — run on a Linux Panel host"
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

detect_arch_tag() {
  case "$(uname -m)" in
    x86_64) echo amd64 ;;
    aarch64|arm64) echo arm64 ;;
    *) die "unsupported arch: $(uname -m)" ;;
  esac
}

image_tag() {
  if [[ -n "${E2B_IMAGE_TAG:-}" ]]; then
    echo "$E2B_IMAGE_TAG"
  else
    detect_arch_tag
  fi
}

acr_login_if_needed() {
  local host="${ACR_REGISTRY%%/*}" user="${ACR_USERNAME:-${ACR_USER:-}}"
  if [[ -n "$user" && -n "${ACR_PASSWORD:-}" ]]; then
    echo "$ACR_PASSWORD" | "$RUNTIME" login "$host" -u "$user" --password-stdin
  fi
}

pull_and_extract() {
  local tag ref cid
  tag="$(image_tag)"
  ref="${ACR_REGISTRY%/}/e2b-binaries:${tag}"
  echo "==> pull $ref"
  acr_login_if_needed
  "$RUNTIME" pull "$ref" || die "failed to pull $ref — wait for release CI / check tag"

  mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/config" "$INSTALL_DIR/data"
  cid="$("$RUNTIME" create "$ref")"
  "$RUNTIME" cp "$cid:/opt/e2b/bin/e2bserver" "$INSTALL_DIR/bin/e2bserver"
  "$RUNTIME" cp "$cid:/opt/e2b/bin/e2b-worker" "$INSTALL_DIR/bin/e2b-worker" 2>/dev/null || true
  "$RUNTIME" rm "$cid" >/dev/null
  chmod 755 "$INSTALL_DIR/bin/e2bserver"
  [[ -f "$INSTALL_DIR/bin/e2b-worker" ]] && chmod 755 "$INSTALL_DIR/bin/e2b-worker"
  echo "==> installed $INSTALL_DIR/bin/e2bserver"
}

pull_base() {
  local tag ref
  tag="$(image_tag)"
  ref="${ACR_REGISTRY%/}/e2b-base:${tag}"
  echo "==> pull $ref"
  acr_login_if_needed
  "$RUNTIME" pull "$ref" || die "failed to pull $ref"
  "$RUNTIME" tag "$ref" e2b-base:latest
  echo "==> e2b-base:latest ← $ref"
}

# Read worker_token from existing deploy.toml [cluster] if present.
read_cluster_token() {
  [[ -f "$PANEL_CONFIG" ]] || return 0
  awk '
    /^\[cluster\]/ { in_c=1; next }
    /^\[/ { in_c=0 }
    in_c && $1 == "worker_token" {
      gsub(/^[^=]+=[[:space:]]*/, "")
      gsub(/^"/, ""); gsub(/"$/, "")
      print
      exit
    }
  ' "$PANEL_CONFIG"
}

ensure_token() {
  local token
  token="$(read_cluster_token)"
  if [[ -n "$token" ]]; then
    mkdir -p "$(dirname "$TOKEN_FILE")"
    printf '%s' "$token" >"$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo "$token"
    return
  fi
  if [[ -f "$TOKEN_FILE" ]]; then
    cat "$TOKEN_FILE"
    return
  fi
  token="e2b_wk_$(openssl rand -hex 16 2>/dev/null || date +%s)"
  mkdir -p "$(dirname "$TOKEN_FILE")"
  printf '%s' "$token" >"$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  echo "$token"
}

# Config-first: never overwrite an existing deploy.toml.
write_config_if_missing() {
  local token="$1"
  if [[ -f "$PANEL_CONFIG" ]]; then
    echo "==> keep existing config: $PANEL_CONFIG"
    echo "    (edit sandbox_domain / api_key / nas here; re-run bootstrap only upgrades binaries)"
    return 0
  fi

  cat >"$PANEL_CONFIG" <<EOF
# generated once by bootstrap-panel.sh — Author: kejiqing
# Single source of truth. Edit this file for domain / keys / NAS; bootstrap will not overwrite it.
api_key = "e2b_53ae1fed82754c17ad8077fbc8bcdd90"
api_addr = "0.0.0.0:3000"
proxy_addr = "0.0.0.0:3002"
traffic_addr = "0.0.0.0:3001"
sandbox_domain = "supone.top"
traffic_ports = [3000, 7681, 8080]
admin_auth = false
data_dir = "$INSTALL_DIR/data"
container_runtime = "$RUNTIME"
default_timeout_secs = 300
base_image = "e2b-base:latest"
envd_version = "0.1.3"
health_wait_timeout_secs = 30

[cluster]
enabled = true
worker_token = "$token"

[nas]
server = "nfs.supone.top"
export = "/mnt/NAS0/nfs-export"
host_mount_root = "/mnt/nas0"
nfs_version = "3"
sandbox_inject = "bind"
mount_options_linux = "vers=3,nolock,rw,hard,intr"

[templates_ci]
enabled = false
acr_registry = "${ACR_REGISTRY}"
image_repo = "e2b-templates"
github_repo = "passionke/e2bserver"
workflow_file = "template-build.yml"
git_ref = "main"
ci_token = ""
github_token = ""
panel_public_url = ""
oss_endpoint = ""
oss_bucket = ""
oss_access_key_id = ""
oss_access_key_secret = ""
oss_context_prefix = "template-builds"
oss_download_url_secs = 86400
oss_context_ttl_days = 30
EOF
  chmod 600 "$PANEL_CONFIG"
  echo "==> wrote first-time config: $PANEL_CONFIG"
  echo "    set sandbox_domain in this file (e.g. prod.spone.xyz), then restart / re-run bootstrap"
}

start_panel() {
  pkill -f "$INSTALL_DIR/bin/e2bserver run" 2>/dev/null || true
  pkill -f "e2bserver run" 2>/dev/null || true
  sleep 1
  nohup env E2B_CONFIG="$PANEL_CONFIG" \
    "$INSTALL_DIR/bin/e2bserver" run >>"$PANEL_LOG" 2>&1 &
  local pid=$!
  echo "==> e2bserver pid=$pid config=$PANEL_CONFIG log=$PANEL_LOG"

  local i
  for i in $(seq 1 40); do
    if curl -sf http://127.0.0.1:3000/healthz >/dev/null 2>&1; then
      echo "==> healthz ok"
      return 0
    fi
    sleep 0.5
    kill -0 "$pid" 2>/dev/null || { echo "panel exited — see $PANEL_LOG"; tail -30 "$PANEL_LOG" >&2; exit 1; }
  done
  die "healthz timeout — see $PANEL_LOG"
}

main() {
  require_cmd curl
  require_cmd "$RUNTIME"
  [[ -n "${E2B_IMAGE_TAG:-}" ]] || echo "==> warning: E2B_IMAGE_TAG unset, using arch tag $(detect_arch_tag)"

  echo "==> install dir: $INSTALL_DIR"
  echo "==> image tag: $(image_tag) (ACR_REGISTRY=$ACR_REGISTRY)"

  pull_and_extract
  pull_base

  local token
  token="$(ensure_token)"
  write_config_if_missing "$token"
  # token file always mirrors config (after first write, read again)
  token="$(ensure_token)"
  start_panel

  echo ""
  echo "panel ready."
  echo "  admin:  http://127.0.0.1:3000/admin"
  echo "  config: $PANEL_CONFIG   ← edit sandbox_domain / keys here only"
  echo "  worker token: $token"
}

main "$@"
