"use client";

import { useState, type FormEvent } from "react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setErrorMessage("");
    setBusy(true);
    try {
      const { error } = await createClient().auth.signInWithPassword({ email, password });
      if (error) {
        setErrorMessage("Email ya password galat hai.");
        return;
      }
      window.location.assign("/dashboard");
    } catch {
      setErrorMessage("Login abhi complete nahi ho saka. Dobara try karein.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="login" onSubmit={submit}>
      <h1>Vidya Campus</h1>
      <p style={{ color: "var(--muted)" }}>Apne account se sign in karein.</p>
      <label htmlFor="email">Email</label>
      <input id="email" type="email" autoComplete="username" placeholder="Email" value={email} onChange={event => setEmail(event.target.value)} required />
      <label htmlFor="password">Password</label>
      <input id="password" type="password" autoComplete="current-password" placeholder="Password" value={password} onChange={event => setPassword(event.target.value)} required />
      {errorMessage && <p role="alert" style={{ color: "#c0392b" }}>{errorMessage}</p>}
      <button className="btn" style={{ width: "100%" }} disabled={busy}>{busy ? "Signing in…" : "Sign in"}</button>
    </form>
  );
}
