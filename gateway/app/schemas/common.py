from pydantic import BaseModel


class QueryRequest(BaseModel):
    query: str
    session_id: str | None = None
    kb_id: str | None = None
    item_name: str | None = None

