import { useState } from "react";
import ReactMarkdown from "react-markdown";
import { queryKnowledge } from "../api/zhikuApi";
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
      });
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
