# deploy-all-in-one

公开、干净的**部署脚本仓库**。生产机无需访问私有业务仓库（如 `e2bserver`），只需从本仓库拉取对应**项目坐标**下的脚本，二进制/镜像仍从 ACR（或各服务约定的 registry）拉取。

Author: kejiqing

## 项目坐标（坐标空间）

每个线上可部署服务占一个**一级目录**，目录名即**项目坐标**：

```
deploy-all-in-one/
├── README.md                 # 本说明
├── COORDINATES.md            # 坐标登记表（新增服务必改）
└── <project-coord>/          # 例：e2bserver/
    ├── README.md             # 该服务部署说明
    └── *.sh                  # 该服务引导脚本
```

| 约定 | 规则 |
|------|------|
| 坐标名 | 小写、短横线或单词，与服务名一致（例：`e2bserver`） |
| 路径 | 仓库根下 `/<project-coord>/` |
| raw 地址 | `https://raw.githubusercontent.com/passionke/deploy-all-in-one/main/<project-coord>/<file>` |
| 禁止 | 塞业务源码、密钥、私有配置；此仓只放**公开部署脚本与说明** |

登记新服务：在 [`COORDINATES.md`](COORDINATES.md) 加一行，并新建对应目录。

## 当前坐标

见 [`COORDINATES.md`](COORDINATES.md)。

## 生产最小用法（无 git clone 业务仓）

> **国内建议用 jsDelivr**（`raw.githubusercontent.com` 易缓存旧脚本）。

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/passionke/deploy-all-in-one@main/e2bserver/bootstrap-panel.sh \
  -o bootstrap-panel.sh
# 确认默认已是 docker：
grep 'RUNTIME=' bootstrap-panel.sh | head -1

E2B_IMAGE_TAG=release-v1.0.1 bash bootstrap-panel.sh
```

更完整步骤见各坐标目录内 `README.md`。
