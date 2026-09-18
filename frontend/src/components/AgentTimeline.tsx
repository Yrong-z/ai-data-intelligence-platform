import type { AgentEvent } from "../types/common";

type AgentTimelineProps = {
  events: AgentEvent[];
};

export function AgentTimeline({ events }: AgentTimelineProps) {
  if (events.length === 0) {
    return <div className="empty-box">Agent 执行步骤会显示在这里。</div>;
  }

  return (
    <ol className="timeline">
      {events.map((event, index) => (
        <li key={`${event.type}-${index}`} className={`timeline-item ${event.status || ""}`}>
          <div className="timeline-dot" />
          <div>
            <div className="timeline-title">
              <span>{event.step || event.type}</span>
              {event.status ? <strong>{event.status}</strong> : null}
            </div>
            {event.message ? <p>{event.message}</p> : null}
            {event.data && typeof event.data !== "string" ? (
              <pre>{JSON.stringify(event.data, null, 2).slice(0, 800)}</pre>
            ) : null}
          </div>
        </li>
      ))}
    </ol>
  );
}
