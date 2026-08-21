// The apps and the fine-grained actions each exposes.
// Admin (role === 'admin') implicitly has every app + every action.

export const APPS = ["voicestore", "quickpay", "stocksense", "shortcutforge"] as const;
export type AppKey = (typeof APPS)[number];

export const PERMISSIONS: Record<AppKey, { key: string; label: string }[]> = {
  voicestore: [
    { key: "voicestore:view", label: "View storefronts" },
    { key: "voicestore:create", label: "Create / edit via voice" },
    { key: "voicestore:publish", label: "Publish storefronts" },
  ],
  quickpay: [
    { key: "quickpay:view", label: "View employees & runs" },
    { key: "quickpay:manage", label: "Manage employees" },
    { key: "quickpay:run", label: "Run payroll" },
  ],
  stocksense: [
    { key: "stocksense:view", label: "View inventory" },
    { key: "stocksense:manage", label: "Manage products & sales" },
    { key: "stocksense:forecast", label: "Run demand forecasts" },
  ],
  shortcutforge: [
    { key: "shortcutforge:view", label: "View & download shortcuts" },
    { key: "shortcutforge:create", label: "Generate shortcuts" },
  ],
};

export interface SessionUser {
  id: number;
  email: string;
  name: string | null;
  role: "admin" | "owner";
  apps: string[];
  perms: string[];
}

export function isAdmin(u: SessionUser) {
  return u.role === "admin";
}

export function hasApp(u: SessionUser, app: AppKey) {
  return isAdmin(u) || u.apps.includes(app);
}

export function hasPerm(u: SessionUser, perm: string) {
  return isAdmin(u) || u.perms.includes(perm);
}
