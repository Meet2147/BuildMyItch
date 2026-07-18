import React, { createContext, useContext, useEffect, useState } from "react";
import { api, setToken, getToken } from "./api";
import type { User, AppKey } from "./types";
import { APP_META, canApp } from "./types";
import { NeoButton, NeoInput, NeoCard, Field } from "./neo";

interface AuthCtx {
  user: User | null;
  loading: boolean;
  signOut: () => void;
  refresh: () => Promise<void>;
}
const Ctx = createContext<AuthCtx>({ user: null, loading: true, signOut: () => {}, refresh: async () => {} });
export const useAuth = () => useContext(Ctx);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  async function refresh() {
    if (!getToken()) {
      setUser(null);
      setLoading(false);
      return;
    }
    try {
      const { user } = await api<{ user: User }>("/auth/me");
      setUser(user);
    } catch {
      setToken(null);
      setUser(null);
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => {
    refresh();
  }, []);

  function signOut() {
    setToken(null);
    setUser(null);
  }

  return <Ctx.Provider value={{ user, loading, signOut, refresh }}>{children}</Ctx.Provider>;
}

/** Wraps an app: shows the login flow until the user is signed in AND has access. */
export function AuthGate({ app, children }: { app: AppKey; children: React.ReactNode }) {
  const { user, loading, refresh, signOut } = useAuth();
  if (loading) {
    return (
      <div style={center}>
        <span className="spin" style={{ fontSize: 34, color: "var(--accent)" }}>◌</span>
      </div>
    );
  }
  if (!user) return <LoginFlow app={app} onDone={refresh} />;
  if (!canApp(user, app)) {
    const meta = APP_META[app];
    return (
      <div style={center}>
        <NeoCard className="fade-in" style={{ maxWidth: 420, textAlign: "center" }}>
          <div style={{ fontSize: 40 }}>{meta.icon}</div>
          <h2 style={{ margin: "10px 0" }}>No access yet</h2>
          <p className="muted">
            You're signed in as <b>{user.email}</b>, but the admin hasn't given you access to {meta.name} yet.
            Ask them to enable it for you.
          </p>
          <div style={{ marginTop: 16 }}>
            <NeoButton onClick={signOut}>Sign out</NeoButton>
          </div>
        </NeoCard>
      </div>
    );
  }
  return <>{children}</>;
}

const center: React.CSSProperties = {
  minHeight: "100vh",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  padding: 20,
};

type Stage = "email" | "login" | "claim" | "unknown";

function LoginFlow({ app, onDone }: { app: AppKey; onDone: () => void }) {
  const meta = APP_META[app];
  const [stage, setStage] = useState<Stage>("email");
  const [email, setEmail] = useState("");
  const [name, setName] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  async function lookup(e: React.FormEvent) {
    e.preventDefault();
    setErr("");
    setBusy(true);
    try {
      const r = await api<{ exists: boolean; hasPassword?: boolean; name?: string }>("/auth/lookup", {
        method: "POST",
        body: JSON.stringify({ email }),
      });
      if (!r.exists) setStage("unknown");
      else if (r.hasPassword) setStage("login");
      else {
        if (r.name) setName(r.name);
        setStage("claim");
      }
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr("");
    setBusy(true);
    try {
      const path = stage === "claim" ? "/auth/claim" : "/auth/login";
      const body = stage === "claim" ? { email, password, name } : { email, password };
      const r = await api<{ token: string }>(path, { method: "POST", body: JSON.stringify(body) });
      setToken(r.token);
      onDone();
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={center}>
      <NeoCard className="fade-in" style={{ maxWidth: 400, width: "100%" }}>
        <div style={{ textAlign: "center", marginBottom: 18 }}>
          <div style={{ fontSize: 40 }}>{meta.icon}</div>
          <h1 style={{ marginTop: 6 }}>{meta.name}</h1>
          <p className="muted" style={{ margin: "4px 0 0" }}>{meta.tagline}</p>
        </div>

        {stage === "email" && (
          <form className="col" onSubmit={lookup}>
            <Field label="Your email">
              <NeoInput
                type="email"
                autoFocus
                placeholder="you@shop.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </Field>
            <NeoButton variant="primary" loading={busy} type="submit">Continue →</NeoButton>
          </form>
        )}

        {stage === "login" && (
          <form className="col" onSubmit={submit}>
            <p className="muted" style={{ margin: 0 }}>Welcome back, {email}</p>
            <Field label="Password">
              <NeoInput type="password" autoFocus value={password} onChange={(e) => setPassword(e.target.value)} required />
            </Field>
            <NeoButton variant="primary" loading={busy} type="submit">Sign in</NeoButton>
            <BackLink onClick={() => setStage("email")} />
          </form>
        )}

        {stage === "claim" && (
          <form className="col" onSubmit={submit}>
            <p className="muted" style={{ margin: 0 }}>
              First time here! You were invited. Set a password to finish setup.
            </p>
            <Field label="Your name">
              <NeoInput value={name} onChange={(e) => setName(e.target.value)} placeholder="Shop owner name" />
            </Field>
            <Field label="Create a password">
              <NeoInput type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
            </Field>
            <NeoButton variant="primary" loading={busy} type="submit">Create account</NeoButton>
            <BackLink onClick={() => setStage("email")} />
          </form>
        )}

        {stage === "unknown" && (
          <div className="col" style={{ textAlign: "center" }}>
            <p className="muted">
              We couldn't find <b>{email}</b>. Access is invite-only — ask the admin to add your email first.
            </p>
            <BackLink onClick={() => setStage("email")} label="Try another email" />
          </div>
        )}

        {err && <p style={{ color: "var(--danger)", fontWeight: 700, marginTop: 12, textAlign: "center" }}>{err}</p>}
      </NeoCard>
    </div>
  );
}

function BackLink({ onClick, label = "← Back" }: { onClick: () => void; label?: string }) {
  return (
    <button className="neo-btn ghost" type="button" onClick={onClick} style={{ alignSelf: "center", color: "var(--text-soft)" }}>
      {label}
    </button>
  );
}
