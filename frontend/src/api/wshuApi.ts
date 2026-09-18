import { API_BASE } from "./http";
import { postSse, SseMessage } from "./sseClient";

export function queryData(query: string, onMessage: (message: SseMessage) => void) {
  return postSse(`${API_BASE}/api/data/query`, { query }, onMessage);
}

