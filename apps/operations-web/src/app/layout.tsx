import type { Metadata } from "next";
import { OperationsShell } from "@/components/operations-shell";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Fieldwork Operations",
    template: "%s | Fieldwork Operations",
  },
  description: "Admin and merchant operations console for commerce networks.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <OperationsShell>{children}</OperationsShell>
      </body>
    </html>
  );
}
