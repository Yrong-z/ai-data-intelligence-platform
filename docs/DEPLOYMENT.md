# Deployment

Run the two backend repositories first, then configure the gateway with:

```text
ZHIKU_BASE_URL=http://127.0.0.1:8010
WSHU_BASE_URL=http://127.0.0.1:8001
REQUEST_TIMEOUT_SECONDS=120
```

Start the gateway from `gateway/` and the frontend from `frontend/`.
The frontend gateway URL can be set with `VITE_GATEWAY_BASE_URL`.

The platform repository intentionally excludes backend databases, model weights,
logs, build output, and dependency directories.
