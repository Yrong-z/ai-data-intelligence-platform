# 部署说明

## 配置入口

统一平台只配置 `ai-data-intelligence-platform/.env`。复制 `.env.example` 为 `.env` 后编辑，启动脚本会把兼容配置传递给两个后端。`.env` 已被 Git 忽略，禁止提交。

单独运行后端时，才使用对应子项目自己的 `.env.example` 和 `.env`。

The platform maps:

- `LLM_API_KEY` → T2S `LLM_API_KEY` 和 RAG `OPENAI_API_KEY`
- `LLM_BASE_URL` → T2S `LLM_BASE_URL` 和 RAG `OPENAI_API_BASE`
- `LLM_MODEL` → T2S `LLM_MODEL` 和 RAG `LLM_DEFAULT_MODEL`
- `RAG_MODE` 决定 RAG 运行模式；`MINERU_API_TOKEN` 用于 PDF Real 导入。

## RAG 模式

只需在平台 `.env` 中设置 `RAG_MODE`。

- `demo`：使用本地 Demo 配置，不要求 Milvus 和真实 API Key。
- `real`：使用真实导入和检索，需要 Milvus、BGE-M3；真实回答还需要 API Key。

Real 模式会先启动 RAG 的 Milvus Compose 项目（`rag_platform`），再启动 RAG API。BGE-M3 使用 Hugging Face 缓存，模型文件不会提交到仓库。

首次使用 Real RAG 时，BGE-M3 可能需要下载约 2GB 模型，首次初始化可能持续数分钟；期间不要误认为系统卡死。平台运行日志位于 `ai-data-intelligence-platform/runtime/logs/`。

Markdown 的 Real RAG 不需要 MinerU；PDF 的 Real RAG 需要 `MINERU_API_TOKEN`。

## LLM 配置示例

DeepSeek：

```dotenv
LLM_API_KEY=your-key-here
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-v4-flash
```

其他 OpenAI 兼容服务填写对应地址和模型名称：

```dotenv
LLM_API_KEY=your-key-here
LLM_BASE_URL=https://your-provider.example.com/v1
LLM_MODEL=your-model-name
```

本地 Demo 可以留空 `LLM_API_KEY` 并使用 `RAG_MODE=demo`。Real RAG 使用 `RAG_MODE=real`，启动脚本会自动设置底层模式。

## 第一次使用

首次双击 `SETUP_PLATFORM.bat`。脚本会为三个 Python 项目执行 `uv sync`、安装前端依赖并拉取 Docker 镜像。依赖下载超时时重新执行即可；启动脚本不会重复安装依赖。

## 一键启动

确认 Docker Desktop、uv、npm 和三个子项目都已准备好后：

```text
START_PLATFORM.bat
```

启动脚本会启动 RAG、统一网关、前端、T2S 基础服务、检索初始化和 T2S API。第一次启动可能下载 `BAAI/bge-large-zh-v1.5`，需要网络连接。

## 手动启动

From the platform root:

```powershell
$env:LLM_API_KEY="your-key"
$env:LLM_BASE_URL="https://api.deepseek.com"
$env:LLM_MODEL="deepseek-v4-flash"
uv run --project ../rag-knowledge-agent uvicorn main:app --host 127.0.0.1 --port 8010
uv run --project ../text2sql-data-agent uvicorn app.main:app --host 127.0.0.1 --port 8001
docker compose -p wshu_platform -f ../text2sql-data-agent/docker/docker-compose.yaml up -d
uv run --project gateway uvicorn main:app --host 127.0.0.1 --port 9010
npm --prefix frontend install
npm --prefix frontend run dev -- --host 127.0.0.1 --port 5173
```

## 访问地址

- 前端：http://localhost:5173
- 统一网关：http://localhost:9010
- RAG API：http://localhost:8010/docs
- T2S API：http://localhost:8001/docs

## 自定义子项目目录

可以在平台 `.env` 中设置 `RAG_REPO_DIR` 和 `WSHU_REPO_DIR`。相对路径按发布目录结构解析，默认分别为 `../rag-knowledge-agent` 和 `../text2sql-data-agent`。

## 停止服务

```powershell
STOP_PLATFORM.bat
```

or:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/stop_all.ps1
```

## 常见问题

- 缺少 Docker、uv、npm 或子项目时，启动前检查会给出明确提示。
- LLM Key 为空时平台仍可启动，但真实 T2S 查询会提示未配置 LLM。
- 第一次向量化启动较慢，TEI 下载模型后会复用 Docker 卷。
- 端口被占用时，先停止占用进程再重新启动。
