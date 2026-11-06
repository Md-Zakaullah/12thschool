"use client";

import { useState, type FormEvent } from "react";

type ChatMessage = { role: "user" | "assistant"; text: string };

export default function ChatWidget() {
  const [messages, setMessages] = useState<ChatMessage[]>([
    { role: "assistant", text: "Namaste! Fees, attendance ya hostel ke baare mein poochiye." },
  ]);
  const [question, setQuestion] = useState("");
  const [busy, setBusy] = useState(false);

  async function send(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const message = question.trim();
    if (!message || busy) return;

    setQuestion("");
    setBusy(true);
    setMessages(current => [...current, { role: "user", text: message }]);
    try {
      const response = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message }),
      });
      const data = await response.json();
      setMessages(current => [...current, {
        role: "assistant",
        text: typeof data.reply === "string" ? data.reply : "Kuch gadbad hui, dobara try karein.",
      }]);
    } catch {
      setMessages(current => [...current, { role: "assistant", text: "Network error. Dobara try karein." }]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="chat" aria-label="School assistant">
      <div className="log" aria-live="polite">
        {messages.map((message, index) => (
          <div key={index} className={message.role === "user" ? "u" : "a"}>{message.text}</div>
        ))}
        {busy && <div className="a">Soch raha hoon…</div>}
      </div>
      <form onSubmit={send}>
        <input aria-label="Ask the school assistant" value={question} onChange={event => setQuestion(event.target.value)} placeholder="Sawaal likhein…" maxLength={2000} />
        <button className="btn" disabled={busy || !question.trim()}>Send</button>
      </form>
    </section>
  );
}
