# AI 数据智能平台

AI 数据智能平台是统一入口，提供 RAG 知识问答、T2S 数据问数和服务状态展示。三个仓库独立维护，但普通用户只需要 Clone 主平台；SETUP 会自动获取固定版本的两个后端。

## 快速开始

### 1. Clone 主仓库

```bash
git clone https://github.com/__GITHUB_USERNAME__/ai-data-intelligence-platform.git
cd ai-data-intelligence-platform
```

### 2. 首次安装

Windows 用户双击：

```text
SETUP_PLATFORM.bat
```

SETUP 会检查 Git、uv、Node.js/npm 和 Docker，并自动下载固定版本的 RAG 知识问答后端与 T2S 数据问数后端。用户无需分别 Clone 两个后端仓库。

发布者需要在 `scripts/release_config.ps1` 集中填写 GitHub 用户名，并先为两个后端发布对应 tag；普通用户不需要修改这个文件。

### 3. 配置

```powershell
Copy-Item .env.example .env
```

在 `.env` 中填写：

```env
LLM_API_KEY=
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-v4-flash
```

`.env` 只保存在本机，禁止上传 GitHub。

### 4. 启动、使用和停止

```text
START_PLATFORM.bat
```

启动 RAG、T2S、Gateway 和统一前端，健康检查通过后自动打开浏览器。停止时运行：

```text
STOP_PLATFORM.bat
```

完整配置、端口、模型初始化和故障排查请查看 [部署说明](docs/DEPLOYMENT.md)、[用户手册](docs/USER_GUIDE.md) 和 [故障排查](docs/TROUBLESHOOTING.md)。

## 项目组成

```text
AI 数据智能平台
├── Frontend                 主平台统一工作台
├── Gateway                  统一 HTTP / SSE / Health 入口
├── RAG Knowledge Agent      独立 RAG 后端
└── Text-to-SQL Data Agent   独立 T2S 后端
```

三个仓库保持独立，便于后端单独开发、阅读源码和部署。普通用户只 Clone 主平台；后端仓库仅作为源码和独立部署入口：

- [RAG Knowledge Agent](https://github.com/__GITHUB_USERNAME__/rag-knowledge-agent)
- [Text-to-SQL Data Agent](https://github.com/__GITHUB_USERNAME__/text2sql-data-agent)

## 技术栈

- Frontend：React 19、TypeScript、Vite、SSE 客户端；统一承载 RAG、T2S 和服务状态展示。
- Gateway：Python、FastAPI、HTTP Proxy、SSE Proxy、Health Aggregation、CORS；提供统一服务入口。
- RAG：Python、FastAPI、LangGraph、PDF/Markdown 导入、文档切分、BGE-M3、Milvus、HyDE、向量检索、RRF 多路召回融合排序、LLM 和 SSE；当前导入链路不支持 TXT，代码中的 Rerank 节点为现有流程节点，不代表接入了真实 Reranker 模型。
- T2S：Python、FastAPI、LangGraph、MySQL、Qdrant、Elasticsearch、Hugging Face TEI、LLM、Text-to-SQL、SQL Validate/Correct、sqlglot AST 安全校验、只读 SQL 和 SSE。主链为：自然语言 → 关键词提取 → 元数据召回 → SQL 生成 → SQL 校验 → 必要时修复 → SQL 执行 → 结果返回。
- Infrastructure：Docker Compose；RAG 使用 Milvus、etcd、MinIO，T2S 使用 MySQL、Qdrant、Elasticsearch、TEI。
- Engineering：`.env` 隔离、Health/Readiness、START/STOP、固定版本自动拉取、Secret 检查、日志、中文操作文档和 SQL 只读安全。

## 版本绑定

主平台发布版本与后端 tag 的绑定集中在 `scripts/release_config.ps1`：

```text
Platform v1.0.0 → RAG v1.0.0 + T2S v1.0.0
```

SETUP 不跟随后端 `main`，避免后端未来变更破坏已发布的平台。

## 用户文档

- [用户手册](docs/USER_GUIDE.md)
- [配置说明](docs/CONFIGURATION.md)
- [故障排查](docs/TROUBLESHOOTING.md)
- [架构说明](docs/ARCHITECTURE.md)
- [API 说明](docs/API.md)
