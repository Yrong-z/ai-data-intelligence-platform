import { useState } from "react";
import ReactMarkdown from "react-markdown";
import { importDocument, queryKnowledge } from "../api/zhikuApi";
import { AgentTimeline } from "../components/AgentTimeline";
import { ChatPanel } from "../components/ChatPanel";
import { CitationList } from "../components/CitationList";
import type { AgentEvent } from "../types/common";
import type { Citation } from "../types/zhiku";

export function KnowledgeChatPage() {
  const [query, setQuery] = useState("智库系统如何导入 PDF 文档？");
  const [answer, setAnswer] = useState("");
  const [events, setEvents] = useState<AgentEvent[]>([]);
  const [citations, setCitations] = useState<Citation[]>([]);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [itemName, setItemName] = useState("");
  const [uploadMessage, setUploadMessage] = useState("");

  async function upload(file?: File) {
    if (!file) return;
    setUploadMessage("正在导入...");
    try {
      const result = await importDocument(file, itemName || undefined);
      if (result.code !== 0 || !result.data?.item_name) throw new Error(result.message || "导入失败");
      setItemName(result.data.item_name);
      setUploadMessage(`已导入：${result.data.item_name}`);
    } catch (err) {
      setUploadMessage(err instanceof Error ? err.message : "导入失败");
    }
  }

  async function submit() {
    setBusy(true);
    setError("");
    setAnswer("");
    setEvents([]);
    setCitations([]);

    try {
      await queryKnowledge(query, (message) => {
        setEvents((current) => [...current, message]);

        if (message.type === "answer_done" && message.data && typeof message.data === "object") {
          const data = message.data as { answer?: string };
          setAnswer(data.answer || "");
        }

        if (message.type === "error") {
          setError(message.message || "智库查询失败");
        }

        const data = message.data;
        if (Array.isArray(data)) {
          setCitations(data as Citation[]);
        }
      }, itemName);
    } catch (err) {
      setError(err instanceof Error ? err.message : "智库查询失败");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="workbench-grid">
      <section className="panel span-2">
        <h2>智库问答</h2>
        <input type="file" accept=".pdf,.md,.markdown" onChange={(event) => upload(event.target.files?.[0])} />
        <input value={itemName} onChange={(event) => setItemName(event.target.value)} placeholder="item_name（导入后自动填充）" />
        {uploadMessage ? <p>{uploadMessage}</p> : null}
        <ChatPanel
          value={query}
          placeholder="请输入企业知识库问题"
          busy={busy}
          onChange={setQuery}
          onSubmit={submit}
        />
        {error ? <div className="error-banner">{error}</div> : null}
      </section>

      <section className="panel">
        <h3>回答</h3>
        <div className="answer-box">
          {answer ? <ReactMarkdown>{answer}</ReactMarkdown> : "回答会显示在这里。"}
        </div>
      </section>

      <section className="panel">
        <h3>引用来源</h3>
        <CitationList citations={citations} />
      </section>

      <section className="panel span-2">
        <h3>Agent 执行过程</h3>
        <AgentTimeline events={events} />
      </section>
    </div>
  );
}
