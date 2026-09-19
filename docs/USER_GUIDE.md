# 用户手册

## 1. 第一次使用需要准备什么

准备 Windows、Python、Node.js、uv、npm 和 Docker Desktop，并在第一次启动前打开 Docker Desktop。

## 2. API Key 填在哪里

复制 `ai-data-intelligence-platform/.env.example` 为 `ai-data-intelligence-platform/.env`，只在这个 `.env` 中填写：

```env
LLM_API_KEY=你的APIKey
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-v4-flash
```

`.env` 是本地文件，禁止提交 GitHub。

## 3. 数据库如何配置

平台使用 Docker Compose 启动 Milvus、MySQL、Qdrant、Elasticsearch 和向量化服务。通常只需启动 Docker Desktop，并按 `.env.example` 配置服务地址。

## 4. 如何启动

首次使用双击 `SETUP_PLATFORM.bat`。依赖准备完成后双击 `START_PLATFORM.bat`。

## 5. 页面打开在哪里

启动成功后浏览器会自动打开 http://localhost:5173。

## 6. 如何使用 RAG

进入“RAG 知识问答”，上传 PDF 或 Markdown，等待导入完成，输入问题后点击“发送”。回答区域显示答案，引用来源区域显示检索到的文档片段。TXT 当前未接入导入链路。

## 7. 如何导入文件

选择文件后等待页面显示导入完成。Real RAG 第一次使用 BGE-M3 时可能下载约 2GB 模型并初始化数分钟，请不要重复提交。

## 8. 如何使用 T2S

进入“T2S 数据问数”，输入例如 `统计浙江省的销售总额`，平台会生成 SQL、执行查询并展示结果。

## 9. 如何停止

双击 `STOP_PLATFORM.bat`，确认 5173、8001、8010、9010 端口释放后再重新启动。

## 10. 出错去哪里看日志

日志目录为 `ai-data-intelligence-platform/runtime/logs/`，重点查看 `rag.log`、`gateway.log` 和 `wshu.log`。
