import "dotenv/config";
import express from "express";
import cors from "cors";
import "./db.js";
import { claudeReady } from "./claude.js";
import authRoutes from "./routes/auth.js";
import adminRoutes from "./routes/admin.js";
import voicestoreRoutes from "./routes/voicestore.js";
import quickpayRoutes from "./routes/quickpay.js";
import stocksenseRoutes from "./routes/stocksense.js";
import shortcutforgeRoutes from "./routes/shortcutforge.js";

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/api/health", (_req, res) => res.json({ ok: true, claudeReady }));

app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/voicestore", voicestoreRoutes);
app.use("/api/quickpay", quickpayRoutes);
app.use("/api/stocksense", stocksenseRoutes);
app.use("/api/shortcutforge", shortcutforgeRoutes);

const PORT = Number(process.env.PORT) || 4000;
app.listen(PORT, () => {
  console.log(`[backend] listening on http://localhost:${PORT}`);
  if (!claudeReady) {
    console.log("[backend] ⚠  ANTHROPIC_API_KEY not set — AI features will return a friendly error.");
    console.log("[backend]    Add it to backend/.env to enable voice-to-site, payroll notes & forecasts.");
  }
});
