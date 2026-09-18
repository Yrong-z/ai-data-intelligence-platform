export function DashboardPage() {
  return (
    <div className="dashboard-grid">
      <section className="hero-panel">
        <h2>企业级 AI 智能知识与数据分析平台</h2>
        <p>统一接入 ZhiKu 智库服务与 Wshu 问数服务，面向商业化演示、工程化交付和面试深挖。</p>
      </section>
      <section className="metric-card">
        <span>服务形态</span>
        <strong>前端统一 / 后端分离</strong>
      </section>
      <section className="metric-card">
        <span>智库能力</span>
        <strong>RAG + 引用溯源</strong>
      </section>
      <section className="metric-card">
        <span>问数能力</span>
        <strong>Text-to-SQL + SQL 校验</strong>
      </section>
      <section className="metric-card">
        <span>工程化</span>
        <strong>Gateway + Docs + Evals</strong>
      </section>
    </div>
  );
}
