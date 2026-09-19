export function DashboardPage() {
  return (
    <div className="dashboard-grid">
      <section className="hero-panel">
        <h2>企业级 AI 智能知识与数据分析平台</h2>
        <p>统一集成 RAG 知识问答与 T2S 数据问数能力，提供文档知识检索、自然语言数据查询与统一服务入口。</p>
      </section>
      <section className="metric-card">
        <span>服务架构</span>
        <strong>统一前端 / 独立后端</strong>
      </section>
      <section className="metric-card">
        <span>知识问答</span>
        <strong>RAG + 引用溯源</strong>
      </section>
      <section className="metric-card">
        <span>数据问数</span>
        <strong>T2S + SQL 校验</strong>
      </section>
      <section className="metric-card">
        <span>工程能力</span>
        <strong>统一网关 + 文档 + 评测</strong>
      </section>
    </div>
  );
}
