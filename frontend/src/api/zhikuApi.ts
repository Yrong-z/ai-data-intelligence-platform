import { API_BASE } from "./http";
import { postSse, SseMessage } from "./sseClient";

export async function importDocument(file: File, itemName?: string) {
  const form = new FormData();
  form.append("file", file);
  if (itemName) form.append("item_name", itemName);
  const response = await fetch(`${API_BASE}/api/knowledge/import`, { method: "POST", body: form });
  if (!response.ok) throw new Error(`导入失败: ${response.status}`);
  return response.json() as Promise<{ code: number; message: string; data?: { item_name: string } }>;
}

export function queryKnowledge(query: string, onMessage: (message: SseMessage) => void, itemName?: string) {
  return postSse(`${API_BASE}/api/knowledge/query`, { query, item_name: itemName || undefined }, onMessage);
}
