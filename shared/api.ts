// In production (Render), set VITE_API_BASE per app to the deployed backend URL,
// e.g. https://buildmyitch-api.onrender.com/api. Locally it falls back to the dev backend.
const envBase = (import.meta as any).env?.VITE_API_BASE as string | undefined;
export const API_BASE = (envBase && envBase.trim()) || "http://localhost:4000/api";
const TOKEN_KEY = "razit_token";

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}
export function setToken(t: string | null) {
  if (t) localStorage.setItem(TOKEN_KEY, t);
  else localStorage.removeItem(TOKEN_KEY);
}

export async function api<T = any>(path: string, opts: RequestInit = {}): Promise<T> {
  const token = getToken();
  const res = await fetch(API_BASE + path, {
    ...opts,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(opts.headers || {}),
    },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error((data as any).error || `Request failed (${res.status})`);
  return data as T;
}
