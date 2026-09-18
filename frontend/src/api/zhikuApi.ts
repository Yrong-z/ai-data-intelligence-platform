import { API_BASE } from "./http";
import { postSse, SseMessage } from "./sseClient";

export function queryKnowledge(query: string, onMessage: (message: SseMessage) => void) {
  return postSse(`${API_BASE}/api/knowledge/query`, { query }, onMessage);
}

