"use client";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
export default function Login() {
  const [email, setEmail] = useState(""); const [password, setPassword] = useState(""); const [err, setErr] = useState("");
  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const { error } = await createClient().auth.signInWithPassword({ email, password });
    if (error) setErr("Email ya password galat hai."); else location.href = "/dashboard";
  }
  return (<form className="login" onSubmit={submit}>
    <h1>Vidya Campus</h1><p style={{ color: "var(--muted)" }}>Apne account se sign in karein.</p>
    <input type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} required />
    <input type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} required />
    {err && <p role="alert" style={{ color: "#c0392b" }}>{err}</p>}
    <button className="btn" style={{ width: "100%" }}>Sign in</button>
  </form>);
}
