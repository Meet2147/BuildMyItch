import Database from "better-sqlite3";
import bcrypt from "bcryptjs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dbPath = path.join(__dirname, "..", "data.sqlite");

export const db = new Database(dbPath);
db.pragma("journal_mode = WAL");

db.exec(`
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  email         TEXT UNIQUE NOT NULL,
  name          TEXT,
  password_hash TEXT,
  role          TEXT NOT NULL DEFAULT 'owner',
  apps          TEXT NOT NULL DEFAULT '[]',   -- JSON array of app keys
  perms         TEXT NOT NULL DEFAULT '[]',   -- JSON array of "app:action"
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

-- VoiceStore: generated storefronts
CREATE TABLE IF NOT EXISTS sites (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id   INTEGER NOT NULL,
  name       TEXT NOT NULL,
  transcript TEXT,
  spec       TEXT NOT NULL,            -- JSON site spec
  published  INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- QuickPay: employees + payroll runs
CREATE TABLE IF NOT EXISTS employees (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id   INTEGER NOT NULL,
  name       TEXT NOT NULL,
  base       REAL NOT NULL DEFAULT 0,       -- monthly base salary
  per_day    REAL NOT NULL DEFAULT 0,       -- derived helper, optional
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS payruns (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id   INTEGER NOT NULL,
  period     TEXT NOT NULL,                 -- e.g. "2026-07"
  result     TEXT NOT NULL,                 -- JSON breakdown
  note       TEXT,                          -- Claude summary
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- StockSense: products + sales
CREATE TABLE IF NOT EXISTS products (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id   INTEGER NOT NULL,
  name       TEXT NOT NULL,
  sku        TEXT,
  stock      INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS sales (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  day        TEXT NOT NULL,                 -- YYYY-MM-DD
  qty        INTEGER NOT NULL DEFAULT 0
);

-- ShortcutForge: generated iOS shortcut plans
CREATE TABLE IF NOT EXISTS shortcuts (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id   INTEGER NOT NULL,
  name       TEXT NOT NULL,
  request    TEXT,
  spec       TEXT NOT NULL,                 -- JSON shortcut plan
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
`);

// Seed the super-admin (no password yet — they claim it on first login).
const adminEmail = (process.env.ADMIN_EMAIL || "meetjethwa3@gmail.com").toLowerCase();
const existing = db.prepare("SELECT id FROM users WHERE email = ?").get(adminEmail);
if (!existing) {
  db.prepare(
    "INSERT INTO users (email, name, role, apps, perms) VALUES (?, ?, 'admin', '[]', '[]')"
  ).run(adminEmail, "Admin");
  console.log(`[db] Seeded super-admin: ${adminEmail} (set password on first login)`);
}

export function hashPassword(pw: string) {
  return bcrypt.hashSync(pw, 10);
}
export function verifyPassword(pw: string, hash: string) {
  return bcrypt.compareSync(pw, hash);
}
