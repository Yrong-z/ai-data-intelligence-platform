from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.middleware.request_id import RequestIdMiddleware
from app.routers.health import router as health_router
from app.routers.zhiku_proxy import router as zhiku_router
from app.routers.wshu_proxy import router as wshu_router


app = FastAPI(title="AI BI Knowledge Platform Gateway", version="0.1.0")

app.add_middleware(RequestIdMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://127.0.0.1:5173",
        "http://localhost:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router, prefix="/api")
app.include_router(zhiku_router, prefix="/api/knowledge", tags=["knowledge"])
app.include_router(wshu_router, prefix="/api/data", tags=["data"])

