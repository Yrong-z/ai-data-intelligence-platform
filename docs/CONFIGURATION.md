# 配置说明

统一平台只配置 `ai-data-intelligence-platform/.env`。请先复制 `.env.example` 为 `.env`。

## LLM

| 配置 | 用途 | 是否必填 | 默认值 |
|---|---|---|---|
| `LLM_API_KEY` | 真实回答和 SQL 生成 | Demo 启动不必填，真实查询必填 | 空 |
| `LLM_BASE_URL` | OpenAI 兼容接口地址 | 真实查询必填 | `https://api.deepseek.com` |
| `LLM_MODEL` | 使用的模型名称 | 真实查询必填 | `deepseek-v4-flash` |

## RAG

| 配置 | 用途 | 是否必填 | 默认值 |
|---|---|---|---|
| `RAG_MODE` | 选择 Demo 或真实 RAG | 否 | `demo` |
| `MILVUS_URL` | Milvus 地址 | Real RAG 必填 | `http://127.0.0.1:19530` |
| `BGE_M3_PATH` | BGE-M3 模型路径 | Real RAG 使用 | 项目默认路径 |
| `MINERU_API_TOKEN` | PDF 解析令牌 | Real RAG 导入 PDF 必填 | 空 |

`RAG_MODE=demo` 不要求 Milvus 和真实 API Key。`RAG_MODE=real` 用于真实导入和检索。

## T2S

| 配置 | 用途 | 是否必填 |
|---|---|---|
| `MYSQL_HOST`、`MYSQL_PORT` | MySQL 地址和端口 | 是 |
| `MYSQL_USER`、`MYSQL_PASSWORD` | MySQL 登录信息 | 是 |
| `QDRANT_URL` | Qdrant 地址 | 是 |
| `ELASTICSEARCH_URL` | Elasticsearch 地址 | 是 |
| `EMBEDDING_BASE_URL` | 向量化服务地址 | 是 |

T2S 的真实自然语言 SQL 生成还需要 `LLM_API_KEY`、`LLM_BASE_URL` 和 `LLM_MODEL`。

## 平台服务地址

- 前端：`http://localhost:5173`
- 统一网关：`http://localhost:9010`
- T2S：`http://localhost:8001`
- RAG：`http://localhost:8010`
