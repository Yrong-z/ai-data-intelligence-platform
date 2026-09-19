# 故障排查

## Docker Desktop 没启动

现象：启动提示 Docker Desktop / Docker Engine 未启动。

原因：Docker 已安装，但 Docker daemon 不可用。

处理：启动 Docker Desktop，等待运行正常后重新双击 `START_PLATFORM.bat`。

## 端口被占用

现象：启动提示 5173、8001、8010 或 9010 已被占用。

处理：先双击 `STOP_PLATFORM.bat`；仍被占用时，根据提示停止对应进程后重试。

## API Key 未配置或无效

现象：平台可以启动，但真实 RAG 回答或 T2S 查询失败。

处理：在 `ai-data-intelligence-platform/.env` 中填写有效的 `LLM_API_KEY`、`LLM_BASE_URL` 和 `LLM_MODEL`，然后重启平台。Demo 模式不要求 API Key。

## RAG 文档导入超时

现象：文档导入超时。

原因：BGE-M3 可能正在首次加载，或 Milvus 尚未就绪。

处理：查看 RAG 日志，等待初始化完成后重试。

## BGE-M3 首次下载较慢

Real RAG 第一次使用可能下载约 2GB 的 BGE-M3 模型并初始化数分钟。期间不要误认为系统卡死，后续启动会复用缓存。

## PDF 缺少 MinerU Token

现象：Markdown 可以导入，但 PDF Real RAG 导入失败。

处理：在 `ai-data-intelligence-platform/.env` 中填写 `MINERU_API_TOKEN`。

## Milvus 不可用

现象：Real RAG readiness 未通过，或检索不到导入内容。

处理：确认 Docker Desktop 正常运行并检查 `MILVUS_URL`。Demo 模式不要求 Milvus。

## MySQL 不可用

现象：T2S 页面提示服务未就绪或查询失败。

处理：确认 Docker 中 MySQL 容器健康，检查 `MYSQL_HOST`、`MYSQL_PORT`、`MYSQL_USER` 和 `MYSQL_PASSWORD`。

## T2S 查询失败

现象：无法生成 SQL 或没有返回结果。

处理：确认 API Key 有效、T2S 基础服务健康，并使用演示数据问题重试。

## START 启动失败

依次确认 Docker Desktop 已启动、已执行 `SETUP_PLATFORM.bat`、`.env` 位于 `ai-data-intelligence-platform/.env`，且四个服务端口没有被占用。

## STOP 后端口未释放

再次执行 `STOP_PLATFORM.bat`，确认 5173、8001、8010、9010 没有监听进程。仍未释放时，按脚本输出的 PID 停止残留进程。

## 日志位置

`ai-data-intelligence-platform/runtime/logs/`
