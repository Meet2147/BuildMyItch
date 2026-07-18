import React, { useState } from "react";
import type { AppKey } from "./types";
import { APP_META, isAdmin } from "./types";
import { useAuth } from "./auth";
import { NeoButton, NeoBadge } from "./neo";
import { AdminPanel } from "./AdminPanel";

export function AppShell({ app, children }: { app: AppKey; children: React.ReactNode }) {
  const { user, signOut } = useAuth();
  const [adminOpen, setAdminOpen] = useState(false);
  const meta = APP_META[app];

  return (
    <div style={{ minHeight: "100vh" }}>
      <header
        style={{
          position: "sticky",
          top: 0,
          zIndex: 10,
          display: "flex",
          alignItems: "center",
          gap: 16,
          padding: "16px 24px",
          background: "var(--bg)",
          boxShadow: "0 6px 14px var(--shadow-dark)",
        }}
      >
        <div className="row" style={{ gap: 10 }}>
          <span style={{ fontSize: 26 }}>{meta.icon}</span>
          <div>
            <div style={{ fontWeight: 900, fontSize: 18, color: "var(--text-strong)" }}>{meta.name}</div>
            <div className="muted" style={{ fontSize: 12 }}>{meta.tagline}</div>
          </div>
        </div>

        <div className="grow" />

        <div className="row wrap" style={{ gap: 8, justifyContent: "flex-end" }}>
          {isAdmin(user) && (
            <NeoButton variant="ghost" onClick={() => setAdminOpen(true)}>⚙️ Admin</NeoButton>
          )}
          <NeoBadge tone={isAdmin(user) ? "accent" : ""}>{isAdmin(user) ? "Admin" : "Owner"} · {user?.email}</NeoBadge>
          <NeoButton variant="ghost" onClick={signOut}>Sign out</NeoButton>
        </div>
      </header>

      <main style={{ maxWidth: 1040, margin: "0 auto", padding: "28px 20px 60px" }}>{children}</main>

      {adminOpen && <AdminPanel onClose={() => setAdminOpen(false)} />}
    </div>
  );
}
