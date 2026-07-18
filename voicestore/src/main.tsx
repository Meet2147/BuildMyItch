import React from "react";
import ReactDOM from "react-dom/client";
import "@shared/theme.css";
import { AuthProvider, AuthGate } from "@shared/auth";
import { AppShell } from "@shared/AppShell";
import App from "./App";

// VoiceStore accent
document.documentElement.style.setProperty("--accent", "#6d7cff");

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <AuthProvider>
      <AuthGate app="voicestore">
        <AppShell app="voicestore">
          <App />
        </AppShell>
      </AuthGate>
    </AuthProvider>
  </React.StrictMode>
);
