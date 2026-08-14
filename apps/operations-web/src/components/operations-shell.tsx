"use client";

import { Icon } from "@/components/icon";
import { SessionProvider, useSession } from "@/components/session-context";
import { SignIn } from "@/components/sign-in";
import { isAdminRole, roleLabel } from "@/lib/roles";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";

type NavigationItem = {
  href: string;
  label: string;
  icon: "overview" | "categories" | "merchants" | "catalog" | "orders" | "settings";
  adminOnly?: boolean;
};

const navigation: NavigationItem[] = [
  { href: "/", label: "Overview", icon: "overview" },
  { href: "/categories", label: "Categories", icon: "categories", adminOnly: true },
  { href: "/merchants", label: "Merchants", icon: "merchants", adminOnly: true },
  { href: "/catalog", label: "Catalog", icon: "catalog" },
  { href: "/orders", label: "Orders", icon: "orders" },
  { href: "/settings", label: "Settings", icon: "settings" },
];

const pageTitles: Record<string, string> = {
  "/": "Overview",
  "/categories": "Categories",
  "/merchants": "Merchants",
  "/catalog": "Catalog",
  "/orders": "Orders",
  "/settings": "Settings",
};

export function OperationsShell({ children }: { children: ReactNode }) {
  return (
    <SessionProvider>
      <ProtectedOperationsShell>{children}</ProtectedOperationsShell>
    </SessionProvider>
  );
}

function ProtectedOperationsShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const { status, session, signOut } = useSession();

  if (status === "loading") {
    return (
      <main className="ops-boot-screen">
        <div className="ops-boot-mark" aria-hidden="true" />
        <p>Preparing your operations workspace</p>
      </main>
    );
  }

  if (!session) {
    return <SignIn />;
  }

  const isAdmin = isAdminRole(session.user.role);
  const availableNavigation = navigation.filter((item) => !item.adminOnly || isAdmin);
  const displayName = session.user.name || session.user.email || "Operations user";
  const initial = displayName.trim().charAt(0).toUpperCase() || "O";
  const currentTitle = pageTitles[pathname] ?? "Operations";

  return (
    <div className="ops-shell">
      <aside className="ops-sidebar">
        <div className="ops-sidebar-top">
          <Link className="ops-brand" href="/" aria-label="Fieldwork operations overview">
            <span className="ops-brand-mark" aria-hidden="true">
              <i />
              <i />
              <i />
            </span>
            <span>Fieldwork</span>
          </Link>
          <div className="ops-workspace-label">
            <span className="ops-workspace-dot" />
            {isAdmin ? "Network control" : "Merchant workspace"}
          </div>
        </div>

        <nav className="ops-nav" aria-label="Operations navigation">
          <p className="ops-nav-label">Workspace</p>
          {availableNavigation.map((item) => {
            const active = pathname === item.href;
            return (
              <Link
                className={`ops-nav-link${active ? " ops-nav-link-active" : ""}`}
                href={item.href}
                key={item.href}
              >
                <Icon name={item.icon} size={18} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        <div className="ops-sidebar-callout">
          <Icon name={isAdmin ? "categories" : "store"} size={18} />
          <div>
            <strong>{isAdmin ? "Govern with context" : "Keep your catalog ready"}</strong>
            <p>
              {isAdmin
                ? "Control the taxonomy and merchants that power the network."
                : "Load your merchant catalog to create and maintain products."}
            </p>
          </div>
        </div>

        <div className="ops-account">
          <div className="ops-avatar" aria-hidden="true">
            {initial}
          </div>
          <div className="ops-account-copy">
            <strong>{displayName}</strong>
            <span>{roleLabel(session.user.role)}</span>
          </div>
          <button className="ops-icon-button" type="button" onClick={signOut} aria-label="Sign out">
            <Icon name="logout" size={17} />
          </button>
        </div>
      </aside>

      <div className="ops-main-column">
        <header className="ops-topbar">
          <div>
            <span className="ops-crumb">Operations</span>
            <span className="ops-crumb-divider">/</span>
            <span>{currentTitle}</span>
          </div>
          <div className="ops-topbar-status">
            <span className="ops-live-dot" />
            JWT session active
          </div>
        </header>
        <main className="ops-content">{children}</main>
      </div>
    </div>
  );
}
