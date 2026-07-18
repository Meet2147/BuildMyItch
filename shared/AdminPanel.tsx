import React, { useEffect, useState } from "react";
import { api } from "./api";
import { NeoButton, NeoCard, NeoInput, NeoChip, NeoBadge, Field } from "./neo";
import { APP_META } from "./types";
import type { AppKey } from "./types";

interface AdminUser {
  id: number;
  email: string;
  name: string | null;
  role: "admin" | "owner";
  apps: string[];
  perms: string[];
  active: boolean;
}
interface Meta {
  apps: AppKey[];
  permissions: Record<AppKey, { key: string; label: string }[]>;
}

export function AdminPanel({ onClose }: { onClose: () => void }) {
  const [meta, setMeta] = useState<Meta | null>(null);
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [email, setEmail] = useState("");
  const [name, setName] = useState("");
  const [draftApps, setDraftApps] = useState<string[]>([]);
  const [draftPerms, setDraftPerms] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  async function load() {
    const [m, u] = await Promise.all([
      api<Meta>("/admin/meta"),
      api<{ users: AdminUser[] }>("/admin/users"),
    ]);
    setMeta(m);
    setUsers(u.users);
  }
  useEffect(() => {
    load().catch((e) => setErr(e.message));
  }, []);

  function toggleDraftApp(app: AppKey) {
    const on = draftApps.includes(app);
    const perms = meta!.permissions[app].map((p) => p.key);
    if (on) {
      setDraftApps(draftApps.filter((a) => a !== app));
      setDraftPerms(draftPerms.filter((p) => !perms.includes(p)));
    } else {
      setDraftApps([...draftApps, app]);
      setDraftPerms([...new Set([...draftPerms, ...perms])]); // grant all perms of that app by default
    }
  }
  function toggleDraftPerm(app: AppKey, key: string) {
    const on = draftPerms.includes(key);
    setDraftPerms(on ? draftPerms.filter((p) => p !== key) : [...draftPerms, key]);
    if (!on && !draftApps.includes(app)) setDraftApps([...draftApps, app]);
  }

  async function addUser(e: React.FormEvent) {
    e.preventDefault();
    setErr("");
    setBusy(true);
    try {
      await api("/admin/users", {
        method: "POST",
        body: JSON.stringify({ email, name, apps: draftApps, perms: draftPerms }),
      });
      setEmail("");
      setName("");
      setDraftApps([]);
      setDraftPerms([]);
      await load();
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function updateUser(u: AdminUser, apps: string[], perms: string[]) {
    setUsers((prev) => prev.map((x) => (x.id === u.id ? { ...x, apps, perms } : x)));
    await api(`/admin/users/${u.id}`, { method: "PATCH", body: JSON.stringify({ apps, perms }) });
  }
  async function removeUser(u: AdminUser) {
    if (!confirm(`Remove ${u.email}?`)) return;
    await api(`/admin/users/${u.id}`, { method: "DELETE" });
    load();
  }

  return (
    <div style={overlay} onClick={onClose}>
      <div style={sheet} className="fade-in" onClick={(e) => e.stopPropagation()}>
        <div className="row" style={{ marginBottom: 18 }}>
          <h2 className="grow">⚙️ Manage access</h2>
          <NeoButton variant="ghost" onClick={onClose}>✕</NeoButton>
        </div>

        {!meta ? (
          <p className="muted">Loading…</p>
        ) : (
          <div className="col" style={{ gap: 22 }}>
            {/* Add user */}
            <NeoCard>
              <h3 style={{ marginBottom: 12 }}>Invite a shop owner</h3>
              <form className="col" onSubmit={addUser}>
                <div className="row wrap" style={{ gap: 12 }}>
                  <div className="grow" style={{ minWidth: 200 }}>
                    <Field label="Email">
                      <NeoInput type="email" placeholder="owner@shop.com" value={email} onChange={(e) => setEmail(e.target.value)} required />
                    </Field>
                  </div>
                  <div className="grow" style={{ minWidth: 160 }}>
                    <Field label="Name (optional)">
                      <NeoInput value={name} onChange={(e) => setName(e.target.value)} placeholder="Ramesh" />
                    </Field>
                  </div>
                </div>

                <div className="col" style={{ gap: 10, marginTop: 4 }}>
                  {meta.apps.map((app) => (
                    <div key={app} className="neo-inset" style={{ padding: 12 }}>
                      <div className="row wrap" style={{ gap: 10 }}>
                        <NeoChip on={draftApps.includes(app)} onClick={() => toggleDraftApp(app)}>
                          {APP_META[app].icon} {APP_META[app].name}
                        </NeoChip>
                        {meta.permissions[app].map((p) => (
                          <NeoChip key={p.key} on={draftPerms.includes(p.key)} onClick={() => toggleDraftPerm(app, p.key)}>
                            {p.label}
                          </NeoChip>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>

                <NeoButton variant="primary" type="submit" loading={busy} style={{ alignSelf: "flex-start" }}>
                  + Add owner
                </NeoButton>
              </form>
            </NeoCard>

            {/* Existing users */}
            <div className="col">
              <h3>People with access</h3>
              {users.map((u) => (
                <UserRow key={u.id} u={u} meta={meta} onChange={updateUser} onRemove={removeUser} />
              ))}
            </div>
          </div>
        )}
        {err && <p style={{ color: "var(--danger)", fontWeight: 700 }}>{err}</p>}
      </div>
    </div>
  );
}

function UserRow({
  u,
  meta,
  onChange,
  onRemove,
}: {
  u: AdminUser;
  meta: Meta;
  onChange: (u: AdminUser, apps: string[], perms: string[]) => void;
  onRemove: (u: AdminUser) => void;
}) {
  const admin = u.role === "admin";
  function togglePerm(app: AppKey, key: string) {
    if (admin) return;
    const on = u.perms.includes(key);
    let perms = on ? u.perms.filter((p) => p !== key) : [...u.perms, key];
    let apps = u.apps;
    const appPerms = meta.permissions[app].map((p) => p.key);
    const anyOn = appPerms.some((p) => perms.includes(p));
    apps = anyOn ? [...new Set([...apps, app])] : apps.filter((a) => a !== app);
    onChange(u, apps, perms);
  }
  return (
    <NeoCard style={{ padding: 16 }}>
      <div className="row wrap" style={{ gap: 10 }}>
        <div className="grow">
          <div style={{ fontWeight: 800, color: "var(--text-strong)" }}>
            {u.name || u.email} {admin && <NeoBadge tone="accent">Admin · all access</NeoBadge>}
          </div>
          <div className="muted" style={{ fontSize: 13 }}>
            {u.email} · {u.active ? "active" : "invited (not signed in yet)"}
          </div>
        </div>
        {!admin && <NeoButton variant="danger" onClick={() => onRemove(u)}>Remove</NeoButton>}
      </div>
      {!admin && (
        <div className="col" style={{ gap: 8, marginTop: 12 }}>
          {meta.apps.map((app) => (
            <div key={app} className="row wrap" style={{ gap: 8 }}>
              <span style={{ width: 120, fontWeight: 800, fontSize: 13, color: "var(--text-soft)" }}>
                {APP_META[app].icon} {APP_META[app].name}
              </span>
              {meta.permissions[app].map((p) => (
                <NeoChip key={p.key} on={u.perms.includes(p.key)} onClick={() => togglePerm(app, p.key)}>
                  {p.label}
                </NeoChip>
              ))}
            </div>
          ))}
        </div>
      )}
    </NeoCard>
  );
}

const overlay: React.CSSProperties = {
  position: "fixed",
  inset: 0,
  background: "rgba(60,64,80,0.35)",
  backdropFilter: "blur(3px)",
  display: "flex",
  justifyContent: "center",
  alignItems: "flex-start",
  padding: "40px 16px",
  zIndex: 50,
  overflowY: "auto",
};
const sheet: React.CSSProperties = {
  background: "var(--bg)",
  borderRadius: 22,
  boxShadow: "var(--sh-out)",
  padding: 24,
  width: "100%",
  maxWidth: 720,
};
