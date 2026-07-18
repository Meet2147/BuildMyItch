import { Router } from "express";
import { db } from "../db.js";
import { requireAuth, requirePerm } from "../auth.js";
import { askJSON, ClaudeNotConfigured } from "../claude.js";

const r = Router();
r.use(requireAuth);

function salesSeries(productId: number, days = 30): { day: string; qty: number }[] {
  return db
    .prepare(
      "SELECT day, SUM(qty) as qty FROM sales WHERE product_id = ? AND day >= date('now', ?) GROUP BY day ORDER BY day"
    )
    .all(productId, `-${days} days`) as any[];
}

r.get("/products", requirePerm("stocksense:view"), (req, res) => {
  const products = db.prepare("SELECT id, name, sku, stock FROM products WHERE owner_id = ? ORDER BY id").all(req.user!.id) as any[];
  const withStats = products.map((p) => {
    const series = salesSeries(p.id);
    const total = series.reduce((s, x) => s + x.qty, 0);
    const avgDaily = series.length ? total / 30 : 0;
    return { ...p, avgDaily: round(avgDaily), soldLast30: total };
  });
  res.json({ products: withStats });
});

r.post("/products", requirePerm("stocksense:manage"), (req, res) => {
  const name = String(req.body.name || "").trim();
  const sku = req.body.sku ? String(req.body.sku) : null;
  const stock = Number(req.body.stock) || 0;
  if (!name) return res.status(400).json({ error: "Name required" });
  const info = db.prepare("INSERT INTO products (owner_id, name, sku, stock) VALUES (?, ?, ?, ?)").run(req.user!.id, name, sku, stock);
  res.json({ product: { id: Number(info.lastInsertRowid), name, sku, stock } });
});

r.delete("/products/:id", requirePerm("stocksense:manage"), (req, res) => {
  const p = db.prepare("SELECT owner_id FROM products WHERE id = ?").get(Number(req.params.id)) as any;
  if (!p || p.owner_id !== req.user!.id) return res.status(404).json({ error: "Not found" });
  db.prepare("DELETE FROM products WHERE id = ?").run(Number(req.params.id));
  db.prepare("DELETE FROM sales WHERE product_id = ?").run(Number(req.params.id));
  res.json({ ok: true });
});

r.post("/products/:id/sale", requirePerm("stocksense:manage"), (req, res) => {
  const id = Number(req.params.id);
  const qty = Number(req.body.qty) || 0;
  const day = String(req.body.day || "").trim() || todayISO();
  const p = db.prepare("SELECT owner_id, stock FROM products WHERE id = ?").get(id) as any;
  if (!p || p.owner_id !== req.user!.id) return res.status(404).json({ error: "Not found" });
  db.prepare("INSERT INTO sales (product_id, day, qty) VALUES (?, ?, ?)").run(id, day, qty);
  db.prepare("UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?").run(qty, id);
  res.json({ ok: true });
});

// Handy for demos: fabricate ~30 days of believable sales history.
r.post("/seed-demo", requirePerm("stocksense:manage"), (req, res) => {
  const products = db.prepare("SELECT id FROM products WHERE owner_id = ?").all(req.user!.id) as any[];
  const insert = db.prepare("INSERT INTO sales (product_id, day, qty) VALUES (?, ?, ?)");
  const tx = db.transaction(() => {
    for (const p of products) {
      db.prepare("DELETE FROM sales WHERE product_id = ?").run(p.id);
      const baseRate = 2 + Math.floor(seededRand(p.id) * 8);
      for (let d = 29; d >= 0; d--) {
        const trend = 1 + (29 - d) * 0.01; // gentle upward drift
        const noise = 0.6 + seededRand(p.id * 100 + d) * 0.8;
        const qty = Math.max(0, Math.round(baseRate * trend * noise));
        insert.run(p.id, isoDaysAgo(d), qty);
      }
    }
  });
  tx();
  res.json({ ok: true });
});

r.post("/forecast", requirePerm("stocksense:forecast"), async (req, res) => {
  const products = db.prepare("SELECT id, name, stock FROM products WHERE owner_id = ? ORDER BY id").all(req.user!.id) as any[];
  if (!products.length) return res.status(400).json({ error: "Add some products first" });

  const payload = products.map((p) => {
    const series = salesSeries(p.id);
    const total = series.reduce((s, x) => s + x.qty, 0);
    const avgDaily = series.length ? total / 30 : 0;
    return {
      name: p.name,
      currentStock: p.stock,
      avgDaily: round(avgDaily),
      daysOfCover: avgDaily > 0 ? round(p.stock / avgDaily) : 999,
      last14: series.slice(-14).map((x) => x.qty),
    };
  });

  const schema = {
    type: "object",
    additionalProperties: false,
    properties: {
      items: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            name: { type: "string" },
            reorderQty: { type: "integer" },
            urgency: { type: "string", enum: ["low", "medium", "high"] },
            reason: { type: "string" },
          },
          required: ["name", "reorderQty", "urgency", "reason"],
        },
      },
    },
    required: ["items"],
  };

  try {
    const out = await askJSON({
      system:
        "You are a demand-forecasting assistant for a small Indian kirana store. Given per-product current " +
        "stock, average daily sales, days of cover, and the last 14 days of unit sales, recommend a reorder " +
        "quantity, an urgency, and a one-line reason for each product. Aim for ~2 weeks of cover after reorder, " +
        "account for any upward/downward trend in the recent series, and flag fast-movers running low as 'high'. " +
        "Reason must be short and concrete (mention the trend or days of cover).",
      prompt: JSON.stringify(payload),
      schema,
    });
    // merge stats back for the UI
    const byName = new Map(payload.map((p) => [p.name, p]));
    const items = (out.items || []).map((it: any) => ({ ...byName.get(it.name), ...it }));
    res.json({ items });
  } catch (e) {
    if (e instanceof ClaudeNotConfigured) return res.status(503).json({ error: e.message });
    console.error(e);
    res.status(500).json({ error: "Could not run the forecast right now" });
  }
});

function round(n: number) {
  return Math.round(n * 100) / 100;
}
function todayISO() {
  return new Date().toISOString().slice(0, 10);
}
function isoDaysAgo(d: number) {
  const dt = new Date();
  dt.setDate(dt.getDate() - d);
  return dt.toISOString().slice(0, 10);
}
// deterministic pseudo-random so demo data is stable per product
function seededRand(seed: number) {
  const x = Math.sin(seed * 9973.13) * 10000;
  return x - Math.floor(x);
}

export default r;
