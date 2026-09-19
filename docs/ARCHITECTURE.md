# 架构说明

平台由统一前端、统一网关和两个独立后端组成。React 前端调用 FastAPI 统一网关，网关分别转发知识问答和数据问数请求。

```text
frontend/src/api → gateway/app/routers
  /api/knowledge/query → RAG /api/query
  /api/data/query     → T2S /api/query
```

统一网关不复制后端代码，也不改变后端核心处理链路。
