import { Router } from "express";
import { db } from "../db.js";
import { requireAuth, requirePerm } from "../auth.js";
import { askJSON, ClaudeNotConfigured } from "../claude.js";

const r = Router();
r.use(requireAuth);

const SITE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    businessName: { type: "string" },
    tagline: { type: "string" },
    about: { type: "string" },
    theme: {
      type: "object",
      additionalProperties: false,
      properties: {
        accent: { type: "string", description: "hex colour, e.g. #E07A5F" },
        mood: { type: "string", enum: ["warm", "fresh", "bold", "calm"] },
      },
      required: ["accent", "mood"],
    },
    products: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          name: { type: "string" },
          price: { type: "string" },
          description: { type: "string" },
        },
        required: ["name", "price", "description"],
      },
    },
    hours: { type: "string" },
    contact: {
      type: "object",
      additionalProperties: false,
      properties: {
        phone: { type: "string" },
        address: { type: "string" },
      },
      required: ["phone", "address"],
    },
  },
  required: ["businessName", "tagline", "about", "theme", "products", "hours", "contact"],
};

const SYSTEM =
  "You turn a shop owner's spoken description into a clean storefront website spec. " +
  "The owner is non-technical and may speak casually or in Hinglish. Infer sensible defaults " +
  "for anything unstated (friendly tagline, a short 'about', 3-6 plausible products with prices " +
  "in INR like '₹120', reasonable hours, placeholder contact if none given). Keep copy short, " +
  "warm and concrete. Never ask questions — always produce a complete, usable storefront.";

r.get("/sites", requirePerm("voicestore:view"), (req, res) => {
  const rows = db
    .prepare("SELECT id, name, transcript, spec, published, created_at FROM sites WHERE owner_id = ? ORDER BY id DESC")
    .all(req.user!.id) as any[];
  res.json({ sites: rows.map((s) => ({ ...s, published: Boolean(s.published), spec: JSON.parse(s.spec) })) });
});

r.post("/generate", requirePerm("voicestore:create"), async (req, res) => {
  const transcript = String(req.body.transcript || "").trim();
  if (!transcript) return res.status(400).json({ error: "Please describe your shop first" });
  try {
    const spec = await askJSON({
      system: SYSTEM,
      prompt: `The shop owner said:\n"""${transcript}"""\n\nBuild their storefront.`,
      schema: SITE_SCHEMA,
    });
    const info = db
      .prepare("INSERT INTO sites (owner_id, name, transcript, spec) VALUES (?, ?, ?, ?)")
      .run(req.user!.id, spec.businessName || "My Shop", transcript, JSON.stringify(spec));
    const row = db.prepare("SELECT id, name, transcript, spec, published, created_at FROM sites WHERE id = ?").get(info.lastInsertRowid) as any;
    res.json({ site: { ...row, published: Boolean(row.published), spec: JSON.parse(row.spec) } });
  } catch (e) {
    if (e instanceof ClaudeNotConfigured) return res.status(503).json({ error: e.message });
    console.error(e);
    res.status(500).json({ error: "Could not build the site right now" });
  }
});

r.post("/sites/:id/publish", requirePerm("voicestore:publish"), (req, res) => {
  const id = Number(req.params.id);
  const site = db.prepare("SELECT owner_id, published FROM sites WHERE id = ?").get(id) as any;
  if (!site || site.owner_id !== req.user!.id) return res.status(404).json({ error: "Not found" });
  const next = site.published ? 0 : 1;
  db.prepare("UPDATE sites SET published = ? WHERE id = ?").run(next, id);
  res.json({ published: Boolean(next) });
});

r.delete("/sites/:id", requirePerm("voicestore:create"), (req, res) => {
  const id = Number(req.params.id);
  const site = db.prepare("SELECT owner_id FROM sites WHERE id = ?").get(id) as any;
  if (!site || site.owner_id !== req.user!.id) return res.status(404).json({ error: "Not found" });
  db.prepare("DELETE FROM sites WHERE id = ?").run(id);
  res.json({ ok: true });
});

export default r;
