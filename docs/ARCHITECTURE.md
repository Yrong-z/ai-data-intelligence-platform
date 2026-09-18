# Architecture

The platform is a thin public shell around two separately released backends.
The React frontend calls the FastAPI gateway, which forwards knowledge requests
to ZhiKu and data requests to Wshu.

```text
frontend/src/api → gateway/app/routers
  /api/knowledge/query → ZhiKu /api/query
  /api/data/query     → Wshu /api/query
```

The gateway does not duplicate backend code or alter either backend pipeline.
