import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import ChatWidget from "@/components/ChatWidget";

const NAV: Record<string, [string, string][]> = {
  admin: [["Overview", "/dashboard"], ["Students", "#"], ["Fees", "#"], ["Hostel", "#"], ["Staff", "#"]],
  principal: [["Overview", "/dashboard"], ["Attendance", "#"], ["Results", "#"]],
  teacher: [["Overview", "/dashboard"], ["Mark attendance", "#"], ["Homework", "#"], ["Marks", "#"]],
  student: [["Overview", "/dashboard"], ["Timetable", "#"], ["Fees", "#"], ["Outpass", "#"]],
  parent: [["Overview", "/dashboard"], ["Attendance", "#"], ["Fees", "#"], ["Approve outpass", "#"]],
  warden: [["Overview", "/dashboard"], ["Room map", "#"], ["Outpass", "#"], ["Visitors", "#"], ["Complaints", "#"]],
  accountant: [["Overview", "/dashboard"], ["Invoices", "#"], ["Defaulters", "#"]],
};

export default async function DashboardLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase.from("profiles").select("full_name, role").eq("id", user.id).maybeSingle();
  const role = profile?.role ?? "student";

  return (
    <div className="shell">
      <nav className="side" aria-label="Main navigation">
        <div className="brand">Vidya Campus</div>
        {(NAV[role] ?? NAV.student).map(([label, href]) => (
          <Link key={label} href={href}>{label}</Link>
        ))}
      </nav>
      <main className="main">
        <h1>Namaste, {profile?.full_name ?? "User"}</h1>
        <p style={{ color: "var(--muted)" }}>Role: {role}</p>
        {children}
      </main>
      <ChatWidget />
    </div>
  );
}
