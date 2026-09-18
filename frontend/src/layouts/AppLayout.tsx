import { useState } from "react";
import { BarChart3, BookOpen, Database, FileText, Gauge, Settings } from "lucide-react";
import { DashboardPage } from "../pages/DashboardPage";
import { DataAskPage } from "../pages/DataAskPage";
import { DocumentsPage } from "../pages/DocumentsPage";
import { EvaluationPage } from "../pages/EvaluationPage";
import { KnowledgeBasePage } from "../pages/KnowledgeBasePage";
import { KnowledgeChatPage } from "../pages/KnowledgeChatPage";
import { SettingsPage } from "../pages/SettingsPage";

export function AppLayout() {
  const [activePage, setActivePage] = useState("dashboard");

  const pages = [
    { key: "dashboard", label: "总览", icon: Gauge, component: <DashboardPage /> },
    { key: "knowledge", label: "RAG Knowledge", icon: BookOpen, component: <KnowledgeChatPage /> },
    { key: "data", label: "Text-to-SQL", icon: Database, component: <DataAskPage /> },
    { key: "kb", label: "知识库", icon: FileText, component: <KnowledgeBasePage /> },
    { key: "evaluation", label: "评测中心", icon: BarChart3, component: <EvaluationPage /> },
    { key: "settings", label: "系统设置", icon: Settings, component: <SettingsPage /> },
  ];

  const current = pages.find((page) => page.key === activePage) || pages[0];

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <div className="brand">AI 智能平台</div>
        <nav>
          {pages.map((page) => {
            const Icon = page.icon;
            return (
              <button
                key={page.key}
                className={page.key === activePage ? "nav-item active" : "nav-item"}
                onClick={() => setActivePage(page.key)}
                type="button"
              >
                <Icon size={18} />
                <span>{page.label}</span>
              </button>
            );
          })}
        </nav>
      </aside>
      <section className="content">
        <div className="page-header">
          <p className="eyebrow">AI-BI-Knowledge-Platform</p>
          <h1>{current.label}</h1>
        </div>
        {current.component}
      </section>
    </main>
  );
}
