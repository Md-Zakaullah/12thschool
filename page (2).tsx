import { createClient } from "@/lib/supabase/server";
export default async function Dashboard() {
  const s = await createClient();
  const [stu, pend, beds, free] = await Promise.all([
    s.from("students").select("*", { count: "exact", head: true }),
    s.from("fee_invoices").select("*", { count: "exact", head: true }).eq("status", "pending"),
    s.from("beds").select("*", { count: "exact", head: true }).not("student_id", "is", null),
    s.from("beds").select("*", { count: "exact", head: true }).is("student_id", null),
  ]);
  const cards = [["Students", stu.count], ["Pending invoices", pend.count], ["Beds occupied", beds.count], ["Beds free", free.count]];
  return (<div className="grid">{cards.map(([l, v]) => <div className="stat" key={l as string}><span>{l}</span><b>{v ?? 0}</b></div>)}</div>);
}
