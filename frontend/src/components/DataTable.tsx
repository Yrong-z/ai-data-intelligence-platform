import type { SqlResultRow } from "../types/wshu";

type DataTableProps = {
  rows: SqlResultRow[];
};

export function DataTable({ rows }: DataTableProps) {
  if (rows.length === 0) {
    return <div className="empty-box">查询结果表格会显示在这里。</div>;
  }

  const columns = Object.keys(rows[0]);

  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={column}>{column}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, rowIndex) => (
            <tr key={rowIndex}>
              {columns.map((column) => (
                <td key={column}>{String(row[column] ?? "")}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
