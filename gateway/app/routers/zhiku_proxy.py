from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse
import httpx

from app.config import settings


router = APIRouter()


@router.post("/query")
async def query_knowledge(request: Request):
    payload = await request.json()
    headers = {"X-Request-ID": getattr(request.state, "request_id", "")}

    async def event_stream():
        async with httpx.AsyncClient(timeout=settings.request_timeout_seconds) as client:
            async with client.stream(
                "POST",
                f"{settings.zhiku_base_url}/api/query",
                json={**payload, "stream": True},
                headers=headers,
            ) as response:
                async for chunk in response.aiter_bytes():
                    yield chunk

    return StreamingResponse(event_stream(), media_type="text/event-stream")

