import type { SqlResultRow } from "../types/wshu";

type ChartViewProps = {
  rows: SqlResultRow[];
};

export function ChartView({ rows }: ChartViewProps) {
  if (rows.length === 0) {
    return <div className="empty-box">图表会根据查询结果自动生成。</div>;
  }

  return (
    <div className="chart-placeholder">
      <strong>图表预览</strong>
      <span>已接收 {rows.length} 行数据，下一步接入 ECharts 自动渲染。</span>
    </div>
  );
}
