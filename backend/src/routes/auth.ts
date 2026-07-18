import { Router } from "express";
import { db, hashPassword, verifyPassword } from "../db.js";
import { loadUser, requireAuth, signToken } from "../auth.js";

const r = Router();

interface Row {
  id: number;
  password_hash: string | null;
  name: string | null;
}

// Step 1 of the smooth login: tell the client what state this email is in.
r.post("/lookup", (req, res) => {
  const email = String(req.body.email || "").trim().toLowerCase();
  if (!email) return res.status(400).json({ error: "Email required" });
  const row = db
    .prepare("SELECT id, password_hash, name FROM users WHERE email = ?")
    .get(email) as Row | undefined;
  if (!row) {
    return res.json({ exists: false });
  }
  res.json({ exists: true, hasPassword: Boolean(row.password_hash), name: row.name });
});

// First-time users (added by admin) set their own password here.
r.post("/claim", (req, res) => {
  const email = String(req.body.email || "").trim().toLowerCase();
  const password = String(req.body.password || "");
  const name = req.body.name ? String(req.body.name) : null;
  if (password.length < 6) return res.status(400).json({ error: "Password must be 6+ characters" });
  const row = db
    .prepare("SELECT id, password_hash, name FROM users WHERE email = ?")
    .get(email) as Row | undefined;
  if (!row) return res.status(404).json({ error: "No invite found for this email" });
  if (row.password_hash) return res.status(409).json({ error: "Account already set up — just sign in" });
  db.prepare("UPDATE users SET password_hash = ?, name = COALESCE(?, name) WHERE id = ?").run(
    hashPassword(password),
    name,
    row.id
  );
  const token = signToken(row.id);
  res.json({ token, user: loadUser(row.id) });
});

r.post("/login", (req, res) => {
  const email = String(req.body.email || "").trim().toLowerCase();
  const password = String(req.body.password || "");
  const row = db
    .prepare("SELECT id, password_hash, name FROM users WHERE email = ?")
    .get(email) as Row | undefined;
  if (!row || !row.password_hash || !verifyPassword(password, row.password_hash)) {
    return res.status(401).json({ error: "Wrong email or password" });
  }
  const token = signToken(row.id);
  res.json({ token, user: loadUser(row.id) });
});

r.get("/me", requireAuth, (req, res) => {
  res.json({ user: req.user });
});

export default r;
