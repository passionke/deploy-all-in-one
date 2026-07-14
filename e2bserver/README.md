# 坐标：`e2bserver`

E2B Panel / Worker **无业务仓 clone** 部署。二进制与沙箱镜像来自私有仓 CI 打的 ACR tag（如 `release-v1.0.1`）。

Author: kejiqing

## 前置

- Linux + **`docker`**（默认；也可用 `E2B_CONTAINER_RUNTIME=podman`）+ `curl`
- 发版 tag 的 Build CI 已成功（ACR 能拉到镜像）
- 本仓库为公开仓，生产可直接 curl

## Panel

```bash
curl -fL https://raw.githubusercontent.com/passionke/deploy-all-in-one/main/e2bserver/bootstrap-panel.sh \
  -o bootstrap-panel.sh

bash bootstrap-panel.sh release-v1.0.1
```

域名 / NAS / api_key：只改 `$INSTALL_DIR/config/deploy.toml`，bootstrap 不会覆盖已有文件。

## Worker

```bash
# 一次性：稳定配置
cat > .env <<'EOF'
E2B_PANEL_URL=http://10.8.0.9:3000
E2B_WORKER_TOKEN=e2b_wk_xxx
E2B_ADVERTISE_HOST=10.8.0.11
EOF

curl -fL https://raw.githubusercontent.com/passionke/deploy-all-in-one/main/e2bserver/bootstrap-worker.sh \
  -o bootstrap-worker.sh

# 每次部署：版本写在命令里
bash bootstrap-worker.sh release-v1.0.1
```

`.env` 模板见 [`.env.worker.example`](.env.worker.example)。

默认安装目录：`/opt/e2b-worker`。

## 升版本

只改 `E2B_IMAGE_TAG=release-vX.Y.Z`，重跑同一条命令即可（无需 git）。

## 约定

| 项 | 放哪 |
|----|------|
| 版本 tag | **命令行参数**：`bash bootstrap-*.sh release-v1.0.1` |
| Worker 稳定连接 | **`.env`**：`E2B_PANEL_URL` / `E2B_WORKER_TOKEN` / `E2B_ADVERTISE_HOST` |
| Panel 域名/NAS/api_key | **`deploy.toml` only**（bootstrap 不覆盖已有文件） |

Worker `.env` 模板：复制 `.env.worker.example` → `.env`。
