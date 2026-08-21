export type AppKey = "voicestore" | "quickpay" | "stocksense" | "shortcutforge";

export interface User {
  id: number;
  email: string;
  name: string | null;
  role: "admin" | "owner";
  apps: string[];
  perms: string[];
}

export const APP_META: Record<AppKey, { name: string; tagline: string; accent: string; icon: string }> = {
  voicestore: { name: "MeriDukaan Online", tagline: "Boliye, aur apni dukaan ki website ban jaaye", accent: "#6d7cff", icon: "🏪" },
  quickpay: { name: "QuickPay", tagline: "One-tap payroll for tiny teams", accent: "#4caf87", icon: "💸" },
  stocksense: { name: "StockSense", tagline: "Know what to reorder, before you run out", accent: "#e08a3c", icon: "📦" },
  shortcutforge: { name: "ShortcutForge", tagline: "Say what your iPhone should do — get the Shortcut", accent: "#8a6dff", icon: "⚡" },
};

export function isAdmin(u: User | null) {
  return u?.role === "admin";
}
export function canApp(u: User | null, app: AppKey) {
  return !!u && (u.role === "admin" || u.apps.includes(app));
}
export function canPerm(u: User | null, perm: string) {
  return !!u && (u.role === "admin" || u.perms.includes(perm));
}
