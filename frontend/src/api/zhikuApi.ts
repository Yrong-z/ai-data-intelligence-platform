import { API_BASE } from "./http";
import { postSse, SseMessage } from "./sseClient";

export async function importDocument(file: File, itemName?: string) {
  const form = new FormData();
  form.append("file", file);
  if (itemName) form.append("item_name", itemName);
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), 180_000);
  let response: Response;
  try {
    response = await fetch(`${API_BASE}/api/knowledge/import`, {
      method: "POST",
      body: form,
      signal: controller.signal,
    });
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") throw new Error("导入超时，请稍后重试");
    throw error;
  } finally {
    window.clearTimeout(timeout);
  }
  if (!response.ok) throw new Error(`导入失败: ${response.status}`);
  return response.json() as Promise<{
    code: number;
    message: string;
    data?: { item_name: string; chunks_count?: number; mode?: string };
  }>;
}

export function queryKnowledge(query: string, onMessage: (message: SseMessage) => void, itemName?: string) {
  return postSse(`${API_BASE}/api/knowledge/query`, { query, item_name: itemName || undefined }, onMessage);
}
