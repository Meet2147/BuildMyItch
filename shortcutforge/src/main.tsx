import React from "react";
import ReactDOM from "react-dom/client";
import "@shared/theme.css";
import { AuthProvider, AuthGate } from "@shared/auth";
import { AppShell } from "@shared/AppShell";
import App from "./App";

// ShortcutForge accent
document.documentElement.style.setProperty("--accent", "#8a6dff");

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <AuthProvider>
      <AuthGate app="shortcutforge">
        <AppShell app="shortcutforge">
          <App />
        </AppShell>
      </AuthGate>
    </AuthProvider>
  </React.StrictMode>
);
