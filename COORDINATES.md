# 项目坐标登记表

> Author: kejiqing  
> 新增服务时：1) 本表加一行 2) 新建 `/<coord>/` 目录与 README + 脚本

| 坐标 (coord) | 服务说明 | 入口脚本 | 产物来源 |
|--------------|----------|----------|----------|
| `e2bserver` | E2B Panel + Worker 集群 | `bootstrap-panel.sh` / `bootstrap-worker.sh` | ACR：`e2b-binaries` / `e2b-base`（tag=`release-v*`） |

## 坐标 URL 模板

```
https://raw.githubusercontent.com/passionke/deploy-all-in-one/main/<coord>/<script>.sh
```

示例：

```
https://raw.githubusercontent.com/passionke/deploy-all-in-one/main/e2bserver/bootstrap-panel.sh
https://raw.githubusercontent.com/passionke/deploy-all-in-one/main/e2bserver/bootstrap-worker.sh
```
