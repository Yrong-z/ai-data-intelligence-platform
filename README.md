# AI-BI-Knowledge-Platform

AI Data Intelligence Platform is the public product shell for two independent
services: a RAG knowledge agent and a Text-to-SQL data agent.

## Architecture

```text
Browser → frontend → gateway → ZhiKu (knowledge) / Wshu (data)
```

The gateway only proxies requests. Backend source remains in its own repository
and is not copied into this platform repository.

## Quick Start

From this repository, run the one-click launcher. It starts the fixed Compose
project `wshu_platform`, waits for TEI, initializes retrieval, then starts both
APIs, the Gateway, and the Vite frontend:

```powershell
copy .env.example .env
powershell -ExecutionPolicy Bypass -File scripts/start_all.ps1
```

The first Wshu startup may take time while TEI downloads its model into the
Docker cache volume.

## Manual Start

```powershell
docker compose -p wshu_platform -f ../text2sql-data-agent/docker/docker-compose.yaml up -d
uv run --project ../rag-knowledge-agent uvicorn main:app --host 127.0.0.1 --port 8010
uv run --project ../text2sql-data-agent uvicorn app.main:app --host 127.0.0.1 --port 8001
uv run --project gateway uvicorn main:app --host 127.0.0.1 --port 9010
cd frontend; npm install; npm run dev
```

## Access URLs

- Frontend: http://localhost:5173
- Gateway: http://localhost:9010
- RAG API: http://localhost:8010/docs
- Text-to-SQL API: http://localhost:8001/docs

The frontend home navigation exposes `RAG Knowledge` for upload/query and
`Text-to-SQL` for natural-language data questions. Backend addresses remain
configurable through `ZHIKU_BASE_URL` and `WSHU_BASE_URL`; the frontend Gateway
address uses `VITE_GATEWAY_BASE_URL`.

## Stop

```powershell
powershell -ExecutionPolicy Bypass -File scripts/stop_all.ps1
```

## Core Flow

- Knowledge: `/api/knowledge/query` → ZhiKu `/api/query`
- Data: `/api/data/query` → Wshu `/api/query`

## Tech Stack

React, Vite, FastAPI, HTTPX, LangGraph, RAG retrieval, and Text-to-SQL.

## Tests

Backend tests remain in the two backend repositories. This repository contains
public evaluation inputs under `evals/` and gateway/frontend source.

## Project Structure

```text
frontend/   React product entry
gateway/    FastAPI routing and proxy layer
evals/      Public evaluation inputs
docs/       Architecture and deployment notes
```

## Current Limitations

- The one-click launcher requires Docker, uv, npm, and internet access for the
  first TEI model download.
- Authentication, tenancy, and production observability are outside this shell.
