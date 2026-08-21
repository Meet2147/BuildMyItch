import React, { useState } from "react";
import { API_BASE, getToken } from "@shared/api";
import { NeoButton, NeoCard, NeoBadge } from "@shared/neo";

export interface ShortcutSpec {
  name: string;
  emoji: string;
  summary: string;
  requirements: string[];
  steps: { action: string; search: string; config: { field: string; value: string }[]; note: string }[];
  actions: { identifier: string; parameters: Record<string, unknown> }[];
  testTip: string;
}

export interface Shortcut {
  id: number;
  name: string;
  request: string;
  spec: ShortcutSpec;
  created_at: string;
}

export function ShortcutGuide({ shortcut }: { shortcut: Shortcut }) {
  const { spec } = shortcut;
  const [downloading, setDownloading] = useState(false);
  const [err, setErr] = useState("");

  async function download() {
    setErr("");
    setDownloading(true);
    try {
      const res = await fetch(`${API_BASE}/shortcutforge/shortcuts/${shortcut.id}/file`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      if (!res.ok) throw new Error("Download failed");
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `${shortcut.name}.shortcut`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setDownloading(false);
    }
  }

  return (
    <NeoCard className="fade-in">
      <div className="row wrap" style={{ gap: 12, alignItems: "flex-start" }}>
        <div style={{ fontSize: 40 }}>{spec.emoji}</div>
        <div className="grow">
          <h2>{spec.name}</h2>
          <p className="muted" style={{ margin: "4px 0 0" }}>{spec.summary}</p>
        </div>
        <NeoButton variant="primary" loading={downloading} onClick={download}>
          ⬇ .shortcut file
        </NeoButton>
      </div>
      {err && <p style={{ color: "var(--danger)", fontWeight: 700 }}>{err}</p>}

      {spec.requirements.length > 0 && (
        <div style={{ marginTop: 18 }}>
          <h4>Before you start</h4>
          <div className="row wrap" style={{ gap: 8, marginTop: 8 }}>
            {spec.requirements.map((r, i) => (
              <NeoBadge key={i}>☝️ {r}</NeoBadge>
            ))}
          </div>
        </div>
      )}

      <div style={{ marginTop: 18 }}>
        <h4>Build it in the Shortcuts app</h4>
        <p className="muted" style={{ fontSize: 13, margin: "4px 0 0" }}>
          Open <b>Shortcuts</b> on your iPhone → tap <b>＋</b> → add these actions in order:
        </p>
        <div className="col" style={{ gap: 12, marginTop: 12 }}>
          {spec.steps.map((step, i) => (
            <div key={i} className="neo-inset" style={{ padding: 14, borderRadius: 14 }}>
              <div className="row wrap" style={{ gap: 8 }}>
                <NeoBadge tone="accent">{i + 1}</NeoBadge>
                <b style={{ color: "var(--text-strong)" }}>{step.action}</b>
                <span className="muted" style={{ fontSize: 12 }}>search “{step.search}”</span>
              </div>
              {step.config.length > 0 && (
                <table style={{ marginTop: 8, fontSize: 13, borderSpacing: "0 4px" }}>
                  <tbody>
                    {step.config.map((c, j) => (
                      <tr key={j}>
                        <td style={{ fontWeight: 800, color: "var(--text-soft)", paddingRight: 12, verticalAlign: "top", whiteSpace: "nowrap" }}>
                          {c.field}
                        </td>
                        <td>{c.value}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
              <p className="muted" style={{ fontSize: 13, margin: "8px 0 0" }}>{step.note}</p>
            </div>
          ))}
        </div>
      </div>

      <div style={{ marginTop: 18 }}>
        <h4>Test it</h4>
        <p className="muted" style={{ fontSize: 13, margin: "4px 0 0" }}>🧪 {spec.testTip}</p>
      </div>

      <p className="muted" style={{ fontSize: 12, marginTop: 18 }}>
        ℹ️ iPhones only import shortcut files signed by Apple, so following the steps above is the
        surest path. The downloaded file is handy if you have a Mac: sign it with{" "}
        <code>shortcuts sign -m anyone -i "{shortcut.name}.shortcut" -o signed.shortcut</code> and
        AirDrop it to your phone.
      </p>
    </NeoCard>
  );
}
