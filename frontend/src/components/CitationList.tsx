import type { Citation } from "../types/zhiku";

type CitationListProps = {
  citations: Citation[];
};

export function CitationList({ citations }: CitationListProps) {
  if (citations.length === 0) {
    return <div className="empty-box">暂无引用来源。</div>;
  }

  return (
    <div className="citation-list">
      {citations.map((citation, index) => (
        <article key={index} className="citation-card">
          <div className="citation-title">
            <span>{citation.source || "知识片段"}</span>
            {typeof citation.score === "number" ? <strong>{citation.score.toFixed(3)}</strong> : null}
          </div>
          <p>{citation.content || "无片段内容"}</p>
        </article>
      ))}
    </div>
  );
}
