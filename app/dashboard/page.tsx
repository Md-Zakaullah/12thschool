import { createClient } from "@/lib/supabase/server";

export default async function DashboardPage() {
  const supabase = await createClient();
  const [students, pendingFees, occupiedBeds, freeBeds] = await Promise.all([
    supabase.from("students").select("id", { count: "exact", head: true }),
    supabase.from("fee_invoices").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("beds").select("id", { count: "exact", head: true }).not("student_id", "is", null),
    supabase.from("beds").select("id", { count: "exact", head: true }).is("student_id", null),
  ]);

  const cards = [
    ["Students", students.count],
    ["Pending invoices", pendingFees.count],
    ["Beds occupied", occupiedBeds.count],
    ["Beds free", freeBeds.count],
  ] as const;

  return (
    <section className="grid" aria-label="School overview">
      {cards.map(([label, value]) => (
        <article className="stat" key={label}>
          <span>{label}</span>
          <b>{value ?? "—"}</b>
        </article>
      ))}
    </section>
  );
}
