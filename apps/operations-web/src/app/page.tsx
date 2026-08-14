"use client";

import { Icon } from "@/components/icon";
import { useSession } from "@/components/session-context";
import { Alert, PageHeader } from "@/components/ui";
import { api, getErrorMessage } from "@/lib/api";
import { isAdminRole } from "@/lib/roles";
import Link from "next/link";
import { useEffect, useState } from "react";

type NetworkSummary = {
  categories: number | null;
  merchants: number | null;
};

export default function OverviewPage() {
  const { session } = useSession();
  const isAdmin = isAdminRole(session?.user.role);
  const token = session?.token;
  const [loadVersion, setLoadVersion] = useState(0);
  const [summary, setSummary] = useState<NetworkSummary>({ categories: null, merchants: null });
  const [isLoading, setIsLoading] = useState(isAdmin);
  const [error, setError] = useState("");

  useEffect(() => {
    let isCurrent = true;

    if (!isAdmin) {
      return () => {
        isCurrent = false;
      };
    }

    void Promise.allSettled([api.listCategories(), api.listMerchants()]).then((results) => {
      if (!isCurrent) {
        return;
      }

      const [categoriesResult, merchantsResult] = results;
      const messages: string[] = [];
      setSummary({
        categories: categoriesResult.status === "fulfilled" ? categoriesResult.value.length : null,
        merchants: merchantsResult.status === "fulfilled" ? merchantsResult.value.length : null,
      });

      if (categoriesResult.status === "rejected") {
        messages.push(getErrorMessage(categoriesResult.reason));
      }
      if (merchantsResult.status === "rejected") {
        messages.push(getErrorMessage(merchantsResult.reason));
      }

      setError(messages.join(" "));
      setIsLoading(false);
    });

    return () => {
      isCurrent = false;
    };
  }, [isAdmin, loadVersion, token]);

  function refreshSummary() {
    setIsLoading(true);
    setError("");
    setLoadVersion((version) => version + 1);
  }

  if (isAdmin) {
    return (
      <div className="ops-page-stack">
        <PageHeader
          eyebrow="Network control"
          title="Operations overview"
          description="A live view of the structures that make your commerce network usable."
          action={
            <button
              className="ops-button ops-button-secondary"
              type="button"
              onClick={refreshSummary}
              disabled={isLoading}
            >
              <Icon name="refresh" size={16} />
              Refresh data
            </button>
          }
        />

        {error ? <Alert>{error}</Alert> : null}

        <section className="ops-metric-grid" aria-label="Network summary">
          <article className="ops-metric-card ops-metric-card-accent">
            <div className="ops-metric-icon">
              <Icon name="categories" size={20} />
            </div>
            <p>Categories</p>
            <strong>{isLoading ? "..." : summary.categories ?? "Unavailable"}</strong>
            <span>Available to organize merchant catalogs</span>
          </article>
          <article className="ops-metric-card">
            <div className="ops-metric-icon">
              <Icon name="merchants" size={20} />
            </div>
            <p>Merchants shown</p>
            <strong>{isLoading ? "..." : summary.merchants ?? "Unavailable"}</strong>
            <span>Returned by the current merchant directory page</span>
          </article>
          <article className="ops-metric-card ops-metric-card-ink">
            <div className="ops-metric-icon">
              <Icon name="catalog" size={20} />
            </div>
            <p>Catalog operations</p>
            <strong>Ready</strong>
            <span>Open any merchant catalog with its identifier</span>
          </article>
        </section>

        <section className="ops-overview-grid">
          <article className="ops-panel ops-panel-wide">
            <div className="ops-panel-heading">
              <div>
                <p className="ops-eyebrow">Control room</p>
                <h2>Keep the network structured.</h2>
              </div>
              <span className="ops-panel-marker">Admin tools</span>
            </div>
            <p className="ops-panel-copy">
              Establish the category system first, then onboard each restaurant or grocery merchant into a
              consistent operating model.
            </p>
            <div className="ops-action-grid">
              <Link className="ops-action-card" href="/categories">
                <span className="ops-action-icon">
                  <Icon name="categories" size={20} />
                </span>
                <span>
                  <strong>Manage categories</strong>
                  <small>Create the taxonomy used across catalogs.</small>
                </span>
                <Icon name="arrowRight" size={18} />
              </Link>
              <Link className="ops-action-card" href="/merchants">
                <span className="ops-action-icon">
                  <Icon name="merchants" size={20} />
                </span>
                <span>
                  <strong>Onboard merchants</strong>
                  <small>Register restaurants and grocery operators.</small>
                </span>
                <Icon name="arrowRight" size={18} />
              </Link>
            </div>
          </article>

          <aside className="ops-side-note">
            <span className="ops-side-note-label">Workflow note</span>
            <h2>Catalog work stays merchant-specific.</h2>
            <p>Use the merchant ID from the onboarding record when creating or reviewing products.</p>
            <Link className="ops-text-link" href="/catalog">
              Open catalog workspace <Icon name="arrowRight" size={16} />
            </Link>
          </aside>
        </section>
      </div>
    );
  }

  return (
    <div className="ops-page-stack">
      <PageHeader
        eyebrow="Merchant workspace"
        title="Store operations, in one place"
        description="Keep your catalog accurate and your storefront prepared for incoming orders."
      />

      <section className="ops-merchant-overview">
        <article className="ops-merchant-hero">
          <div className="ops-merchant-hero-mark">
            <Icon name="store" size={27} />
          </div>
          <div>
            <p className="ops-eyebrow">Your assigned store</p>
            <h2>{session?.user.merchantId || "Merchant ID not assigned"}</h2>
            <p>
              {session?.user.merchantId
                ? "Use this identifier in the catalog workspace to load your storefront."
                : "Enter the merchant ID supplied by your administrator. The API verifies your merchant membership."}
            </p>
          </div>
          <Link className="ops-button ops-button-primary" href="/catalog">
            Manage catalog <Icon name="arrowRight" size={17} />
          </Link>
        </article>

        <div className="ops-merchant-steps" aria-label="Merchant workflow">
          <article>
            <span>01</span>
            <h2>Load your catalog</h2>
            <p>Enter or confirm the merchant ID to retrieve the current product list.</p>
          </article>
          <article>
            <span>02</span>
            <h2>Maintain product detail</h2>
            <p>Use a category, price, SKU, stock value, and substitution policy for every new item.</p>
          </article>
          <article>
            <span>03</span>
            <h2>Prepare for orders</h2>
            <p>The orders workspace will surface order activity when an order feed is connected.</p>
          </article>
        </div>
      </section>
    </div>
  );
}
