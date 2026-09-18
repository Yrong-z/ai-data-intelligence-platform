# API

The gateway exposes two streaming proxy endpoints:

- `POST /api/knowledge/query` forwards the JSON query payload to ZhiKu.
- `POST /api/data/query` forwards `{ "query": "..." }` to Wshu.
- `GET /api/health` reports gateway availability.

The gateway forwards the backend SSE response and adds a request ID header.
