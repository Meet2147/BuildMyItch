import React from "react";
import ReactDOM from "react-dom/client";
import "@shared/theme.css";
import { AuthProvider, AuthGate } from "@shared/auth";
import { AppShell } from "@shared/AppShell";
import App from "./App";

document.documentElement.style.setProperty("--accent", "#e08a3c");

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <AuthProvider>
      <AuthGate app="stocksense">
        <AppShell app="stocksense">
          <App />
        </AppShell>
      </AuthGate>
    </AuthProvider>
  </React.StrictMode>
);
