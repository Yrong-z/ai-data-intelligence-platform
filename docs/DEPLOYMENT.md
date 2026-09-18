# Deployment

## Configuration entry point

For the unified platform, copy the root `.env.example` to `.env` and edit only that file. The launcher reads it from the platform directory and passes compatible values to both backends. `.env` is ignored by Git.

When running either backend independently, use that repository's own `.env.example` and `.env` instead.

The platform maps:

- `LLM_API_KEY` → Wshu `LLM_API_KEY` and ZhiKu `OPENAI_API_KEY`
- `LLM_BASE_URL` → Wshu `LLM_BASE_URL` and ZhiKu `OPENAI_API_BASE`
- `LLM_MODEL` → Wshu `LLM_MODEL` and ZhiKu `LLM_DEFAULT_MODEL`
- `LLM_MODE`, `IMPORT_MODE`, and `MINERU_API_TOKEN` are passed to backend processes.

## LLM examples

DeepSeek:

```dotenv
LLM_API_KEY=your-key-here
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-v4-flash
LLM_MODE=real
```

Other OpenAI-compatible providers use their compatible endpoint and model name:

```dotenv
LLM_API_KEY=your-key-here
LLM_BASE_URL=https://your-provider.example.com/v1
LLM_MODEL=your-model-name
LLM_MODE=real
```

For a safe local demo, leave `LLM_API_KEY` empty and use `LLM_MODE=mock`. Real RAG uses `LLM_MODE=real`; document import defaults to `IMPORT_MODE=mock` unless the ZhiKu deployment is configured for real import services.

## One-click startup

With Docker Desktop/Linux engine, uv, npm, and the three sibling repositories present:

```text
START_PLATFORM.bat
```

The launcher starts RAG, Gateway, Frontend, Wshu infrastructure, retrieval initialization, and Wshu API. The first Wshu start may download `BAAI/bge-large-zh-v1.5` into a Docker named volume and requires internet access.

## Manual startup

From the platform root:

```powershell
$env:LLM_API_KEY="your-key"
$env:LLM_BASE_URL="https://api.deepseek.com"
$env:LLM_MODEL="deepseek-v4-flash"
uv run --project ../rag-knowledge-agent uvicorn main:app --host 127.0.0.1 --port 8010
uv run --project ../text2sql-data-agent uvicorn app.main:app --host 127.0.0.1 --port 8001
docker compose -p wshu_platform -f ../text2sql-data-agent/docker/docker-compose.yaml up -d
uv run --project gateway uvicorn main:app --host 127.0.0.1 --port 9010
npm --prefix frontend install
npm --prefix frontend run dev -- --host 127.0.0.1 --port 5173
```

## Access URLs

- Frontend: http://localhost:5173
- Gateway: http://localhost:9010
- RAG API: http://localhost:8010/docs
- Text-to-SQL API: http://localhost:8001/docs

## Custom repository directories

Set `RAG_REPO_DIR` and `WSHU_REPO_DIR` in the platform `.env` to absolute or relative paths. Relative paths are resolved by the launcher from the release workspace layout; the default is `../rag-knowledge-agent` and `../text2sql-data-agent`.

## Stop

```powershell
STOP_PLATFORM.bat
```

or:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/stop_all.ps1
```

## Common issues

- Missing Docker, uv, npm, or a sibling repository stops preflight with a clear error.
- An empty LLM key keeps the platform startable, but real Text-to-SQL requests report that the LLM provider is not configured.
- The first embedding startup is slow while TEI downloads the model; later starts reuse the Docker volume.
- If a port is occupied, stop the process using it or change the service configuration consistently before starting again.
