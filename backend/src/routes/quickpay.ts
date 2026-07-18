import { Router } from "express";
import { db } from "../db.js";
import { requireAuth, requirePerm } from "../auth.js";
import { askText, claudeReady } from "../claude.js";

const r = Router();
r.use(requireAuth);

r.get("/employees", requirePerm("quickpay:view"), (req, res) => {
  const rows = db.prepare("SELECT id, name, base FROM employees WHERE owner_id = ? ORDER BY id").all(req.user!.id);
  res.json({ employees: rows });
});

r.post("/employees", requirePerm("quickpay:manage"), (req, res) => {
  const name = String(req.body.name || "").trim();
  const base = Number(req.body.base) || 0;
  if (!name) return res.status(400).json({ error: "Name required" });
  const info = db.prepare("INSERT INTO employees (owner_id, name, base) VALUES (?, ?, ?)").run(req.user!.id, name, base);
  res.json({ employee: { id: Number(info.lastInsertRowid), name, base } });
});

r.delete("/employees/:id", requirePerm("quickpay:manage"), (req, res) => {
  const emp = db.prepare("SELECT owner_id FROM employees WHERE id = ?").get(Number(req.params.id)) as any;
  if (!emp || emp.owner_id !== req.user!.id) return res.status(404).json({ error: "Not found" });
  db.prepare("DELETE FROM employees WHERE id = ?").run(Number(req.params.id));
  res.json({ ok: true });
});

r.get("/runs", requirePerm("quickpay:view"), (req, res) => {
  const rows = db
    .prepare("SELECT id, period, result, note, created_at FROM payruns WHERE owner_id = ? ORDER BY id DESC")
    .all(req.user!.id) as any[];
  res.json({ runs: rows.map((x) => ({ ...x, result: JSON.parse(x.result) })) });
});

interface RunRow {
  employeeId: number;
  unpaidDays?: number;
  paidLeave?: number;
  overtimeHours?: number;
  bonus?: number;
}

// One-click payroll: deterministic math (no AI needed for correctness),
// with an optional plain-language summary from Claude.
r.post("/run", requirePerm("quickpay:run"), async (req, res) => {
  const period = String(req.body.period || "").trim() || "this month";
  const workingDays = Number(req.body.workingDays) || 26;
  const rows: RunRow[] = Array.isArray(req.body.rows) ? req.body.rows : [];

  const lines = rows.map((row) => {
    const emp = db.prepare("SELECT id, name, base FROM employees WHERE id = ? AND owner_id = ?").get(row.employeeId, req.user!.id) as any;
    if (!emp) return null;
    const perDay = emp.base / workingDays;
    const perHour = perDay / 8;
    const unpaidDeduction = perDay * (row.unpaidDays || 0);
    const overtimePay = perHour * 1.5 * (row.overtimeHours || 0);
    const bonus = row.bonus || 0;
    const net = emp.base - unpaidDeduction + overtimePay + bonus;
    return {
      name: emp.name,
      base: round(emp.base),
      unpaidDays: row.unpaidDays || 0,
      paidLeave: row.paidLeave || 0,
      overtimeHours: row.overtimeHours || 0,
      unpaidDeduction: round(unpaidDeduction),
      overtimePay: round(overtimePay),
      bonus: round(bonus),
      net: round(net),
    };
  }).filter(Boolean) as any[];

  const total = round(lines.reduce((s, l) => s + l.net, 0));
  const result = { period, workingDays, lines, total };

  let note = "";
  if (claudeReady && lines.length) {
    try {
      note = await askText({
        system:
          "You are a friendly payroll assistant for a shop owner with a tiny team. " +
          "Given a payroll breakdown, write 2-3 short sentences: the total payout, who earns most/least " +
          "and why (overtime, bonus, unpaid days), in plain language. Amounts are in INR (₹). No markdown.",
        prompt: JSON.stringify(result),
        maxTokens: 400,
      });
    } catch {
      note = "";
    }
  }

  const info = db
    .prepare("INSERT INTO payruns (owner_id, period, result, note) VALUES (?, ?, ?, ?)")
    .run(req.user!.id, period, JSON.stringify(result), note);
  res.json({ run: { id: Number(info.lastInsertRowid), period, result, note } });
});

function round(n: number) {
  return Math.round(n * 100) / 100;
}

export default r;
