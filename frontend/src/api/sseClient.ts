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
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!response.body) {
    throw new Error("当前浏览器不支持 ReadableStream");
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder("utf-8");
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const parts = buffer.split("\n\n");
    buffer = parts.pop() || "";

    for (const part of parts) {
      for (const line of part.split("\n")) {
        if (!line.startsWith("data: ")) continue;
        onMessage(JSON.parse(line.slice(6)));
      }
    }
  }
}

