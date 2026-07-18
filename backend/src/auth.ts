import type { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { db } from "./db.js";
import type { SessionUser } from "./permissions.js";
import { hasPerm as _hasPerm } from "./permissions.js";

const SECRET = process.env.JWT_SECRET || "dev-insecure-secret";

export function signToken(userId: number) {
  return jwt.sign({ uid: userId }, SECRET, { expiresIn: "30d" });
}

interface UserRow {
  id: number;
  email: string;
  name: string | null;
  role: "admin" | "owner";
  apps: string;
  perms: string;
}

export function loadUser(userId: number): SessionUser | null {
  const row = db
    .prepare("SELECT id, email, name, role, apps, perms FROM users WHERE id = ?")
    .get(userId) as UserRow | undefined;
  if (!row) return null;
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    role: row.role,
    apps: JSON.parse(row.apps || "[]"),
    perms: JSON.parse(row.perms || "[]"),
  };
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: SessionUser;
    }
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "Not signed in" });
  try {
    const { uid } = jwt.verify(token, SECRET) as { uid: number };
    const user = loadUser(uid);
    if (!user) return res.status(401).json({ error: "Account not found" });
    req.user = user;
    next();
  } catch {
    return res.status(401).json({ error: "Session expired, please sign in again" });
  }
}

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  if (req.user?.role !== "admin") return res.status(403).json({ error: "Admins only" });
  next();
}

export function requirePerm(perm: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user || !_hasPerm(req.user, perm)) {
      return res.status(403).json({ error: `Missing permission: ${perm}` });
    }
    next();
  };
}
