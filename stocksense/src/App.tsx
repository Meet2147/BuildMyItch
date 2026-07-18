import React, { useEffect, useState } from "react";
import { api } from "@shared/api";
import { useAuth } from "@shared/auth";
import { canPerm } from "@shared/types";
import { NeoButton, NeoCard, NeoInput, NeoBadge, Field } from "@shared/neo";

interface Product { id: number; name: string; sku: string | null; stock: number; avgDaily: number; soldLast30: number; }
interface Forecast { name: string; currentStock: number; avgDaily: number; daysOfCover: number; last14: number[]; reorderQty: number; urgency: "low" | "medium" | "high"; reason: string; }

export default function App() {
  const { user } = useAuth();
  const [products, setProducts] = useState<Product[]>([]);
  const [forecast, setForecast] = useState<Forecast[]>([]);
  const [name, setName] = useState("");
  const [sku, setSku] = useState("");
  const [stock, setStock] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  const canManage = canPerm(user, "stocksense:manage");
  const canForecast = canPerm(user, "stocksense:forecast");

  async function load() {
    try {
      const { products } = await api<{ products: Product[] }>("/stocksense/products");
      setProducts(products);
    } catch (e: any) { setErr(e.message); }
  }
  useEffect(() => { load(); }, []);

  async function addProduct(e: React.FormEvent) {
    e.preventDefault();
    setErr("");
    try {
      await api("/stocksense/products", { method: "POST", body: JSON.stringify({ name, sku, stock: Number(stock) }) });
      setName(""); setSku(""); setStock("");
      load();
    } catch (e: any) { setErr(e.message); }
  }
  async function removeProduct(id: number) {
    await api(`/stocksense/products/${id}`, { method: "DELETE" });
    load();
  }
  async function recordSale(id: number, qty: number) {
    await api(`/stocksense/products/${id}/sale`, { method: "POST", body: JSON.stringify({ qty }) });
    load();
  }
  async function seedDemo() {
    setBusy(true);
    try { await api("/stocksense/seed-demo", { method: "POST" }); await load(); }
    finally { setBusy(false); }
  }
  async function runForecast() {
    setErr(""); setBusy(true);
    try {
      const { items } = await api<{ items: Forecast[] }>("/stocksense/forecast", { method: "POST" });
      setForecast(items);
    } catch (e: any) { setErr(e.message); }
    finally { setBusy(false); }
  }

  return (
    <div className="col" style={{ gap: 24 }}>
      <NeoCard className="fade-in">
        <div className="row wrap">
          <div className="grow">
            <h2>📦 Your inventory</h2>
            <p className="muted" style={{ marginTop: 4 }}>Add products and log daily sales. StockSense learns the pattern.</p>
          </div>
          {canManage && (
            <NeoButton onClick={seedDemo} loading={busy}>⚡ Fill demo sales history</NeoButton>
          )}
        </div>

        {canManage && (
          <form className="row wrap" style={{ gap: 10, marginTop: 14 }} onSubmit={addProduct}>
            <NeoInput placeholder="Product name" value={name} onChange={(e) => setName(e.target.value)} style={{ width: 170 }} required />
            <NeoInput placeholder="SKU (optional)" value={sku} onChange={(e) => setSku(e.target.value)} style={{ width: 130 }} />
            <NeoInput placeholder="In stock" type="number" value={stock} onChange={(e) => setStock(e.target.value)} style={{ width: 110 }} required />
            <NeoButton variant="primary" type="submit">+ Add product</NeoButton>
          </form>
        )}

        <div className="col" style={{ gap: 8, marginTop: 16 }}>
          {products.map((p) => (
            <div key={p.id} className="row wrap neo-inset" style={{ padding: "10px 14px", gap: 10 }}>
              <div className="grow">
                <b style={{ color: "var(--text-strong)" }}>{p.name}</b>
                {p.sku && <span className="muted" style={{ fontSize: 12 }}> · {p.sku}</span>}
              </div>
              <NeoBadge tone={p.stock <= p.avgDaily * 5 ? "danger" : ""}>{p.stock} in stock</NeoBadge>
              <NeoBadge>~{p.avgDaily}/day</NeoBadge>
              {canManage && (
                <div className="row" style={{ gap: 6 }}>
                  <NeoButton variant="ghost" onClick={() => recordSale(p.id, 1)}>Sold 1</NeoButton>
                  <NeoButton variant="ghost" onClick={() => recordSale(p.id, 5)}>Sold 5</NeoButton>
                  <NeoButton variant="ghost" className="danger" onClick={() => removeProduct(p.id)}>✕</NeoButton>
                </div>
              )}
            </div>
          ))}
          {!products.length && <p className="muted">No products yet — add some above.</p>}
        </div>
      </NeoCard>

      {canForecast && products.length > 0 && (
        <NeoCard className="fade-in">
          <div className="row wrap">
            <div className="grow">
              <h2>🔮 What to reorder</h2>
              <p className="muted" style={{ marginTop: 4 }}>AI reads your sales trend and tells you what's about to run out.</p>
            </div>
            <NeoButton variant="primary" loading={busy} onClick={runForecast}>Run forecast</NeoButton>
          </div>

          <div className="col" style={{ gap: 10, marginTop: 16 }}>
            {forecast.map((f) => (
              <div key={f.name} className="neo-inset fade-in" style={{ padding: 14 }}>
                <div className="row wrap" style={{ gap: 10 }}>
                  <b className="grow" style={{ color: "var(--text-strong)", fontSize: 16 }}>{f.name}</b>
                  <NeoBadge tone={f.urgency}>{f.urgency.toUpperCase()}</NeoBadge>
                  <NeoBadge tone="accent">Reorder {f.reorderQty}</NeoBadge>
                </div>
                <div className="row wrap" style={{ gap: 14, marginTop: 8, fontSize: 13 }} >
                  <span className="muted">Stock: <b>{f.currentStock}</b></span>
                  <span className="muted">Sells ~<b>{f.avgDaily}</b>/day</span>
                  <span className="muted">Cover: <b>{f.daysOfCover >= 999 ? "∞" : f.daysOfCover + " days"}</b></span>
                  <Spark data={f.last14} />
                </div>
                <div style={{ marginTop: 8, color: "var(--text)", lineHeight: 1.5 }}>💡 {f.reason}</div>
              </div>
            ))}
            {!forecast.length && <p className="muted">Run the forecast to see reorder recommendations.</p>}
          </div>
        </NeoCard>
      )}

      {err && <p style={{ color: "var(--danger)", fontWeight: 700 }}>{err}</p>}
    </div>
  );
}

// tiny inline sparkline of the last 14 days
function Spark({ data }: { data: number[] }) {
  if (!data?.length) return null;
  const max = Math.max(...data, 1);
  return (
    <span style={{ display: "inline-flex", alignItems: "flex-end", gap: 2, height: 22 }}>
      {data.map((v, i) => (
        <span key={i} style={{ width: 4, height: Math.max(2, (v / max) * 22), background: "var(--accent)", borderRadius: 2, opacity: 0.5 + (i / data.length) * 0.5 }} />
      ))}
    </span>
  );
}
