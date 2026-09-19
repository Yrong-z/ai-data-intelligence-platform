import json

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
    try:
        async with httpx.AsyncClient(timeout=settings.request_timeout_seconds) as client:
            response = await client.post(f"{settings.zhiku_base_url}/api/import", files=files, data=data, headers=headers)
        return response.json()
    except httpx.TimeoutException:
        return {"code": 50400, "message": "RAG 导入超时", "data": None}
    except httpx.HTTPError as exc:
        return {"code": 50200, "message": f"RAG 服务不可用: {exc}", "data": None}


@router.post("/query")
async def query_knowledge(request: Request):
    payload = await request.json()
    headers = {"X-Request-ID": getattr(request.state, "request_id", "")}

    async def event_stream():
        try:
            async with httpx.AsyncClient(timeout=settings.request_timeout_seconds) as client:
                async with client.stream(
                    "POST",
                    f"{settings.zhiku_base_url}/api/query",
                    json={**payload, "stream": True},
                    headers=headers,
                ) as response:
                    if response.status_code >= 400:
                        yield f"data: {json.dumps({'type': 'error', 'message': f'RAG 服务返回 HTTP {response.status_code}'}, ensure_ascii=False)}\n\n".encode()
                        return
                    async for chunk in response.aiter_bytes():
                        yield chunk
        except httpx.TimeoutException:
            yield f"data: {json.dumps({'type': 'error', 'message': 'RAG 查询超时'}, ensure_ascii=False)}\n\n".encode()
        except httpx.HTTPError as exc:
            yield f"data: {json.dumps({'type': 'error', 'message': f'RAG 服务不可用: {exc}'}, ensure_ascii=False)}\n\n".encode()

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
