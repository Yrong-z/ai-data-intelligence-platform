type ChatPanelProps = {
  value: string;
  placeholder: string;
  busy: boolean;
  onChange: (value: string) => void;
  onSubmit: () => void;
};

export function ChatPanel({ value, placeholder, busy, onChange, onSubmit }: ChatPanelProps) {
  return (
    <div className="chat-panel">
      <textarea
        value={value}
        placeholder={placeholder}
        onChange={(event) => onChange(event.target.value)}
        rows={4}
      />
      <button disabled={busy || !value.trim()} onClick={onSubmit} type="button">
        {busy ? "执行中..." : "发送"}
      </button>
    </div>
  );
}
