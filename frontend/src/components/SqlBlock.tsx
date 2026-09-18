type SqlBlockProps = {
  sql?: string;
};

export function SqlBlock({ sql }: SqlBlockProps) {
  return (
    <pre className="sql-block">
      <code>{sql || "-- SQL 会在问数 Agent 生成后显示在这里"}</code>
    </pre>
  );
}
