import { Router } from "express";
import { db } from "../db.js";
import { requireAuth, requireAdmin, loadUser } from "../auth.js";
import { APPS, PERMISSIONS } from "../permissions.js";

const r = Router();
r.use(requireAuth, requireAdmin);

// Metadata the admin UI uses to render the permission matrix.
r.get("/meta", (_req, res) => {
  res.json({ apps: APPS, permissions: PERMISSIONS });
});

r.get("/users", (_req, res) => {
  const rows = db
    .prepare("SELECT id, email, name, role, apps, perms, password_hash, created_at FROM users ORDER BY id")
    .all() as any[];
  res.json({
    users: rows.map((u) => ({
      id: u.id,
      email: u.email,
      name: u.name,
      role: u.role,
      apps: JSON.parse(u.apps || "[]"),
      perms: JSON.parse(u.perms || "[]"),
      active: Boolean(u.password_hash),
      created_at: u.created_at,
    })),
  });
});

// Admin adds a shop owner by email + grants apps/permissions.
r.post("/users", (req, res) => {
  const email = String(req.body.email || "").trim().toLowerCase();
  const name = req.body.name ? String(req.body.name) : null;
  const apps: string[] = Array.isArray(req.body.apps) ? req.body.apps : [];
  const perms: string[] = Array.isArray(req.body.perms) ? req.body.perms : [];
  if (!email || !email.includes("@")) return res.status(400).json({ error: "Valid email required" });
  const exists = db.prepare("SELECT id FROM users WHERE email = ?").get(email);
  if (exists) return res.status(409).json({ error: "That email is already added" });
  const info = db
    .prepare("INSERT INTO users (email, name, role, apps, perms) VALUES (?, ?, 'owner', ?, ?)")
    .run(email, name, JSON.stringify(apps), JSON.stringify(perms));
  res.json({ user: loadUser(Number(info.lastInsertRowid)) });
});

// Update apps/permissions/name for a user.
r.patch("/users/:id", (req, res) => {
  const id = Number(req.params.id);
  const user = loadUser(id);
  if (!user) return res.status(404).json({ error: "User not found" });
  if (user.role === "admin") return res.status(400).json({ error: "The admin already has every permission" });
  const apps = Array.isArray(req.body.apps) ? req.body.apps : user.apps;
  const perms = Array.isArray(req.body.perms) ? req.body.perms : user.perms;
  const name = req.body.name !== undefined ? req.body.name : user.name;
  db.prepare("UPDATE users SET apps = ?, perms = ?, name = ? WHERE id = ?").run(
    JSON.stringify(apps),
    JSON.stringify(perms),
    name,
    id
  );
  res.json({ user: loadUser(id) });
});

r.delete("/users/:id", (req, res) => {
  const id = Number(req.params.id);
  const user = loadUser(id);
  if (!user) return res.status(404).json({ error: "User not found" });
  if (user.role === "admin") return res.status(400).json({ error: "Cannot remove the admin" });
  db.prepare("DELETE FROM users WHERE id = ?").run(id);
  res.json({ ok: true });
});

export default r;
