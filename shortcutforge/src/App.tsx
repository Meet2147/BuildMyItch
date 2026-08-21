import React, { useEffect, useRef, useState } from "react";
import { api } from "@shared/api";
import { useAuth } from "@shared/auth";
import { canPerm } from "@shared/types";
import { NeoButton, NeoCard, NeoTextarea, NeoBadge, Field } from "@shared/neo";
import { ShortcutGuide, type Shortcut } from "./ShortcutGuide";

const EXAMPLES = [
  "When I tap it, text my wife \"Leaving now\" and start driving directions home.",
  "Turn on Do Not Disturb, set an alarm for 7am and play my sleep playlist.",
  "Ask me for a number of minutes, start a timer and turn on low power mode.",
];

export default function App() {
  const { user } = useAuth();
  const [shortcuts, setShortcuts] = useState<Shortcut[]>([]);
  const [request, setRequest] = useState("");
  const [listening, setListening] = useState(false);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");
  const [selected, setSelected] = useState<Shortcut | null>(null);
  const recRef = useRef<any>(null);

  const canCreate = canPerm(user, "shortcutforge:create");

  async function load() {
    try {
      const { shortcuts } = await api<{ shortcuts: Shortcut[] }>("/shortcutforge/shortcuts");
      setShortcuts(shortcuts);
      if (!selected && shortcuts[0]) setSelected(shortcuts[0]);
    } catch (e: any) {
      setErr(e.message);
    }
  }
  useEffect(() => {
    load();
  }, []);

  function toggleMic() {
    const SR = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SR) {
      setErr("Voice input isn't supported in this browser — you can type instead.");
      return;
    }
    if (listening) {
      recRef.current?.stop();
      return;
    }
    const rec = new SR();
    rec.lang = "en-IN";
    rec.continuous = true;
    rec.interimResults = true;
    let base = request ? request + " " : "";
    rec.onresult = (e: any) => {
      let interim = "";
      for (let i = e.resultIndex; i < e.results.length; i++) {
        const t = e.results[i][0].transcript;
        if (e.results[i].isFinal) base += t + " ";
        else interim += t;
      }
      setRequest((base + interim).trimStart());
    };
    rec.onend = () => setListening(false);
    rec.onerror = () => setListening(false);
    recRef.current = rec;
    rec.start();
    setListening(true);
  }

  async function generate() {
    setErr("");
    setBusy(true);
    try {
      const { shortcut } = await api<{ shortcut: Shortcut }>("/shortcutforge/generate", {
        method: "POST",
        body: JSON.stringify({ request }),
      });
      setShortcuts((s) => [shortcut, ...s]);
      setSelected(shortcut);
      setRequest("");
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function remove(s: Shortcut) {
    if (!confirm(`Delete "${s.name}"?`)) return;
    await api(`/shortcutforge/shortcuts/${s.id}`, { method: "DELETE" });
    setShortcuts((all) => all.filter((x) => x.id !== s.id));
    setSelected((sel) => (sel?.id === s.id ? null : sel));
  }

  return (
    <div className="col" style={{ gap: 24 }}>
      {canCreate && (
        <NeoCard className="fade-in">
          <h2>⚡ What should your iPhone do?</h2>
          <p className="muted" style={{ marginTop: 4 }}>
            Explain your idea in your own words — we'll design the Shortcut, action by action.
          </p>
          <div className="col" style={{ marginTop: 14 }}>
            <Field label="Your idea">
              <NeoTextarea
                value={request}
                onChange={(e) => setRequest(e.target.value)}
                placeholder="Tap the mic and start talking, or type your idea here…"
                rows={4}
              />
            </Field>
            <div className="row wrap" style={{ gap: 10 }}>
              <NeoButton onClick={toggleMic} variant={listening ? "danger" : "default"}>
                {listening ? "● Listening… tap to stop" : "🎤 Say it instead"}
              </NeoButton>
              <NeoButton variant="primary" loading={busy} disabled={!request.trim()} onClick={generate}>
                ✨ Forge my Shortcut
              </NeoButton>
            </div>
            <div className="row wrap" style={{ gap: 8, marginTop: 4 }}>
              <span className="muted" style={{ fontSize: 12 }}>Try:</span>
              {EXAMPLES.map((ex, i) => (
                <NeoBadge key={i}>
                  <span style={{ cursor: "pointer" }} onClick={() => setRequest(ex)}>
                    {ex.slice(0, 38)}…
                  </span>
                </NeoBadge>
              ))}
            </div>
          </div>
        </NeoCard>
      )}

      {err && <p style={{ color: "var(--danger)", fontWeight: 700 }}>{err}</p>}

      <div className="row wrap" style={{ gap: 24, alignItems: "flex-start" }}>
        <div className="col" style={{ flex: "1 1 260px", minWidth: 240 }}>
          <h3>Your shortcuts</h3>
          {shortcuts.length === 0 && (
            <p className="muted">Nothing forged yet — describe an idea above to create your first shortcut.</p>
          )}
          {shortcuts.map((s) => (
            <NeoCard
              key={s.id}
              style={{ padding: 14, cursor: "pointer", boxShadow: selected?.id === s.id ? "var(--sh-in)" : undefined }}
              className="fade-in"
            >
              <div onClick={() => setSelected(s)}>
                <div className="row">
                  <b className="grow" style={{ color: "var(--text-strong)" }}>
                    {s.spec.emoji} {s.name}
                  </b>
                  <NeoBadge>{s.spec.steps.length} steps</NeoBadge>
                </div>
                <div className="muted" style={{ fontSize: 12, marginTop: 6 }}>{s.request?.slice(0, 60)}…</div>
              </div>
              {canCreate && (
                <div className="row" style={{ gap: 8, marginTop: 10 }}>
                  <NeoButton variant="ghost" className="danger" onClick={() => remove(s)}>Delete</NeoButton>
                </div>
              )}
            </NeoCard>
          ))}
        </div>

        <div style={{ flex: "2 1 420px", minWidth: 300 }}>
          <h3>Build guide</h3>
          {selected ? (
            <ShortcutGuide shortcut={selected} />
          ) : (
            <NeoCard><p className="muted">Select a shortcut to see its build guide.</p></NeoCard>
          )}
        </div>
      </div>
    </div>
  );
}
