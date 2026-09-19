# API 说明

统一网关提供两个流式代理接口：

- `POST /api/knowledge/query`：转发 JSON 知识问答请求。
- `POST /api/data/query`：转发 `{ "query": "..." }` 数据问数请求。
- `GET /api/health`：返回统一网关可用状态。

统一网关转发后端 SSE 响应，并增加请求 ID 响应头。
