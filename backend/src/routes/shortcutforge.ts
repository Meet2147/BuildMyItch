import { Router } from "express";
import { db } from "../db.js";
import { requireAuth, requirePerm } from "../auth.js";
import { askJSON, ClaudeNotConfigured } from "../claude.js";
import { buildShortcutFile } from "../shortcutFile.js";

const r = Router();
r.use(requireAuth);

const SHORTCUT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    name: { type: "string", description: "Short shortcut name, e.g. 'Heading Home'" },
    emoji: { type: "string", description: "One emoji that fits the shortcut" },
    summary: { type: "string", description: "One friendly sentence: what the shortcut does when you run it" },
    requirements: {
      type: "array",
      items: { type: "string" },
      description: "Things the user needs before building: apps installed, permissions to allow, values to have ready. Empty if none.",
    },
    steps: {
      type: "array",
      description: "The exact actions to add in the Shortcuts app, in order.",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          action: { type: "string", description: "Exact action name as it appears in the Shortcuts action library, e.g. 'Send Message'" },
          search: { type: "string", description: "What to type in the action search bar to find it" },
          config: {
            type: "array",
            description: "Fields to set on the action after adding it. Empty if defaults are fine.",
            items: {
              type: "object",
              additionalProperties: false,
              properties: {
                field: { type: "string" },
                value: { type: "string" },
              },
              required: ["field", "value"],
            },
          },
          note: { type: "string", description: "One short sentence: what this step does or a tip for configuring it" },
        },
        required: ["action", "search", "config", "note"],
      },
    },
    actions: {
      type: "array",
      description: "The same steps as machine-readable workflow actions for the .shortcut file.",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          identifier: {
            type: "string",
            description: "Real WFWorkflowActionIdentifier, e.g. 'is.workflow.actions.sendmessage'",
          },
          parametersJson: {
            type: "string",
            description: "JSON object string of WFWorkflowActionParameters for this action. '{}' if none.",
          },
        },
        required: ["identifier", "parametersJson"],
      },
    },
    testTip: { type: "string", description: "One sentence telling the user how to test the finished shortcut" },
  },
  required: ["name", "emoji", "summary", "requirements", "steps", "actions", "testTip"],
};

const SYSTEM =
  "You are an expert iOS Shortcuts author. The user describes, in casual language, something they " +
  "want their iPhone to do; you design a working shortcut built only from actions that actually exist " +
  "in the iOS Shortcuts app (built-in actions whenever possible; if a third-party app is unavoidable, " +
  "list it in requirements). Produce two parallel views of the same shortcut: " +
  "(1) steps — a beginner-friendly build guide using the exact action names and field labels shown in " +
  "the Shortcuts app, in the exact order to add them; " +
  "(2) actions — the same sequence as real WFWorkflowActionIdentifier entries " +
  "(e.g. is.workflow.actions.gettext, is.workflow.actions.sendmessage, is.workflow.actions.delay) with " +
  "correct WFWorkflowActionParameters encoded as a JSON string. Use conservative, well-known " +
  "identifiers and parameters; when a value must reference a previous action's output, prefer asking " +
  "the user each run (WFAskWhenRun style) or keep the parameter simple rather than inventing exotic " +
  "attachment structures. Never ask questions — make sensible assumptions and mention them in the " +
  "step notes or requirements. Keep it as short as the idea allows.";

interface StoredShortcut {
  id: number;
  owner_id?: number;
  name: string;
  request: string;
  spec: string;
  created_at: string;
}

function publicRow(row: StoredShortcut) {
  const { owner_id, ...rest } = row;
  return { ...rest, spec: JSON.parse(row.spec) };
}

r.get("/shortcuts", requirePerm("shortcutforge:view"), (req, res) => {
  const rows = db
    .prepare("SELECT id, name, request, spec, created_at FROM shortcuts WHERE owner_id = ? ORDER BY id DESC")
    .all(req.user!.id) as StoredShortcut[];
  res.json({ shortcuts: rows.map(publicRow) });
});

r.post("/generate", requirePerm("shortcutforge:create"), async (req, res) => {
  const request = String(req.body.request || "").trim();
  if (!request) return res.status(400).json({ error: "Describe your shortcut idea first" });
  try {
    const spec = await askJSON({
      system: SYSTEM,
      prompt: `The user wants this shortcut:\n"""${request}"""\n\nDesign it.`,
      schema: SHORTCUT_SCHEMA,
    });
    // Claude returns action parameters as JSON strings — parse them once here
    // so the stored spec is plain JSON all the way down.
    spec.actions = (spec.actions || []).map((a: any) => {
      let parameters: Record<string, unknown> = {};
      try {
        const parsed = JSON.parse(a.parametersJson || "{}");
        if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) parameters = parsed;
      } catch {
        // leave the action parameter-less rather than failing the whole shortcut
      }
      return { identifier: a.identifier, parameters };
    });
    const info = db
      .prepare("INSERT INTO shortcuts (owner_id, name, request, spec) VALUES (?, ?, ?, ?)")
      .run(req.user!.id, spec.name || "My Shortcut", request, JSON.stringify(spec));
    const row = db
      .prepare("SELECT id, name, request, spec, created_at FROM shortcuts WHERE id = ?")
      .get(info.lastInsertRowid) as StoredShortcut;
    res.json({ shortcut: publicRow(row) });
  } catch (e) {
    if (e instanceof ClaudeNotConfigured) return res.status(503).json({ error: e.message });
    console.error(e);
    res.status(500).json({ error: "Could not design the shortcut right now" });
  }
});

r.get("/shortcuts/:id/file", requirePerm("shortcutforge:view"), (req, res) => {
  const id = Number(req.params.id);
  const row = db.prepare("SELECT * FROM shortcuts WHERE id = ?").get(id) as StoredShortcut | undefined;
  if (!row || row.owner_id !== req.user!.id) return res.status(404).json({ error: "Not found" });
  const spec = JSON.parse(row.spec);
  const file = buildShortcutFile(spec.actions || []);
  const safeName = String(row.name).replace(/[^\w\- ]+/g, "").trim() || "Shortcut";
  res.setHeader("Content-Type", "application/octet-stream");
  res.setHeader("Content-Disposition", `attachment; filename="${safeName}.shortcut"`);
  res.send(file);
});

r.delete("/shortcuts/:id", requirePerm("shortcutforge:create"), (req, res) => {
  const id = Number(req.params.id);
  const row = db.prepare("SELECT owner_id FROM shortcuts WHERE id = ?").get(id) as any;
  if (!row || row.owner_id !== req.user!.id) return res.status(404).json({ error: "Not found" });
  db.prepare("DELETE FROM shortcuts WHERE id = ?").run(id);
  res.json({ ok: true });
});

export default r;
