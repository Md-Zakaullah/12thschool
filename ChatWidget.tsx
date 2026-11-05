"use client";
import { useState } from "react";
export default function ChatWidget() {
  const [log, setLog] = useState<{ r: "u" | "a"; t: string }[]>([{ r: "a", t: "Namaste! Fees, attendance ya hostel ke baare mein poochiye." }]);
  const [q, setQ] = useState(""); const [busy, setBusy] = useState(false);
  async function send(e: React.FormEvent) {
    e.preventDefault(); if (!q.trim() || busy) return;
    const m = q; setQ(""); setBusy(true); setLog(l => [...l, { r: "u", t: m }]);
    const res = await fetch("/api/chat", { method: "POST", body: JSON.stringify({ message: m }) });
    const d = await res.json().catch(() => ({ reply: "Kuch gadbad hui, dobara try karein." }));
    setLog(l => [...l, { r: "a", t: d.reply }]); setBusy(false);
  }
  return (<div className="chat"><div className="log" aria-live="polite">{log.map((x, i) => <div key={i} className={x.r}>{x.t}</div>)}</div>
    <form onSubmit={send}><input value={q} onChange={e => setQ(e.target.value)} placeholder="Sawaal likhein…" /><button className="btn" disabled={busy}>Send</button></form></div>);
}
