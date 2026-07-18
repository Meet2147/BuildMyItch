import React, { useEffect, useRef, useState } from "react";
import { api } from "@shared/api";
import { useAuth } from "@shared/auth";
import { canPerm } from "@shared/types";
import { NeoButton, NeoCard, NeoTextarea, NeoBadge, Field } from "@shared/neo";
import { SitePreview } from "./SitePreview";

interface Site {
  id: number;
  name: string;
  transcript: string;
  spec: any;
  published: boolean;
}

const EXAMPLES = [
  "I run a small bakery called Sunrise Bakes. We sell fresh bread, cakes and cookies. Open 8am to 9pm.",
  "Meri kirana dukaan hai, Sharma General Store. Rice, atta, oil, snacks milte hain. Subah 7 se raat 10 tak.",
  "I have a tailoring shop, we stitch shirts, kurtas and do alterations. Contact 98765 43210.",
];

export default function App() {
  const { user } = useAuth();
  const [sites, setSites] = useState<Site[]>([]);
  const [transcript, setTranscript] = useState("");
  const [listening, setListening] = useState(false);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");
  const [preview, setPreview] = useState<Site | null>(null);
  const recRef = useRef<any>(null);

  const canCreate = canPerm(user, "voicestore:create");
  const canPublish = canPerm(user, "voicestore:publish");

  async function load() {
    try {
      const { sites } = await api<{ sites: Site[] }>("/voicestore/sites");
      setSites(sites);
      if (!preview && sites[0]) setPreview(sites[0]);
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
    let base = transcript ? transcript + " " : "";
    rec.onresult = (e: any) => {
      let interim = "";
      for (let i = e.resultIndex; i < e.results.length; i++) {
        const t = e.results[i][0].transcript;
        if (e.results[i].isFinal) base += t + " ";
        else interim += t;
      }
      setTranscript((base + interim).trimStart());
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
      const { site } = await api<{ site: Site }>("/voicestore/generate", {
        method: "POST",
        body: JSON.stringify({ transcript }),
      });
      setSites((s) => [site, ...s]);
      setPreview(site);
      setTranscript("");
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function togglePublish(site: Site) {
    const { published } = await api<{ published: boolean }>(`/voicestore/sites/${site.id}/publish`, { method: "POST" });
    setSites((s) => s.map((x) => (x.id === site.id ? { ...x, published } : x)));
    setPreview((p) => (p && p.id === site.id ? { ...p, published } : p));
  }
  async function remove(site: Site) {
    if (!confirm(`Delete "${site.name}"?`)) return;
    await api(`/voicestore/sites/${site.id}`, { method: "DELETE" });
    setSites((s) => s.filter((x) => x.id !== site.id));
    setPreview((p) => (p?.id === site.id ? null : p));
  }

  return (
    <div className="col" style={{ gap: 24 }}>
      {canCreate && (
        <NeoCard className="fade-in">
          <h2>🎙️ Describe your shop</h2>
          <p className="muted" style={{ marginTop: 4 }}>
            Just talk — say what you sell, your timings and how to reach you. We'll build the website.
          </p>
          <div className="col" style={{ marginTop: 14 }}>
            <Field label="What you said">
              <NeoTextarea
                value={transcript}
                onChange={(e) => setTranscript(e.target.value)}
                placeholder="Tap the mic and start talking, or type here…"
                rows={4}
              />
            </Field>
            <div className="row wrap" style={{ gap: 10 }}>
              <NeoButton onClick={toggleMic} variant={listening ? "danger" : "default"}>
                {listening ? "● Listening… tap to stop" : "🎤 Start talking"}
              </NeoButton>
              <NeoButton variant="primary" loading={busy} disabled={!transcript.trim()} onClick={generate}>
                ✨ Build my website
              </NeoButton>
            </div>
            <div className="row wrap" style={{ gap: 8, marginTop: 4 }}>
              <span className="muted" style={{ fontSize: 12 }}>Try:</span>
              {EXAMPLES.map((ex, i) => (
                <NeoBadge key={i}>
                  <span style={{ cursor: "pointer" }} onClick={() => setTranscript(ex)}>
                    {ex.slice(0, 34)}…
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
          <h3>Your storefronts</h3>
          {sites.length === 0 && <p className="muted">No sites yet — describe your shop above to create one.</p>}
          {sites.map((s) => (
            <NeoCard
              key={s.id}
              style={{ padding: 14, cursor: "pointer", boxShadow: preview?.id === s.id ? "var(--sh-in)" : undefined }}
              className="fade-in"
            >
              <div onClick={() => setPreview(s)}>
                <div className="row">
                  <b className="grow" style={{ color: "var(--text-strong)" }}>{s.name}</b>
                  {s.published ? <NeoBadge tone="ok">● Live</NeoBadge> : <NeoBadge>Draft</NeoBadge>}
                </div>
                <div className="muted" style={{ fontSize: 12, marginTop: 6 }}>{s.transcript?.slice(0, 60)}…</div>
              </div>
              <div className="row" style={{ gap: 8, marginTop: 10 }}>
                {canPublish && (
                  <NeoButton variant="ghost" onClick={() => togglePublish(s)}>
                    {s.published ? "Unpublish" : "Publish"}
                  </NeoButton>
                )}
                {canCreate && (
                  <NeoButton variant="ghost" className="danger" onClick={() => remove(s)}>Delete</NeoButton>
                )}
              </div>
            </NeoCard>
          ))}
        </div>

        <div style={{ flex: "2 1 420px", minWidth: 300 }}>
          <h3>Preview</h3>
          {preview ? <SitePreview spec={preview.spec} /> : <NeoCard><p className="muted">Select a storefront to preview it.</p></NeoCard>}
        </div>
      </div>
    </div>
  );
}
