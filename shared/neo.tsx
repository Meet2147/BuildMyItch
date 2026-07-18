import React from "react";

type BtnProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "default" | "primary" | "ghost" | "danger";
  loading?: boolean;
};
export function NeoButton({ variant = "default", loading, children, className = "", disabled, ...rest }: BtnProps) {
  return (
    <button className={`neo-btn ${variant} ${className}`} disabled={disabled || loading} {...rest}>
      {loading ? <span className="spin">◌</span> : children}
    </button>
  );
}

export function NeoCard({ children, className = "", style }: { children: React.ReactNode; className?: string; style?: React.CSSProperties }) {
  return <div className={`neo-card ${className}`} style={style}>{children}</div>;
}

export function NeoInput(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input className="neo-input" {...props} />;
}
export function NeoTextarea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea className="neo-textarea" {...props} />;
}

export function NeoBadge({ children, tone = "" }: { children: React.ReactNode; tone?: string }) {
  return <span className={`neo-badge ${tone}`}>{children}</span>;
}

export function NeoChip({ on, children, onClick }: { on?: boolean; children: React.ReactNode; onClick?: () => void }) {
  return (
    <span className={`neo-chip ${on ? "on" : ""}`} onClick={onClick}>
      {children}
    </span>
  );
}

export function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="col" style={{ gap: 7 }}>
      <span style={{ fontSize: 13, fontWeight: 800, color: "var(--text-soft)" }}>{label}</span>
      {children}
    </label>
  );
}

export function Money({ value }: { value: number }) {
  return <span>₹{value.toLocaleString("en-IN", { maximumFractionDigits: 2 })}</span>;
}
