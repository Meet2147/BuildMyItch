import React, { useEffect, useState } from "react";
import { api } from "@shared/api";
import { useAuth } from "@shared/auth";
import { canPerm } from "@shared/types";
import { NeoButton, NeoCard, NeoInput, NeoBadge, Field, Money } from "@shared/neo";

interface Employee { id: number; name: string; base: number; }
interface RunLine {
  name: string; base: number; unpaidDays: number; paidLeave: number; overtimeHours: number;
  unpaidDeduction: number; overtimePay: number; bonus: number; net: number;
}
interface Run { id: number; period: string; result: { period: string; workingDays: number; lines: RunLine[]; total: number }; note: string; }
interface Draft { unpaidDays: string; paidLeave: string; overtimeHours: string; bonus: string; }

const emptyDraft: Draft = { unpaidDays: "", paidLeave: "", overtimeHours: "", bonus: "" };

export default function App() {
  const { user } = useAuth();
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [runs, setRuns] = useState<Run[]>([]);
  const [name, setName] = useState("");
  const [base, setBase] = useState("");
  const [period, setPeriod] = useState(new Date().toISOString().slice(0, 7));
  const [workingDays, setWorkingDays] = useState("26");
  const [drafts, setDrafts] = useState<Record<number, Draft>>({});
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  const canManage = canPerm(user, "quickpay:manage");
  const canRun = canPerm(user, "quickpay:run");

  async function load() {
    try {
      const [e, r] = await Promise.all([
        api<{ employees: Employee[] }>("/quickpay/employees"),
        api<{ runs: Run[] }>("/quickpay/runs"),
      ]);
      setEmployees(e.employees);
      setRuns(r.runs);
    } catch (e: any) { setErr(e.message); }
  }
  useEffect(() => { load(); }, []);

  async function addEmployee(e: React.FormEvent) {
    e.preventDefault();
    setErr("");
    try {
      const { employee } = await api<{ employee: Employee }>("/quickpay/employees", {
        method: "POST", body: JSON.stringify({ name, base: Number(base) }),
      });
      setEmployees((s) => [...s, employee]);
      setName(""); setBase("");
    } catch (e: any) { setErr(e.message); }
  }
  async function removeEmployee(id: number) {
    await api(`/quickpay/employees/${id}`, { method: "DELETE" });
    setEmployees((s) => s.filter((x) => x.id !== id));
  }

  function setDraft(id: number, patch: Partial<Draft>) {
    setDrafts((d) => ({ ...d, [id]: { ...(d[id] || emptyDraft), ...patch } }));
  }

  async function runPayroll() {
    setErr(""); setBusy(true);
    try {
      const rows = employees.map((emp) => {
        const d = drafts[emp.id] || emptyDraft;
        return {
          employeeId: emp.id,
          unpaidDays: Number(d.unpaidDays) || 0,
          paidLeave: Number(d.paidLeave) || 0,
          overtimeHours: Number(d.overtimeHours) || 0,
          bonus: Number(d.bonus) || 0,
        };
      });
      const { run } = await api<{ run: Run }>("/quickpay/run", {
        method: "POST", body: JSON.stringify({ period, workingDays: Number(workingDays), rows }),
      });
      setRuns((s) => [run, ...s]);
    } catch (e: any) { setErr(e.message); }
    finally { setBusy(false); }
  }

  return (
    <div className="col" style={{ gap: 24 }}>
      <div className="row wrap" style={{ gap: 24, alignItems: "flex-start" }}>
        {/* Employees */}
        <NeoCard className="fade-in grow" style={{ flex: "1 1 300px" }}>
          <h2>👥 Your team</h2>
          <p className="muted" style={{ marginTop: 4 }}>Add each worker once with their monthly salary.</p>
          {canManage && (
            <form className="row wrap" style={{ gap: 10, marginTop: 12 }} onSubmit={addEmployee}>
              <NeoInput placeholder="Name" value={name} onChange={(e) => setName(e.target.value)} style={{ width: 150 }} required />
              <NeoInput placeholder="Monthly ₹" type="number" value={base} onChange={(e) => setBase(e.target.value)} style={{ width: 130 }} required />
              <NeoButton variant="primary" type="submit">+ Add</NeoButton>
            </form>
          )}
          <div className="col" style={{ gap: 8, marginTop: 14 }}>
            {employees.map((e) => (
              <div key={e.id} className="row neo-inset" style={{ padding: "10px 14px" }}>
                <b className="grow" style={{ color: "var(--text-strong)" }}>{e.name}</b>
                <span className="muted"><Money value={e.base} />/mo</span>
                {canManage && <NeoButton variant="ghost" className="danger" onClick={() => removeEmployee(e.id)}>✕</NeoButton>}
              </div>
            ))}
            {!employees.length && <p className="muted">No team members yet.</p>}
          </div>
        </NeoCard>

        {/* Run payroll */}
        {canRun && employees.length > 0 && (
          <NeoCard className="fade-in" style={{ flex: "1 1 340px" }}>
            <h2>🧮 Run this month's payroll</h2>
            <div className="row wrap" style={{ gap: 12, marginTop: 10 }}>
              <Field label="Period"><NeoInput value={period} onChange={(e) => setPeriod(e.target.value)} style={{ width: 130 }} /></Field>
              <Field label="Working days"><NeoInput type="number" value={workingDays} onChange={(e) => setWorkingDays(e.target.value)} style={{ width: 110 }} /></Field>
            </div>
            <div className="col" style={{ gap: 10, marginTop: 12 }}>
              {employees.map((emp) => {
                const d = drafts[emp.id] || emptyDraft;
                return (
                  <div key={emp.id} className="neo-inset" style={{ padding: 12 }}>
                    <b style={{ color: "var(--text-strong)" }}>{emp.name}</b>
                    <div className="row wrap" style={{ gap: 8, marginTop: 8 }}>
                      <MiniField label="Unpaid days" value={d.unpaidDays} onChange={(v) => setDraft(emp.id, { unpaidDays: v })} />
                      <MiniField label="Paid leave" value={d.paidLeave} onChange={(v) => setDraft(emp.id, { paidLeave: v })} />
                      <MiniField label="OT hours" value={d.overtimeHours} onChange={(v) => setDraft(emp.id, { overtimeHours: v })} />
                      <MiniField label="Bonus ₹" value={d.bonus} onChange={(v) => setDraft(emp.id, { bonus: v })} />
                    </div>
                  </div>
                );
              })}
            </div>
            <NeoButton variant="primary" loading={busy} onClick={runPayroll} style={{ marginTop: 14 }}>
              💸 Calculate payroll
            </NeoButton>
          </NeoCard>
        )}
      </div>

      {err && <p style={{ color: "var(--danger)", fontWeight: 700 }}>{err}</p>}

      {/* Results */}
      <div className="col">
        <h3>Payroll history</h3>
        {runs.length === 0 && <p className="muted">No payroll runs yet.</p>}
        {runs.map((run) => (
          <NeoCard key={run.id} className="fade-in">
            <div className="row">
              <h3 className="grow">{run.result.period}</h3>
              <NeoBadge tone="ok">Total <Money value={run.result.total} /></NeoBadge>
            </div>
            {run.note && (
              <div className="neo-inset" style={{ padding: 12, marginTop: 10, color: "var(--text)", lineHeight: 1.5 }}>
                💬 {run.note}
              </div>
            )}
            <div style={{ overflowX: "auto", marginTop: 12 }}>
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>
                <thead>
                  <tr style={{ color: "var(--text-soft)", textAlign: "right" }}>
                    <th style={{ textAlign: "left", padding: 6 }}>Name</th>
                    <th style={{ padding: 6 }}>Base</th>
                    <th style={{ padding: 6 }}>Unpaid</th>
                    <th style={{ padding: 6 }}>OT pay</th>
                    <th style={{ padding: 6 }}>Bonus</th>
                    <th style={{ padding: 6 }}>Net pay</th>
                  </tr>
                </thead>
                <tbody>
                  {run.result.lines.map((l, i) => (
                    <tr key={i} style={{ textAlign: "right", borderTop: "1px solid var(--shadow-dark)" }}>
                      <td style={{ textAlign: "left", padding: 6, fontWeight: 700, color: "var(--text-strong)" }}>{l.name}</td>
                      <td style={{ padding: 6 }}><Money value={l.base} /></td>
                      <td style={{ padding: 6, color: l.unpaidDeduction ? "var(--danger)" : undefined }}>−<Money value={l.unpaidDeduction} /></td>
                      <td style={{ padding: 6, color: l.overtimePay ? "var(--ok)" : undefined }}>+<Money value={l.overtimePay} /></td>
                      <td style={{ padding: 6, color: l.bonus ? "var(--ok)" : undefined }}>+<Money value={l.bonus} /></td>
                      <td style={{ padding: 6, fontWeight: 800, color: "var(--text-strong)" }}><Money value={l.net} /></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </NeoCard>
        ))}
      </div>
    </div>
  );
}

function MiniField({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <label className="col" style={{ gap: 4 }}>
      <span style={{ fontSize: 11, fontWeight: 800, color: "var(--text-soft)" }}>{label}</span>
      <NeoInput type="number" value={value} onChange={(e) => onChange(e.target.value)} placeholder="0" style={{ width: 90, padding: "9px 12px" }} />
    </label>
  );
}
