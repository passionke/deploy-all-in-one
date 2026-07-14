# 坐标：`e2bserver`

E2B Panel / Worker **无业务仓 clone** 部署。二进制与沙箱镜像来自私有仓 CI 打的 ACR tag（如 `release-v1.0.1`）。

Author: kejiqing

## 前置

- Linux + **`docker`**（默认；也可用 `E2B_CONTAINER_RUNTIME=podman`）+ `curl`
- 发版 tag 的 Build CI 已成功（ACR 能拉到镜像）
- 本仓库为公开仓，生产可直接 curl

## Panel

```bash
curl -fsSL https://raw.githubusercontent.com/passionke/deploy-all-in-one/main/e2bserver/bootstrap-panel.sh \
  -o bootstrap-panel.sh

E2B_IMAGE_TAG=release-v1.0.1 bash bootstrap-panel.sh

# 记下 Worker 要用的 token
cat /opt/e2bserver/config/.worker-token
```

默认安装目录：`/opt/e2bserver`。

## Worker（在 Worker 本机）

```bash
curl -fsSL https://raw.githubusercontent.com/passionke/deploy-all-in-one/main/e2bserver/bootstrap-worker.sh \
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
| `E2B_IMAGE_TAG` | 推荐必填 | 推荐必填 | ACR 镜像 tag，与发版一致 |
| `E2B_PANEL_URL` | — | 必填 | Panel API，如 `http://10.8.0.9:3000` |
| `E2B_WORKER_TOKEN` | 可选（自动生成） | 必填 | 与 Panel `cluster.worker_token` 一致 |
| `E2B_ADVERTISE_HOST` | — | 远程节点必填 | Panel 用来连回 Worker 的 IP |
| `E2B_WORKER_ADDR` | — | 可选 | 默认 `0.0.0.0:3100` |
| `E2B_MAX_SANDBOXES` | — | 可选 | 默认 `4`（即 worker-num） |
| `ACR_REGISTRY` | 可选 | 可选 | 默认真网 ACR 命名空间 |
| `ACR_USERNAME` / `ACR_PASSWORD` | 私有仓时 | 私有仓时 | 登录 ACR |

**不用 `.env`，不用 clone `e2bserver` 私有仓。**
