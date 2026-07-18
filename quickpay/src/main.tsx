import React from "react";
import ReactDOM from "react-dom/client";
import "@shared/theme.css";
import { AuthProvider, AuthGate } from "@shared/auth";
import { AppShell } from "@shared/AppShell";
import App from "./App";

document.documentElement.style.setProperty("--accent", "#4caf87");

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <AuthProvider>
      <AuthGate app="quickpay">
        <AppShell app="quickpay">
          <App />
        </AppShell>
      </AuthGate>
    </AuthProvider>
  </React.StrictMode>
);
