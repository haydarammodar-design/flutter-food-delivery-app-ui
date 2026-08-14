"use client";

import { Icon } from "@/components/icon";
import { useSession } from "@/components/session-context";
import {
  AccessPanel,
  Alert,
  EmptyState,
  formatDate,
  LoadingRows,
  PageHeader,
  StatusPill,
} from "@/components/ui";
import { api, getErrorMessage, type Merchant } from "@/lib/api";
import { isAdminRole } from "@/lib/roles";
import { useEffect, useState, type FormEvent } from "react";

type MerchantForm = {
  name: string;
  type: "RESTAURANT" | "GROCERY";
  contactEmail: string;
  description: string;
  phone: string;
  streetAddress: string;
  city: string;
};

const initialForm: MerchantForm = {
  name: "",
  type: "RESTAURANT",
  contactEmail: "",
  description: "",
  phone: "",
  streetAddress: "",
  city: "",
};

export default function MerchantsPage() {
  const { session } = useSession();

  if (!isAdminRole(session?.user.role)) {
    return (
      <AccessPanel
        title="Merchant onboarding is managed by admins"
        description="Your merchant workspace is ready for catalog maintenance. Contact a network administrator to change merchant records."
      />
    );
  }

  return <MerchantsWorkspace />;
}

function MerchantsWorkspace() {
  const [merchants, setMerchants] = useState<Merchant[]>([]);
  const [form, setForm] = useState<MerchantForm>(initialForm);
  const [loadVersion, setLoadVersion] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [removingMerchantId, setRemovingMerchantId] = useState("");
  const [loadError, setLoadError] = useState("");
  const [formError, setFormError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    let isCurrent = true;

    void api
      .listMerchants()
      .then((items) => {
        if (isCurrent) {
          setMerchants(items);
        }
      })
      .catch((error: unknown) => {
        if (isCurrent) {
          setLoadError(getErrorMessage(error));
        }
      })
      .finally(() => {
        if (isCurrent) {
          setIsLoading(false);
        }
      });

    return () => {
      isCurrent = false;
    };
  }, [loadVersion]);

  function reloadMerchants() {
    setIsLoading(true);
    setLoadError("");
    setLoadVersion((version) => version + 1);
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setFormError("");
    setSuccess("");

    if (!form.name.trim() || !form.contactEmail.trim()) {
      setFormError("A merchant name and contact email are required.");
      return;
    }

    setIsSubmitting(true);
    try {
      await api.createMerchant({
        name: form.name.trim(),
        type: form.type,
        contactEmail: form.contactEmail.trim(),
        description: form.description.trim() || undefined,
        phone: form.phone.trim() || undefined,
        streetAddress: form.streetAddress.trim() || undefined,
        city: form.city.trim() || undefined,
      });
      setForm(initialForm);
      setSuccess("Merchant created. The merchant list has been refreshed.");
      reloadMerchants();
    } catch (error) {
      setFormError(getErrorMessage(error));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleMerchantRemove(merchant: Merchant) {
    if (!merchant.id || merchant.status === "INACTIVE") {
      return;
    }
    if (
      !window.confirm(
        `Remove ${merchant.name} from customer discovery? Existing catalog and order history will be preserved.`,
      )
    ) {
      return;
    }

    setRemovingMerchantId(merchant.id);
    setLoadError("");
    setSuccess("");
    try {
      await api.removeMerchant(merchant.id);
      setSuccess(`${merchant.name} removed from customer discovery.`);
      reloadMerchants();
    } catch (error) {
      setLoadError(getErrorMessage(error));
    } finally {
      setRemovingMerchantId("");
    }
  }

  return (
    <div className="ops-page-stack">
      <PageHeader
        eyebrow="Merchant network"
        title="Merchants"
        description="Onboard restaurant and grocery operators, then use their ID to manage a catalog."
        action={
          <button
            className="ops-button ops-button-secondary"
            type="button"
            onClick={reloadMerchants}
            disabled={isLoading}
          >
            <Icon name="refresh" size={16} />
            Refresh
          </button>
        }
      />

      {loadError ? <Alert>{loadError}</Alert> : null}
      {success ? <Alert tone="success">{success}</Alert> : null}

      <div className="ops-workspace-grid">
        <section className="ops-panel ops-table-panel">
          <div className="ops-panel-heading ops-panel-heading-tight">
            <div>
              <p className="ops-eyebrow">Merchant directory</p>
              <h2>Registered operators</h2>
            </div>
            {!isLoading ? <span className="ops-count-label">{merchants.length} shown</span> : null}
          </div>

          <div className="ops-table-wrap">
            <table className="ops-table ops-merchant-table">
              <thead>
                <tr>
                  <th>Merchant</th>
                  <th>Type</th>
                  <th>Contact</th>
                  <th>Status</th>
                  <th>Created</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? <LoadingRows columns={6} /> : null}
                {!isLoading && !loadError && merchants.length === 0 ? (
                  <tr>
                    <td colSpan={6}>
                      <EmptyState
                        title="No merchants registered"
                        description="Create a restaurant or grocery merchant to begin its catalog setup."
                      />
                    </td>
                  </tr>
                ) : null}
                {!isLoading
                  ? merchants.map((merchant, index) => (
                      <tr key={merchant.id || `${merchant.name}-${index}`}>
                        <td>
                          <strong>{merchant.name || "Name unavailable"}</strong>
                          {merchant.id ? <span className="ops-table-id">{merchant.id}</span> : null}
                          {merchant.address ? <span className="ops-table-subtext">{merchant.address}</span> : null}
                        </td>
                        <td>
                          <span className="ops-type-label">
                            {merchant.type.replace(/_/g, " ").toLowerCase()}
                          </span>
                        </td>
                        <td>
                          {merchant.contactEmail || merchant.phone ? (
                            <>
                              <strong>{merchant.contactEmail || "Contact unavailable"}</strong>
                              {merchant.phone ? <span className="ops-table-subtext">{merchant.phone}</span> : null}
                            </>
                          ) : (
                            "Not available"
                          )}
                        </td>
                        <td>
                          <StatusPill status={merchant.status} />
                        </td>
                        <td>{formatDate(merchant.createdAt)}</td>
                        <td>
                          <button
                            className="ops-button ops-button-danger ops-button-compact"
                            type="button"
                            onClick={() => handleMerchantRemove(merchant)}
                            disabled={
                              merchant.status === "INACTIVE" || removingMerchantId === merchant.id
                            }
                          >
                            {removingMerchantId === merchant.id ? "Removing..." : "Remove merchant"}
                          </button>
                        </td>
                      </tr>
                    ))
                  : null}
              </tbody>
            </table>
          </div>
        </section>

        <aside className="ops-panel ops-form-panel">
          <div className="ops-panel-heading ops-panel-heading-tight">
            <div>
              <p className="ops-eyebrow">Add merchant</p>
              <h2>Start an onboarding record</h2>
            </div>
          </div>
          <p className="ops-panel-copy">The API will create the merchant identifier used by the catalog workspace.</p>

          <form className="ops-form" onSubmit={handleSubmit}>
            {formError ? <Alert>{formError}</Alert> : null}
            <label>
              Merchant name
              <input
                value={form.name}
                onChange={(event) => setForm({ ...form, name: event.target.value })}
                placeholder="Storefront name"
                required
              />
            </label>
            <label>
              Merchant type
              <select
                value={form.type}
                onChange={(event) => setForm({ ...form, type: event.target.value as MerchantForm["type"] })}
              >
                <option value="RESTAURANT">Restaurant</option>
                <option value="GROCERY">Grocery</option>
              </select>
            </label>
            <label>
              Contact email
              <input
                type="email"
                value={form.contactEmail}
                onChange={(event) => setForm({ ...form, contactEmail: event.target.value })}
                placeholder="contact@store.com"
                required
              />
            </label>
            <label>
              Description <span className="ops-optional">Optional</span>
              <textarea
                value={form.description}
                onChange={(event) => setForm({ ...form, description: event.target.value })}
                placeholder="A short description for discovery"
                rows={3}
              />
            </label>
            <div className="ops-form-row">
              <label>
                Phone <span className="ops-optional">Optional</span>
                <input
                  value={form.phone}
                  onChange={(event) => setForm({ ...form, phone: event.target.value })}
                  placeholder="Store phone number"
                />
              </label>
              <label>
                Street address <span className="ops-optional">Optional</span>
                <input
                  value={form.streetAddress}
                  onChange={(event) => setForm({ ...form, streetAddress: event.target.value })}
                  placeholder="Street and unit"
                />
              </label>
            </div>
            <label>
              City <span className="ops-optional">Optional</span>
              <input
                value={form.city}
                onChange={(event) => setForm({ ...form, city: event.target.value })}
                placeholder="City"
              />
            </label>
            <button className="ops-button ops-button-primary ops-button-full" type="submit" disabled={isSubmitting}>
              <Icon name="plus" size={17} />
              {isSubmitting ? "Creating merchant..." : "Create merchant"}
            </button>
          </form>
        </aside>
      </div>
    </div>
  );
}
