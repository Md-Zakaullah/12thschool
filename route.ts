import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@/lib/supabase/server";
const hits = new Map<string, number[]>();
export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response("Unauthorized", { status: 401 });
  const now = Date.now(); const recent = (hits.get(user.id) ?? []).filter(t => now - t < 60_000);
  if (recent.length >= 8) return Response.json({ reply: "Thoda ruko, 1 minute mein dobara poochiye." });
  hits.set(user.id, [...recent, now]);
  const { message } = await req.json();
  // RLS ki wajah se user ko sirf apna data milta hai
  const [{ data: profile }, { data: fees }, { data: att }] = await Promise.all([
    supabase.from("profiles").select("full_name,role").eq("id", user.id).single(),
    supabase.from("fee_invoices").select("title,amount,status,due_date").limit(20),
    supabase.from("attendance").select("date,status").order("date", { ascending: false }).limit(30),
  ]);
  const model = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!).getGenerativeModel({ model: "gemini-2.5-flash" });
  const prompt = `You are the school assistant. Reply briefly in the user's language (Hindi/English/Hinglish). Use only the data given; if missing, say so.
User: ${JSON.stringify(profile)}\nFees: ${JSON.stringify(fees)}\nRecent attendance: ${JSON.stringify(att)}\nQuestion: ${message}`;
  try { const r = await model.generateContent(prompt); return Response.json({ reply: r.response.text() }); }
  catch { return Response.json({ reply: "AI abhi available nahi hai." }); }
}
