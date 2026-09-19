import { useEffect, useState } from "react";
import { queryData } from "../api/wshuApi";
import { API_BASE } from "../api/http";
import { AgentTimeline } from "../components/AgentTimeline";
import { ChartView } from "../components/ChartView";
import { ChatPanel } from "../components/ChatPanel";
import { DataTable } from "../components/DataTable";
import { SqlBlock } from "../components/SqlBlock";
import type { AgentEvent } from "../types/common";
import type { SqlResultRow } from "../types/wshu";

function extractSql(message: AgentEvent): string | undefined {
  if (!message.data || typeof message.data !== "object") return undefined;
  const data = message.data as Record<string, unknown>;
  return typeof data.sql === "string" ? data.sql : undefined;
}

export function DataAskPage() {
  const [query, setQuery] = useState("统计去年各地区的销售总额");
  const [events, setEvents] = useState<AgentEvent[]>([]);
  const [rows, setRows] = useState<SqlResultRow[]>([]);
  const [sql, setSql] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [serviceReady, setServiceReady] = useState(false);

  useEffect(() => {
    let disposed = false;

    async function checkReadiness() {
      try {
        const response = await fetch(`${API_BASE}/api/health`, { cache: "no-store" });
        const data = (await response.json()) as { wshu_ready?: boolean };
        if (!disposed) setServiceReady(response.ok && data.wshu_ready === true);
      } catch {
        if (!disposed) setServiceReady(false);
      }
    }

    void checkReadiness();
    const timer = window.setInterval(() => void checkReadiness(), 3000);
    return () => {
      disposed = true;
      window.clearInterval(timer);
    };
  }, []);

  async function submit() {
    if (!serviceReady) {
      setError("T2S 数据问数尚未就绪，请等待服务恢复后重试。");
      return;
    }
    setBusy(true);
    setError("");
    setEvents([]);
    setRows([]);
    setSql("");

    try {
      await queryData(query, (message) => {
        setEvents((current) => [...current, message]);

        const maybeSql = extractSql(message);
        if (maybeSql) setSql(maybeSql);

        if (message.type === "result" && Array.isArray(message.data)) {
          setRows(message.data as SqlResultRow[]);
        }

        if (message.type === "error") {
          setError(message.message || "问数查询失败");
        }
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "问数查询失败");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="workbench-grid">
      <section className="panel span-2">
        <h2>自然语言问数</h2>
        <p>
          {serviceReady
            ? "T2S 数据问数服务已启动，可以提交查询。"
            : "T2S 数据问数服务正在初始化或暂时不可用，页面将自动重试连接。"}
        </p>
        <ChatPanel
          value={query}
          placeholder="请输入数据分析问题"
          busy={busy}
          disabled={!serviceReady}
          disabledLabel="等待服务就绪"
          onChange={setQuery}
          onSubmit={submit}
        />
        {error ? <div className="error-banner">{error}</div> : null}
      </section>

      <section className="panel">
        <h3>生成 SQL</h3>
        <SqlBlock sql={sql} />
      </section>

      <section className="panel">
        <h3>图表分析</h3>
        <ChartView rows={rows} />
      </section>

      <section className="panel span-2">
        <h3>查询结果</h3>
        <DataTable rows={rows} />
      </section>

      <section className="panel span-2">
        <h3>Agent 执行过程</h3>
        <AgentTimeline events={events} />
      </section>
    </div>
  );
}
