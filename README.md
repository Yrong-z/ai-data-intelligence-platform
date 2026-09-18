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

1. Start ZhiKu and Wshu using their repository instructions.
2. Set `ZHIKU_BASE_URL` and `WSHU_BASE_URL` for the gateway.
3. Start the gateway from `gateway/` with Uvicorn.
4. Start the frontend with `npm install` and `npm run dev`.

Default local endpoints are gateway `9010`, ZhiKu `8010`, Wshu `8001`, and
frontend `5173`; backend addresses are configurable through environment variables.

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

- The gateway requires both backend services to be started separately.
- Wshu Docker clean-run has not been verified in this environment.
- Authentication, tenancy, and production observability are outside this shell.
