export type SseMessage = {
  type: string;
  step?: string;
  status?: string;
  message?: string;
  data?: unknown;
};

export async function postSse(
  url: string,
  payload: unknown,
  onMessage: (message: SseMessage) => void,
) {
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), 180_000);
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    if (!response.ok) {
      const detail = await response.text();
      throw new Error(detail || `请求失败: ${response.status}`);
    }
    if (!response.body) {
      throw new Error("当前浏览器不支持 ReadableStream");
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder("utf-8");
    let buffer = "";
    let terminalSeen = false;

    const consume = (part: string) => {
      const data = part.split(/\r?\n/)
        .filter((line) => line.startsWith("data:"))
        .map((line) => line.slice(5).replace(/^ /, "")).join("\n");
      if (data) {
        const message = JSON.parse(data) as SseMessage;
        onMessage(message);
        if (["answer_done", "result", "error"].includes(message.type)) terminalSeen = true;
      }
    };

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const parts = buffer.split(/\r?\n\r?\n/);
      buffer = parts.pop() || "";
      parts.forEach(consume);
      if (terminalSeen) {
        await reader.cancel();
        return;
      }
    }

    buffer += decoder.decode();
    if (buffer.trim()) consume(buffer);
    if (!terminalSeen) throw new Error("服务连接提前结束，未收到查询结果");
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new Error("请求超时，请稍后重试");
    }
    if (error instanceof TypeError) throw new Error("无法连接服务，请确认平台已启动后重试");
    throw error;
  } finally {
    window.clearTimeout(timeout);
  }
}
