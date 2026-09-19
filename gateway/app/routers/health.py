import httpx
from fastapi import APIRouter
from fastapi.responses import JSONResponse

from app.config import settings


router = APIRouter()


@router.get("/health")
async def health():
    checks = {}
    async with httpx.AsyncClient(timeout=3) as client:
        for name, url in (("rag", f"{settings.zhiku_base_url}/health/ready"), ("wshu", f"{settings.wshu_base_url}/health/ready")):
            try:
                response = await client.get(url)
                checks[name] = response.json()
            except Exception as exc:
                checks[name] = {"status": "unreachable", "error": type(exc).__name__}
    ready = all(item.get("status") == "ready" for item in checks.values())
    payload = {"status": "ok" if ready else "not_ready", "service": "gateway", "wshu_ready": checks.get("wshu", {}).get("status") == "ready", "rag_ready": checks.get("rag", {}).get("status") == "ready", "checks": checks}
    return JSONResponse(payload, status_code=200 if ready else 503)
