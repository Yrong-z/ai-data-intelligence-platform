from fastapi import APIRouter, File, Form, Request, UploadFile
from fastapi.responses import StreamingResponse
import httpx

from app.config import settings


router = APIRouter()


@router.post("/import")
async def import_document(request: Request, file: UploadFile = File(...), item_name: str | None = Form(default=None)):
    headers = {"X-Request-ID": getattr(request.state, "request_id", "")}
    content = await file.read()
    files = {"file": (file.filename or "upload", content, file.content_type or "application/octet-stream")}
    data = {"item_name": item_name} if item_name else {}
    async with httpx.AsyncClient(timeout=settings.request_timeout_seconds) as client:
        response = await client.post(f"{settings.zhiku_base_url}/api/import", files=files, data=data, headers=headers)
    return response.json()


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
