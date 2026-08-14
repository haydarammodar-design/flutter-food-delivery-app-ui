"use client";

/* eslint-disable @next/next/no-img-element -- Product images may come from locally uploaded or arbitrary external URLs. */

import { Icon } from "@/components/icon";
import {
  Alert,
  EmptyState,
  formatNumber,
  LoadingRows,
  PageHeader,
  StatusPill,
} from "@/components/ui";
import {
  api,
  getErrorMessage,
  type CatalogProduct,
  type Category,
  type Merchant,
} from "@/lib/api";
import { useEffect, useState, type ChangeEvent, type FormEvent } from "react";

type ProductForm = {
  name: string;
  description: string;
  imageUrl: string;
  price: string;
  sku: string;
  stock: string;
  substitutionAllowed: boolean;
  categoryId: string;
  publish: boolean;
};

const initialProductForm: ProductForm = {
  name: "",
  description: "",
  imageUrl: "",
  price: "",
  sku: "",
  stock: "",
  substitutionAllowed: false,
  categoryId: "",
  publish: true,
};

export default function CatalogPage() {
  const [merchantId, setMerchantId] = useState("");
  const [activeMerchantId, setActiveMerchantId] = useState("");
  const [merchants, setMerchants] = useState<Merchant[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<CatalogProduct[]>([]);
  const [imageDrafts, setImageDrafts] = useState<Record<string, string>>({});
  const [productForm, setProductForm] = useState<ProductForm>(initialProductForm);
  const [categoryLoadVersion, setCategoryLoadVersion] = useState(0);
  const [merchantLoadVersion, setMerchantLoadVersion] = useState(0);
  const [isLoadingCategories, setIsLoadingCategories] = useState(true);
  const [isLoadingMerchants, setIsLoadingMerchants] = useState(true);
  const [isLoadingProducts, setIsLoadingProducts] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [publishingProductId, setPublishingProductId] = useState("");
  const [uploadingProductImageTarget, setUploadingProductImageTarget] = useState("");
  const [savingProductImageId, setSavingProductImageId] = useState("");
  const [clearingProductImageId, setClearingProductImageId] = useState("");
  const [deletingProductId, setDeletingProductId] = useState("");
  const [categoryError, setCategoryError] = useState("");
  const [merchantError, setMerchantError] = useState("");
  const [productError, setProductError] = useState("");
  const [formError, setFormError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    let isCurrent = true;

    void api
      .listCatalogCategories()
      .then((items) => {
        if (isCurrent) {
          setCategories(items);
        }
      })
      .catch((error: unknown) => {
        if (isCurrent) {
          setCategoryError(getErrorMessage(error));
        }
      })
      .finally(() => {
        if (isCurrent) {
          setIsLoadingCategories(false);
        }
      });

    return () => {
      isCurrent = false;
    };
  }, [categoryLoadVersion]);

  useEffect(() => {
    let isCurrent = true;

    void api
      .listManageableMerchants()
      .then((items) => {
        if (isCurrent) {
          setMerchants(items);
        }
      })
      .catch((error: unknown) => {
        if (isCurrent) {
          setMerchantError(getErrorMessage(error));
        }
      })
      .finally(() => {
        if (isCurrent) {
          setIsLoadingMerchants(false);
        }
      });

    return () => {
      isCurrent = false;
    };
  }, [merchantLoadVersion]);

  function reloadCategories() {
    setIsLoadingCategories(true);
    setCategoryError("");
    setCategoryLoadVersion((version) => version + 1);
  }

  function reloadMerchants() {
    setIsLoadingMerchants(true);
    setMerchantError("");
    setMerchantLoadVersion((version) => version + 1);
  }

  async function fetchProducts(id: string, preserveSuccess = false) {
    setIsLoadingProducts(true);
    setProductError("");
    if (!preserveSuccess) {
      setSuccess("");
    }

    try {
      const items = await api.listMerchantProducts(id);
      setProducts(items);
      setImageDrafts(
        Object.fromEntries(items.map((product) => [product.id, product.imageUrl ?? ""])),
      );
      setActiveMerchantId(id);
    } catch (error) {
      setProductError(getErrorMessage(error));
      setProducts([]);
      setActiveMerchantId("");
    } finally {
      setIsLoadingProducts(false);
    }
  }

  async function handleCatalogLoad(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const normalizedMerchantId = merchantId.trim();
    if (!normalizedMerchantId) {
      setProductError("Select a merchant to load its catalog.");
      return;
    }

    await fetchProducts(normalizedMerchantId);
  }

  async function handleProductSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setFormError("");
    setSuccess("");

    if (!activeMerchantId) {
      setFormError("Load a merchant catalog before creating a product.");
      return;
    }

    const price = Number(productForm.price);
    const stock = Number(productForm.stock);
    if (!productForm.name.trim() || !productForm.sku.trim() || !productForm.categoryId) {
      setFormError("Name, SKU, and category are required.");
      return;
    }
    if (!Number.isFinite(price) || price < 0) {
      setFormError("Enter a valid non-negative price.");
      return;
    }
    if (!Number.isInteger(stock) || stock < 0) {
      setFormError("Stock must be a non-negative whole number.");
      return;
    }

    setIsSubmitting(true);
    try {
      await api.createMerchantProduct(activeMerchantId, {
        name: productForm.name.trim(),
        description: productForm.description.trim() || undefined,
        imageUrl: productForm.imageUrl.trim() || undefined,
        price,
        sku: productForm.sku.trim(),
        inventoryQuantity: stock,
        allowSubstitutions: productForm.substitutionAllowed,
        categoryId: productForm.categoryId,
        isPublished: productForm.publish,
      });
      setProductForm(initialProductForm);
      setSuccess(
        productForm.publish
          ? "Product created and published to the customer app."
          : "Product created as a draft. Publish it when it is ready for customers.",
      );
      await fetchProducts(activeMerchantId, true);
    } catch (error) {
      setFormError(getErrorMessage(error));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handlePublicationChange(product: CatalogProduct) {
    if (!activeMerchantId || !product.id) {
      return;
    }

    const published = !product.isPublished;
    setPublishingProductId(product.id);
    setProductError("");
    setSuccess("");

    try {
      await api.updateMerchantProductPublication(activeMerchantId, product.id, published);
      setSuccess(`${product.name} has been ${published ? "published" : "unpublished"}.`);
      await fetchProducts(activeMerchantId, true);
    } catch (error) {
      setProductError(getErrorMessage(error));
    } finally {
      setPublishingProductId("");
    }
  }

  async function uploadProductImage(file: File): Promise<string> {
    if (!activeMerchantId) {
      throw new Error("Load a merchant catalog before uploading a product photo.");
    }

    return api.uploadMerchantImage(activeMerchantId, file);
  }

  async function handleNewProductPhotoChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) {
      return;
    }

    setUploadingProductImageTarget("new");
    setFormError("");
    try {
      const imageUrl = await uploadProductImage(file);
      setProductForm((current) => ({ ...current, imageUrl }));
      setSuccess("Product photo uploaded. Create the product to attach it to the catalog.");
    } catch (error) {
      setFormError(getErrorMessage(error));
    } finally {
      setUploadingProductImageTarget("");
    }
  }

  async function handleExistingProductPhotoChange(
    product: CatalogProduct,
    event: ChangeEvent<HTMLInputElement>,
  ) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file || !activeMerchantId || !product.id) {
      return;
    }

    setUploadingProductImageTarget(product.id);
    setProductError("");
    setSuccess("");
    try {
      const imageUrl = await uploadProductImage(file);
      await api.updateMerchantProductImage(activeMerchantId, product.id, imageUrl);
      setSuccess(`${product.name} photo updated.`);
      await fetchProducts(activeMerchantId, true);
    } catch (error) {
      setProductError(getErrorMessage(error));
    } finally {
      setUploadingProductImageTarget("");
    }
  }

  async function handleExistingProductImageSave(product: CatalogProduct) {
    const imageUrl = imageDrafts[product.id]?.trim();
    if (!activeMerchantId || !product.id || !imageUrl) {
      setProductError("Enter a full image URL before saving the product photo.");
      return;
    }

    setSavingProductImageId(product.id);
    setProductError("");
    setSuccess("");
    try {
      await api.updateMerchantProductImage(activeMerchantId, product.id, imageUrl);
      setSuccess(`${product.name} photo updated.`);
      await fetchProducts(activeMerchantId, true);
    } catch (error) {
      setProductError(getErrorMessage(error));
    } finally {
      setSavingProductImageId("");
    }
  }

  async function handleExistingProductImageClear(product: CatalogProduct) {
    if (!activeMerchantId || !product.id || !product.imageUrl) {
      return;
    }

    setClearingProductImageId(product.id);
    setProductError("");
    setSuccess("");
    try {
      await api.clearMerchantProductImage(activeMerchantId, product.id);
      setSuccess(`${product.name} photo removed.`);
      await fetchProducts(activeMerchantId, true);
    } catch (error) {
      setProductError(getErrorMessage(error));
    } finally {
      setClearingProductImageId("");
    }
  }

  async function handleProductDelete(product: CatalogProduct) {
    if (!activeMerchantId || !product.id) {
      return;
    }
    if (!window.confirm(`Remove ${product.name} from this catalog? This cannot be undone from the dashboard.`)) {
      return;
    }

    setDeletingProductId(product.id);
    setProductError("");
    setSuccess("");
    try {
      await api.deleteMerchantProduct(activeMerchantId, product.id);
      setSuccess(`${product.name} removed from the catalog.`);
      await fetchProducts(activeMerchantId, true);
    } catch (error) {
      setProductError(getErrorMessage(error));
    } finally {
      setDeletingProductId("");
    }
  }

  function handleMerchantChange(id: string) {
    setMerchantId(id);
    if (id !== activeMerchantId) {
      setActiveMerchantId("");
      setProducts([]);
      setImageDrafts({});
      setProductError("");
      setSuccess("");
    }
  }

  return (
    <div className="ops-page-stack">
      <PageHeader
        eyebrow="Merchant catalog"
        title="Catalog workspace"
        description="Select a storefront, then create and publish dishes or grocery items for its catalog."
      />

      {success ? <Alert tone="success">{success}</Alert> : null}

      <section className="ops-catalog-picker">
        <div>
          <p className="ops-eyebrow">Catalog selector</p>
          <h2>Which merchant are you working on?</h2>
          <p>Select a restaurant or grocery storefront you are allowed to manage.</p>
        </div>
        <form className="ops-catalog-picker-form" onSubmit={handleCatalogLoad}>
          <label>
            Merchant
            <select
              value={merchantId}
              onChange={(event) => handleMerchantChange(event.target.value)}
              disabled={isLoadingMerchants || merchants.length === 0}
              aria-label="Merchant"
            >
              <option value="">
                {isLoadingMerchants
                  ? "Loading merchants..."
                  : merchants.length === 0
                    ? "No manageable merchants"
                    : "Select a merchant"}
              </option>
              {merchants.map((merchant) => (
                <option key={merchant.id} value={merchant.id}>
                  {merchant.name} ({merchant.type.toLowerCase()})
                </option>
              ))}
            </select>
          </label>
          <button
            className="ops-button ops-button-primary"
            type="submit"
            disabled={isLoadingProducts || isLoadingMerchants || !merchantId}
          >
            {isLoadingProducts ? "Loading..." : "Load catalog"}
            {!isLoadingProducts ? <Icon name="arrowRight" size={17} /> : null}
          </button>
        </form>
      </section>

      {merchantError ? (
        <Alert>
          Could not load your manageable merchants. {merchantError}
          <button className="ops-alert-action" type="button" onClick={reloadMerchants}>
            Try again
          </button>
        </Alert>
      ) : null}
      {productError ? <Alert>{productError}</Alert> : null}

      <div className="ops-catalog-grid">
        <aside className="ops-panel ops-form-panel ops-catalog-form-panel">
          <div className="ops-panel-heading ops-panel-heading-tight">
            <div>
              <p className="ops-eyebrow">Add product</p>
              <h2>Catalog detail</h2>
            </div>
            {activeMerchantId ? <span className="ops-active-id">{activeMerchantId}</span> : null}
          </div>
          <p className="ops-panel-copy">
            {activeMerchantId
              ? "This product will be created in the loaded merchant catalog."
              : "Load a merchant catalog to activate the product form."}
          </p>

          {categoryError ? (
            <Alert>
              Could not load categories for this product. {categoryError}
              <button
                className="ops-alert-action"
                type="button"
                onClick={reloadCategories}
              >
                Try again
              </button>
            </Alert>
          ) : null}

          <form className="ops-form" onSubmit={handleProductSubmit}>
            {formError ? <Alert>{formError}</Alert> : null}
            <label>
              Product name
              <input
                value={productForm.name}
                onChange={(event) => setProductForm({ ...productForm, name: event.target.value })}
                placeholder="Product name"
                disabled={!activeMerchantId}
                required
              />
            </label>
            <label>
              Description <span className="ops-optional">Optional</span>
              <textarea
                value={productForm.description}
                onChange={(event) => setProductForm({ ...productForm, description: event.target.value })}
                placeholder="Helpful item detail"
                rows={3}
                disabled={!activeMerchantId}
              />
            </label>
            <label>
              Upload product photo <span className="ops-optional">Optional</span>
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp,image/gif"
                onChange={handleNewProductPhotoChange}
                disabled={!activeMerchantId || uploadingProductImageTarget === "new"}
              />
              <small className="ops-input-help">
                {uploadingProductImageTarget === "new"
                  ? "Uploading photo..."
                  : "JPEG, PNG, WebP, or GIF up to 5 MB."}
              </small>
            </label>
            <label>
              Product photo URL <span className="ops-optional">Optional</span>
              <input
                type="url"
                value={productForm.imageUrl}
                onChange={(event) => setProductForm({ ...productForm, imageUrl: event.target.value })}
                placeholder="https://example.com/product-photo.jpg"
                disabled={!activeMerchantId}
              />
            </label>
            {productForm.imageUrl ? (
              <img className="ops-product-image-preview" src={productForm.imageUrl} alt="Product preview" />
            ) : null}
            <div className="ops-form-row">
              <label>
                Price
                <input
                  type="number"
                  inputMode="decimal"
                  min="0"
                  step="0.01"
                  value={productForm.price}
                  onChange={(event) => setProductForm({ ...productForm, price: event.target.value })}
                  placeholder="0.00"
                  disabled={!activeMerchantId}
                  required
                />
              </label>
              <label>
                Stock
                <input
                  type="number"
                  inputMode="numeric"
                  min="0"
                  step="1"
                  value={productForm.stock}
                  onChange={(event) => setProductForm({ ...productForm, stock: event.target.value })}
                  placeholder="0"
                  disabled={!activeMerchantId}
                  required
                />
              </label>
            </div>
            <label>
              SKU
              <input
                value={productForm.sku}
                onChange={(event) => setProductForm({ ...productForm, sku: event.target.value })}
                placeholder="Unique product code"
                disabled={!activeMerchantId}
                required
              />
            </label>
            <label>
              Category
              <select
                value={productForm.categoryId}
                onChange={(event) => setProductForm({ ...productForm, categoryId: event.target.value })}
                disabled={!activeMerchantId || isLoadingCategories || categories.length === 0}
                required
              >
                <option value="">
                  {isLoadingCategories ? "Loading categories..." : "Select a category"}
                </option>
                {categories.map((category, index) => (
                  <option key={category.id || `${category.name}-${index}`} value={category.id}>
                    {category.name || "Name unavailable"}
                  </option>
                ))}
              </select>
            </label>
            <label className="ops-checkbox-label">
              <input
                type="checkbox"
                checked={productForm.substitutionAllowed}
                onChange={(event) =>
                  setProductForm({ ...productForm, substitutionAllowed: event.target.checked })
                }
                disabled={!activeMerchantId}
              />
              <span>
                <strong>Substitution allowed</strong>
                <small>Allow a replacement when this product is unavailable.</small>
              </span>
            </label>
            <label className="ops-checkbox-label">
              <input
                type="checkbox"
                checked={productForm.publish}
                onChange={(event) => setProductForm({ ...productForm, publish: event.target.checked })}
                disabled={!activeMerchantId}
              />
              <span>
                <strong>Publish to customers</strong>
                <small>Published items are available in the customer app.</small>
              </span>
            </label>
            <button
              className="ops-button ops-button-primary ops-button-full"
              type="submit"
              disabled={
                isSubmitting ||
                uploadingProductImageTarget === "new" ||
                !activeMerchantId ||
                isLoadingCategories ||
                categories.length === 0
              }
            >
              <Icon name="plus" size={17} />
              {isSubmitting ? "Creating product..." : "Create product"}
            </button>
          </form>
        </aside>

        <section className="ops-panel ops-table-panel">
          <div className="ops-panel-heading ops-panel-heading-tight">
            <div>
              <p className="ops-eyebrow">Loaded catalog</p>
              <h2>{activeMerchantId ? "Products" : "Product list"}</h2>
            </div>
            {activeMerchantId && !isLoadingProducts ? (
              <span className="ops-count-label">{products.length} items</span>
            ) : null}
          </div>

          <div className="ops-table-wrap">
            <table className="ops-table ops-product-table">
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Photo</th>
                  <th>Category</th>
                  <th>Price</th>
                  <th>Stock</th>
                  <th>Substitution</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {isLoadingProducts ? <LoadingRows columns={7} /> : null}
                {!isLoadingProducts && !activeMerchantId && !productError ? (
                  <tr>
                    <td colSpan={7}>
                      <EmptyState
                        title="Choose a merchant catalog"
                        description="Select a merchant above to retrieve the products attached to that storefront."
                      />
                    </td>
                  </tr>
                ) : null}
                {!isLoadingProducts && activeMerchantId && !productError && products.length === 0 ? (
                  <tr>
                    <td colSpan={7}>
                      <EmptyState
                        title="This catalog has no products"
                        description="Use the form to add the first product for this merchant."
                      />
                    </td>
                  </tr>
                ) : null}
                {!isLoadingProducts
                  ? products.map((product, index) => (
                      <tr key={product.id || `${product.sku || product.name}-${index}`}>
                        <td>
                          <strong>{product.name || "Name unavailable"}</strong>
                          {product.sku ? <span className="ops-table-id">SKU {product.sku}</span> : null}
                          {product.description ? (
                            <span className="ops-table-subtext">{product.description}</span>
                          ) : null}
                        </td>
                        <td>
                          <div className="ops-product-photo-editor">
                            {product.imageUrl ? (
                              <img
                                className="ops-product-photo-thumbnail"
                                src={product.imageUrl}
                                alt={`${product.name} product photo`}
                              />
                            ) : (
                              <span className="ops-product-photo-empty">No photo</span>
                            )}
                            <input
                              type="url"
                              value={imageDrafts[product.id] ?? ""}
                              onChange={(event) =>
                                setImageDrafts((current) => ({
                                  ...current,
                                  [product.id]: event.target.value,
                                }))
                              }
                              placeholder="Paste image URL"
                              aria-label={`Photo URL for ${product.name}`}
                              disabled={
                                uploadingProductImageTarget === product.id ||
                                savingProductImageId === product.id ||
                                clearingProductImageId === product.id ||
                                deletingProductId === product.id
                              }
                            />
                            <div className="ops-product-photo-actions">
                              <label className="ops-photo-upload-button">
                                <input
                                  type="file"
                                  accept="image/jpeg,image/png,image/webp,image/gif"
                                  onChange={(event) => void handleExistingProductPhotoChange(product, event)}
                                  disabled={
                                    uploadingProductImageTarget === product.id ||
                                    savingProductImageId === product.id ||
                                    clearingProductImageId === product.id ||
                                    deletingProductId === product.id
                                  }
                                  aria-label={`Upload a photo for ${product.name}`}
                                />
                                {uploadingProductImageTarget === product.id ? "Uploading..." : "Upload"}
                              </label>
                              <button
                                className="ops-button ops-button-secondary ops-button-compact"
                                type="button"
                                onClick={() => handleExistingProductImageSave(product)}
                                disabled={
                                  !imageDrafts[product.id]?.trim() ||
                                  uploadingProductImageTarget === product.id ||
                                  savingProductImageId === product.id ||
                                  clearingProductImageId === product.id ||
                                  deletingProductId === product.id
                                }
                              >
                                {savingProductImageId === product.id ? "Saving..." : "Save URL"}
                              </button>
                              <button
                                className="ops-button ops-button-danger ops-button-compact"
                                type="button"
                                onClick={() => handleExistingProductImageClear(product)}
                                disabled={
                                  !product.imageUrl ||
                                  uploadingProductImageTarget === product.id ||
                                  savingProductImageId === product.id ||
                                  clearingProductImageId === product.id ||
                                  deletingProductId === product.id
                                }
                              >
                                {clearingProductImageId === product.id ? "Removing..." : "Remove"}
                              </button>
                            </div>
                          </div>
                        </td>
                        <td>{product.categoryName || product.categoryId || "Not available"}</td>
                        <td>{formatNumber(product.price)}</td>
                        <td>{formatNumber(product.stock)}</td>
                        <td>
                          <span className={`ops-boolean ${product.substitutionAllowed ? "ops-boolean-yes" : ""}`}>
                            {product.substitutionAllowed ? "Allowed" : "Not allowed"}
                          </span>
                        </td>
                        <td>
                          <div className="ops-publication-control">
                            <StatusPill status={product.status} />
                            <button
                              className="ops-button ops-button-secondary ops-button-compact"
                              type="button"
                              onClick={() => handlePublicationChange(product)}
                              disabled={
                                publishingProductId === product.id || deletingProductId === product.id
                              }
                            >
                              {product.isPublished ? "Unpublish" : "Publish"}
                            </button>
                            <button
                              className="ops-button ops-button-danger ops-button-compact"
                              type="button"
                              onClick={() => handleProductDelete(product)}
                              disabled={deletingProductId === product.id}
                            >
                              {deletingProductId === product.id ? "Removing..." : "Delete product"}
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  : null}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </div>
  );
}
