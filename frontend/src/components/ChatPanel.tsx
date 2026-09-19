type ChatPanelProps = {
  value: string;
  placeholder: string;
  busy: boolean;
  disabled?: boolean;
  disabledLabel?: string;
  onChange: (value: string) => void;
  onSubmit: () => void;
};

export function ChatPanel({ value, placeholder, busy, disabled, disabledLabel, onChange, onSubmit }: ChatPanelProps) {
  return (
    <div className="chat-panel">
      <textarea
        value={value}
        placeholder={placeholder}
        onChange={(event) => onChange(event.target.value)}
        rows={4}
      />
      <button disabled={busy || disabled || !value.trim()} onClick={onSubmit} type="button">
        {busy ? "执行中..." : disabled ? (disabledLabel || "暂不可用") : "发送"}
      </button>
    </div>
  );
}
