import json

from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse
import httpx

from app.config import settings


router = APIRouter()


@router.post("/query")
async def query_data(request: Request):
    payload = await request.json()
    headers = {"X-Request-ID": getattr(request.state, "request_id", "")}

    async def event_stream():
        try:
            async with httpx.AsyncClient(timeout=settings.request_timeout_seconds) as client:
                async with client.stream(
                    "POST",
                    f"{settings.wshu_base_url}/api/query",
                    json={"query": payload.get("query", "")},
                    headers=headers,
                ) as response:
                    if response.status_code >= 400:
                        yield f"data: {json.dumps({'type': 'error', 'message': f'Text-to-SQL 服务返回 HTTP {response.status_code}'}, ensure_ascii=False)}\n\n".encode()
                        return
                    async for chunk in response.aiter_bytes():
                        yield chunk
        except httpx.TimeoutException:
            yield f"data: {json.dumps({'type': 'error', 'message': 'Text-to-SQL 查询超时'}, ensure_ascii=False)}\n\n".encode()
        except httpx.HTTPError as exc:
            yield f"data: {json.dumps({'type': 'error', 'message': f'Text-to-SQL 服务不可用: {exc}'}, ensure_ascii=False)}\n\n".encode()

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
