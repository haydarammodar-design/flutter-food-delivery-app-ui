"use client";

import { Icon } from "@/components/icon";
import { useSession } from "@/components/session-context";
import { PageHeader } from "@/components/ui";
import { isAdminRole } from "@/lib/roles";
import Link from "next/link";

export default function OrdersPage() {
  const { session } = useSession();
  const isAdmin = isAdminRole(session?.user.role);

  return (
    <div className="ops-page-stack">
      <PageHeader
        eyebrow={isAdmin ? "Network activity" : "Store fulfillment"}
        title="Orders"
        description={
          isAdmin
            ? "A dedicated space for network-wide order visibility when the order feed is connected."
            : "A dedicated space for incoming order work when the merchant order feed is connected."
        }
      />

      <section className="ops-orders-empty">
        <div className="ops-orders-empty-icon">
          <Icon name="orders" size={28} />
        </div>
        <p className="ops-eyebrow">Order feed pending</p>
        <h2>No order records are loaded here.</h2>
        <p>
          This console does not invent operational data. Connect the NestJS order endpoint to surface live
          order activity, fulfillment states, and exceptions in this workspace.
        </p>
        <div className="ops-orders-empty-actions">
          <Link className="ops-button ops-button-secondary" href="/catalog">
            <Icon name="catalog" size={17} />
            {isAdmin ? "Review catalogs" : "Maintain catalog"}
          </Link>
          {isAdmin ? (
            <Link className="ops-button ops-button-primary" href="/merchants">
              <Icon name="merchants" size={17} />
              Review merchants
            </Link>
          ) : null}
        </div>
      </section>
    </div>
  );
}
