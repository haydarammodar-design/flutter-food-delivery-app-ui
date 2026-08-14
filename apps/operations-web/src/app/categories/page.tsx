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
import { api, getErrorMessage, type Category } from "@/lib/api";
import { isAdminRole } from "@/lib/roles";
import { useEffect, useState, type FormEvent } from "react";

type CategoryForm = {
  name: string;
  description: string;
  status: "ACTIVE" | "INACTIVE";
};

const initialForm: CategoryForm = {
  name: "",
  description: "",
  status: "ACTIVE",
};

export default function CategoriesPage() {
  const { session } = useSession();

  if (!isAdminRole(session?.user.role)) {
    return (
      <AccessPanel
        title="Category governance is managed by admins"
        description="Your merchant account can use the shared category structure while cataloging products, but only network administrators can change it."
      />
    );
  }

  return <CategoriesWorkspace />;
}

function CategoriesWorkspace() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [form, setForm] = useState<CategoryForm>(initialForm);
  const [loadVersion, setLoadVersion] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [loadError, setLoadError] = useState("");
  const [formError, setFormError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    let isCurrent = true;

    void api
      .listCategories()
      .then((items) => {
        if (isCurrent) {
          setCategories(items);
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

  function reloadCategories() {
    setIsLoading(true);
    setLoadError("");
    setLoadVersion((version) => version + 1);
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setFormError("");
    setSuccess("");

    if (!form.name.trim()) {
      setFormError("A category name is required.");
      return;
    }

    setIsSubmitting(true);
    try {
      await api.createCategory({
        name: form.name.trim(),
        description: form.description.trim() || undefined,
        isActive: form.status === "ACTIVE",
      });
      setForm(initialForm);
      setSuccess("Category created. The list has been refreshed.");
      reloadCategories();
    } catch (error) {
      setFormError(getErrorMessage(error));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="ops-page-stack">
      <PageHeader
        eyebrow="Network taxonomy"
        title="Categories"
        description="Define the shared structure merchants use when they add products to their catalogs."
        action={
          <button
            className="ops-button ops-button-secondary"
            type="button"
            onClick={reloadCategories}
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
              <p className="ops-eyebrow">Current structure</p>
              <h2>Category list</h2>
            </div>
            {!isLoading ? <span className="ops-count-label">{categories.length} total</span> : null}
          </div>

          <div className="ops-table-wrap">
            <table className="ops-table">
              <thead>
                <tr>
                  <th>Category</th>
                  <th>Description</th>
                  <th>Status</th>
                  <th>Created</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? <LoadingRows columns={4} /> : null}
                {!isLoading && !loadError && categories.length === 0 ? (
                  <tr>
                    <td colSpan={4}>
                      <EmptyState
                        title="No categories yet"
                        description="Create the first category to give merchants a consistent place for new products."
                      />
                    </td>
                  </tr>
                ) : null}
                {!isLoading
                  ? categories.map((category, index) => (
                      <tr key={category.id || `${category.name}-${index}`}>
                        <td>
                          <strong>{category.name || "Name unavailable"}</strong>
                          {category.id ? <span className="ops-table-id">{category.id}</span> : null}
                        </td>
                        <td className="ops-table-description">{category.description || "No description"}</td>
                        <td>
                          <StatusPill status={category.status} />
                        </td>
                        <td>{formatDate(category.createdAt)}</td>
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
              <p className="ops-eyebrow">Create category</p>
              <h2>Add to the structure</h2>
            </div>
          </div>
          <p className="ops-panel-copy">Use a clear, reusable name that can work across merchant catalogs.</p>

          <form className="ops-form" onSubmit={handleSubmit}>
            {formError ? <Alert>{formError}</Alert> : null}
            <label>
              Category name
              <input
                value={form.name}
                onChange={(event) => setForm({ ...form, name: event.target.value })}
                placeholder="e.g. Pantry essentials"
                required
              />
            </label>
            <label>
              Description <span className="ops-optional">Optional</span>
              <textarea
                value={form.description}
                onChange={(event) => setForm({ ...form, description: event.target.value })}
                placeholder="How this category should be used"
                rows={4}
              />
            </label>
            <label>
              Initial status
              <select
                value={form.status}
                onChange={(event) =>
                  setForm({ ...form, status: event.target.value as CategoryForm["status"] })
                }
              >
                <option value="ACTIVE">Active</option>
                <option value="INACTIVE">Inactive</option>
              </select>
            </label>
            <button className="ops-button ops-button-primary ops-button-full" type="submit" disabled={isSubmitting}>
              <Icon name="plus" size={17} />
              {isSubmitting ? "Creating category..." : "Create category"}
            </button>
          </form>
        </aside>
      </div>
    </div>
  );
}
