# 坐标：`e2bserver`

E2B Panel / Worker **无业务仓 clone** 部署。二进制与沙箱镜像来自私有仓 CI 打的 ACR tag（如 `release-v1.0.1`）。

Author: kejiqing

## 前置

- Linux + **`docker`**（默认；也可用 `E2B_CONTAINER_RUNTIME=podman`）+ `curl`
- 发版 tag 的 Build CI 已成功（ACR 能拉到镜像）
- 本仓库为公开仓，生产可直接 curl

## Panel

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/passionke/deploy-all-in-one@main/e2bserver/bootstrap-panel.sh \
  -o bootstrap-panel.sh

E2B_IMAGE_TAG=release-v1.0.1 bash bootstrap-panel.sh
```

默认安装目录：`/opt/e2bserver`。默认运行时：`docker`。

**配置只认一个文件：** `$INSTALL_DIR/config/deploy.toml`

- 首次安装会生成该文件；之后再跑 bootstrap **不会覆盖**它（只升级二进制/镜像并重启）
- 改域名：只改文件里的 `sandbox_domain`，然后重跑 bootstrap 或重启进程  
  例：`sandbox_domain = "prod.spone.xyz"`
- **不要**用环境变量管域名

```bash
# 改域名示例
$EDITOR /opt/e2bserver/config/deploy.toml   # 或你的 E2B_INSTALL_DIR
# 重启（可再次执行 bootstrap，或）
pkill -f 'e2bserver run'; sleep 1
E2B_CONFIG=/opt/e2bserver/config/deploy.toml \
  nohup /opt/e2bserver/bin/e2bserver run >>/opt/e2bserver/e2bserver.log 2>&1 &
```

记下 Worker 要用的 token：

```bash
grep worker_token /opt/e2bserver/config/deploy.toml
# 或
cat /opt/e2bserver/config/.worker-token
```

## Worker（在 Worker 本机）

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/passionke/deploy-all-in-one@main/e2bserver/bootstrap-worker.sh \
  -o bootstrap-worker.sh

E2B_IMAGE_TAG=release-v1.0.1 \
E2B_PANEL_URL='http://<Panel-IP>:3000' \
E2B_WORKER_TOKEN='<上面 token>' \
E2B_ADVERTISE_HOST='<本机IP>' \
E2B_WORKER_ADDR='0.0.0.0:3100' \
E2B_MAX_SANDBOXES=4 \
  bash bootstrap-worker.sh
```

默认安装目录：`/opt/e2b-worker`。

## 升版本

只改 `E2B_IMAGE_TAG=release-vX.Y.Z`，重跑同一条命令即可（无需 git）。

## 环境变量速查

| 变量 | Panel | Worker | 说明 |
|------|-------|--------|------|
| `E2B_IMAGE_TAG` | 推荐 | 推荐 | ACR 镜像 tag |
| `E2B_INSTALL_DIR` | 可选 | 可选 | Panel 默认 `/opt/e2bserver`；Worker 默认 `/opt/e2b-worker` |
| `E2B_PANEL_URL` | — | 必填 | Panel API |
| `E2B_WORKER_TOKEN` | — | 必填 | 与 Panel `deploy.toml` 里 `[cluster].worker_token` 一致 |
| `E2B_ADVERTISE_HOST` | — | 远程必填 | Panel 回连 Worker 的 IP |
| `E2B_WORKER_ADDR` / `E2B_MAX_SANDBOXES` | — | 可选 | 端口与容量 |
| `ACR_USERNAME` / `ACR_PASSWORD` | 私有仓 | 私有仓 | |

域名、api_key、NAS 等：**只改 Panel 的 `config/deploy.toml`**，不用环境变量。

**不用 `.env`，不用 clone `e2bserver` 私有仓。**
