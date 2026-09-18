import os
from pathlib import Path
from dotenv import load_dotenv

from pydantic import BaseModel


load_dotenv(Path(__file__).resolve().parents[2] / ".env")


class Settings(BaseModel):
    zhiku_base_url: str = os.getenv("ZHIKU_BASE_URL", "http://127.0.0.1:8000")
    wshu_base_url: str = os.getenv("WSHU_BASE_URL", "http://127.0.0.1:8001")
    request_timeout_seconds: float = float(os.getenv("REQUEST_TIMEOUT_SECONDS", "120"))


settings = Settings()
