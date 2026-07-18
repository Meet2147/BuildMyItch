import React from "react";

const MOOD_BG: Record<string, string> = {
  warm: "#fff4ec",
  fresh: "#eefaf3",
  bold: "#f3eeff",
  calm: "#eef4fb",
};

/** Renders the AI-generated storefront spec as a mini landing page. */
export function SitePreview({ spec }: { spec: any }) {
  const accent = spec?.theme?.accent || "#6d7cff";
  const bg = MOOD_BG[spec?.theme?.mood] || "#fff7f0";
  return (
    <div
      className="fade-in"
      style={{
        borderRadius: 18,
        overflow: "hidden",
        boxShadow: "var(--sh-out)",
        background: "#fff",
      }}
    >
      {/* hero */}
      <div style={{ background: bg, padding: "34px 28px", borderBottom: `4px solid ${accent}` }}>
        <div style={{ fontSize: 13, fontWeight: 800, letterSpacing: 1, color: accent, textTransform: "uppercase" }}>
          {spec.tagline}
        </div>
        <h1 style={{ fontSize: 30, margin: "8px 0", color: "#2c2f45" }}>{spec.businessName}</h1>
        <p style={{ color: "#5b6076", maxWidth: 520, lineHeight: 1.55, margin: 0 }}>{spec.about}</p>
      </div>

      {/* products */}
      <div style={{ padding: "24px 28px", background: "#fff" }}>
        <h3 style={{ color: accent, marginBottom: 14 }}>What we offer</h3>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill,minmax(160px,1fr))", gap: 14 }}>
          {(spec.products || []).map((p: any, i: number) => (
            <div key={i} style={{ border: "1px solid #eee", borderRadius: 14, padding: 14 }}>
              <div style={{ fontWeight: 800, color: "#2c2f45" }}>{p.name}</div>
              <div style={{ color: accent, fontWeight: 800, margin: "4px 0" }}>{p.price}</div>
              <div style={{ fontSize: 13, color: "#7a7f93", lineHeight: 1.4 }}>{p.description}</div>
            </div>
          ))}
        </div>
      </div>

      {/* footer info */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 24, padding: "20px 28px", background: bg }}>
        <div>
          <div style={{ fontWeight: 800, color: "#2c2f45", marginBottom: 4 }}>🕒 Hours</div>
          <div style={{ color: "#5b6076" }}>{spec.hours}</div>
        </div>
        <div>
          <div style={{ fontWeight: 800, color: "#2c2f45", marginBottom: 4 }}>📞 Contact</div>
          <div style={{ color: "#5b6076" }}>{spec.contact?.phone}</div>
          <div style={{ color: "#5b6076" }}>{spec.contact?.address}</div>
        </div>
      </div>
    </div>
  );
}
