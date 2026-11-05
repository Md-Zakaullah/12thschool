import "./globals.css";
export const metadata = { title: "Vidya Campus — School & Hostel", description: "School and hostel management" };
export default function Root({ children }: { children: React.ReactNode }) {
  return (<html lang="en"><head>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:wght@600&family=Plus+Jakarta+Sans:wght@400;600&display=swap" />
  </head><body>{children}</body></html>);
}
