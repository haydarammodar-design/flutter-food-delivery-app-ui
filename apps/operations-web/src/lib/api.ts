export type UserRole = string;

export interface AuthUser {
  id?: string;
  email?: string;
  name?: string;
  role: UserRole;
  merchantId?: string;
}

export interface AuthSession {
  token: string;
  user: AuthUser;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface Category {
  id: string;
  name: string;
  description?: string;
  status: string;
  createdAt?: string;
}

export interface Merchant {
  id: string;
  name: string;
  type: string;
  description?: string;
  address?: string;
  contactEmail?: string;
  phone?: string;
  status: string;
  createdAt?: string;
}

export interface CatalogProduct {
  id: string;
  name: string;
  description?: string;
  imageUrl?: string;
  price?: number;
  sku?: string;
  stock?: number;
  substitutionAllowed?: boolean;
  categoryId?: string;
  categoryName?: string;
  isPublished?: boolean;
  status: string;
}

export interface CreateCategoryInput {
  name: string;
  description?: string;
  isActive: boolean;
}

export interface CreateMerchantInput {
  name: string;
  type: "RESTAURANT" | "GROCERY";
  contactEmail: string;
  description?: string;
  phone?: string;
  streetAddress?: string;
  city?: string;
}

export interface CreateProductInput {
  name: string;
  description?: string;
  imageUrl?: string;
  price: number;
  sku: string;
  inventoryQuantity: number;
  allowSubstitutions: boolean;
  categoryId: string;
  isPublished: boolean;
}

type JsonRecord = Record<string, unknown>;

type ApiRequestOptions = {
  method?: string;
  body?: unknown;
  headers?: HeadersInit;
  auth?: boolean;
  signal?: AbortSignal;
};

const sessionStorageKey = "operations-web.session.v1";
const fallbackApiUrl = "http://localhost:3000";
const configuredApiUrl = process.env.NEXT_PUBLIC_API_URL?.trim();

export const apiBaseUrl = (configuredApiUrl || fallbackApiUrl).replace(/\/+$/, "");

export class ApiError extends Error {
  readonly status: number;
  readonly payload: unknown;

  constructor(message: string, status = 0, payload: unknown = null) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.payload = payload;
  }
}

function asRecord(value: unknown): JsonRecord | null {
  if (typeof value === "object" && value !== null && !Array.isArray(value)) {
    return value as JsonRecord;
  }

  return null;
}

function stringFrom(record: JsonRecord | null, keys: string[]): string {
  if (!record) {
    return "";
  }

  for (const key of keys) {
    const value = record[key];
    if (typeof value === "string" || typeof value === "number") {
      return String(value);
    }
  }

  return "";
}

function numberFrom(record: JsonRecord | null, keys: string[]): number | undefined {
  if (!record) {
    return undefined;
  }

  for (const key of keys) {
    const value = record[key];
    if (typeof value !== "number" && typeof value !== "string") {
      continue;
    }
    const parsed = typeof value === "number" ? value : Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return undefined;
}

function booleanFrom(record: JsonRecord | null, keys: string[]): boolean | undefined {
  if (!record) {
    return undefined;
  }

  for (const key of keys) {
    const value = record[key];
    if (typeof value === "boolean") {
      return value;
    }
  }

  return undefined;
}

function unwrapData(payload: unknown): unknown {
  const record = asRecord(payload);
  return record && "data" in record ? record.data : payload;
}

function listFrom(payload: unknown, resourceKey: string): unknown[] {
  const unwrapped = unwrapData(payload);
  if (Array.isArray(unwrapped)) {
    return unwrapped;
  }

  const record = asRecord(unwrapped);
  if (!record) {
    return [];
  }

  for (const key of [resourceKey, "items", "results"]) {
    if (Array.isArray(record[key])) {
      return record[key];
    }
  }

  return [];
}

function errorMessageFrom(payload: unknown): string {
  const record = asRecord(unwrapData(payload)) ?? asRecord(payload);
  if (!record) {
    return typeof payload === "string" ? payload : "";
  }

  const message = record.message ?? record.error ?? record.detail;
  if (Array.isArray(message)) {
    return message.filter((item): item is string => typeof item === "string").join(" ");
  }

  return typeof message === "string" ? message : "";
}

function apiUrl(path: string): string {
  return `${apiBaseUrl}${path}`;
}

async function request<T>(path: string, options: ApiRequestOptions = {}): Promise<T> {
  const headers = new Headers(options.headers);
  const shouldAuthenticate = options.auth !== false;
  const session = shouldAuthenticate ? getStoredSession() : null;

  if (session?.token) {
    headers.set("Authorization", `Bearer ${session.token}`);
  }

  const isFormData = typeof FormData !== "undefined" && options.body instanceof FormData;
  if (options.body !== undefined && !isFormData) {
    headers.set("Content-Type", "application/json");
  }

  const requestBody =
    options.body === undefined
      ? undefined
      : isFormData
        ? (options.body as FormData)
        : JSON.stringify(options.body);

  let response: Response;
  try {
    response = await fetch(apiUrl(path), {
      method: options.method ?? "GET",
      headers,
      body: requestBody,
      signal: options.signal,
    });
  } catch (error) {
    const reason = error instanceof Error ? ` ${error.message}` : "";
    throw new ApiError(`Could not reach the API at ${apiBaseUrl}.${reason}`);
  }

  const responseText = await response.text();
  let payload: unknown = null;
  if (responseText) {
    try {
      payload = JSON.parse(responseText) as unknown;
    } catch {
      payload = responseText;
    }
  }

  if (!response.ok) {
    throw new ApiError(
      errorMessageFrom(payload) || `The API returned ${response.status} ${response.statusText}.`,
      response.status,
      payload,
    );
  }

  return payload as T;
}

function categoryFrom(value: unknown): Category {
  const record = asRecord(value);
  const isActive = booleanFrom(record, ["isActive"]);
  return {
    id: stringFrom(record, ["id", "categoryId", "uuid"]),
    name: stringFrom(record, ["name", "title"]),
    description: stringFrom(record, ["description", "details"]) || undefined,
    status: isActive === undefined ? stringFrom(record, ["status"]) || "UNSPECIFIED" : isActive ? "ACTIVE" : "INACTIVE",
    createdAt: stringFrom(record, ["createdAt", "created_at"]) || undefined,
  };
}

function merchantFrom(value: unknown): Merchant {
  const record = asRecord(value);
  const streetAddress = stringFrom(record, ["streetAddress"]);
  const city = stringFrom(record, ["city"]);
  const state = stringFrom(record, ["state"]);
  const locality = [city, state].filter(Boolean).join(", ");
  const isActive = booleanFrom(record, ["isActive"]);
  const isOpen = booleanFrom(record, ["isOpen"]);
  const status =
    isActive === false
      ? "INACTIVE"
      : isOpen === false
        ? "CLOSED"
        : isActive === true
          ? "ACTIVE"
          : stringFrom(record, ["status"]) || "UNSPECIFIED";

  return {
    id: stringFrom(record, ["id", "merchantId", "uuid"]),
    name: stringFrom(record, ["name", "displayName"]),
    type: stringFrom(record, ["type", "merchantType", "kind"]) || "UNSPECIFIED",
    description: stringFrom(record, ["description"]) || undefined,
    address: [streetAddress, locality].filter(Boolean).join(", ") || undefined,
    contactEmail: stringFrom(record, ["contactEmail", "email"]) || undefined,
    phone: stringFrom(record, ["phone"]) || undefined,
    status,
    createdAt: stringFrom(record, ["createdAt", "created_at"]) || undefined,
  };
}

function productFrom(value: unknown): CatalogProduct {
  const record = asRecord(value);
  const category = asRecord(record?.category);
  const inventory = asRecord(record?.inventory);
  const isPublished = booleanFrom(record, ["isPublished"]);
  const isAvailable = booleanFrom(inventory, ["isAvailable"]);
  const status =
    isPublished === false
      ? "DRAFT"
      : isAvailable === false
        ? "UNAVAILABLE"
        : isPublished === true
          ? "PUBLISHED"
          : stringFrom(record, ["status"]) || "UNSPECIFIED";

  return {
    id: stringFrom(record, ["id", "productId", "uuid"]),
    name: stringFrom(record, ["name", "title"]),
    description: stringFrom(record, ["description", "details"]) || undefined,
    imageUrl: stringFrom(record, ["imageUrl", "image_url"]) || undefined,
    price: numberFrom(record, ["price", "unitPrice"]),
    sku: stringFrom(record, ["sku", "code"]) || undefined,
    stock:
      numberFrom(inventory, ["quantity"]) ?? numberFrom(record, ["stock", "inventoryQuantity", "quantity"]),
    substitutionAllowed:
      booleanFrom(inventory, ["allowSubstitutions"]) ??
      booleanFrom(record, ["substitutionAllowed", "allowSubstitutions"]),
    categoryId:
      stringFrom(record, ["categoryId"]) || stringFrom(category, ["id", "categoryId"]) || undefined,
    categoryName: stringFrom(category, ["name", "title"]) || undefined,
    isPublished,
    status,
  };
}

function sessionFromLogin(payload: unknown): AuthSession {
  const response = asRecord(payload);
  const data = asRecord(unwrapData(payload));
  const token =
    stringFrom(data, ["accessToken", "access_token", "token", "jwt"]) ||
    stringFrom(response, ["accessToken", "access_token", "token", "jwt"]);

  if (!token) {
    throw new ApiError("The login response did not include an access token.");
  }

  const user = asRecord(data?.user) ?? asRecord(response?.user) ?? data ?? response;
  const firstName = stringFrom(user, ["firstName"]);
  const lastName = stringFrom(user, ["lastName"]);
  const fullName = [firstName, lastName].filter(Boolean).join(" ");
  return {
    token,
    user: {
      id: stringFrom(user, ["id", "userId", "uuid"]) || undefined,
      email: stringFrom(user, ["email"]) || undefined,
      name: stringFrom(user, ["name", "fullName", "displayName"]) || fullName || undefined,
      role:
        stringFrom(user, ["role", "userRole"]) ||
        stringFrom(data, ["role", "userRole"]) ||
        "UNKNOWN",
      merchantId:
        stringFrom(user, ["merchantId", "merchant_id"]) ||
        stringFrom(data, ["merchantId", "merchant_id"]) ||
        undefined,
    },
  };
}

export function getStoredSession(): AuthSession | null {
  if (typeof window === "undefined") {
    return null;
  }

  try {
    const value = window.localStorage.getItem(sessionStorageKey);
    if (!value) {
      return null;
    }

    const parsed = JSON.parse(value) as unknown;
    const record = asRecord(parsed);
    const token = stringFrom(record, ["token"]);
    const user = asRecord(record?.user);
    if (!token || !user) {
      return null;
    }

    return {
      token,
      user: {
        id: stringFrom(user, ["id"]) || undefined,
        email: stringFrom(user, ["email"]) || undefined,
        name: stringFrom(user, ["name"]) || undefined,
        role: stringFrom(user, ["role"]) || "UNKNOWN",
        merchantId: stringFrom(user, ["merchantId"]) || undefined,
      },
    };
  } catch {
    return null;
  }
}

export function saveStoredSession(session: AuthSession): void {
  if (typeof window !== "undefined") {
    window.localStorage.setItem(sessionStorageKey, JSON.stringify(session));
  }
}

export function clearStoredSession(): void {
  if (typeof window !== "undefined") {
    window.localStorage.removeItem(sessionStorageKey);
  }
}

export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError || error instanceof Error) {
    return error.message;
  }

  return "Something went wrong. Please try again.";
}

export const api = {
  async login(credentials: LoginCredentials): Promise<AuthSession> {
    const payload = await request<unknown>("/v1/auth/login", {
      method: "POST",
      body: credentials,
      auth: false,
    });

    return sessionFromLogin(payload);
  },

  async listCategories(): Promise<Category[]> {
    const payload = await request<unknown>("/v1/admin/categories");
    return listFrom(payload, "categories").map(categoryFrom);
  },

  async listCatalogCategories(): Promise<Category[]> {
    const payload = await request<unknown>("/v1/categories", { auth: false });
    return listFrom(payload, "categories").map(categoryFrom);
  },

  async createCategory(input: CreateCategoryInput): Promise<void> {
    await request<unknown>("/v1/admin/categories", {
      method: "POST",
      body: input,
    });
  },

  async listMerchants(): Promise<Merchant[]> {
    const payload = await request<unknown>("/v1/admin/merchants");
    return listFrom(payload, "merchants").map(merchantFrom);
  },

  async listManageableMerchants(): Promise<Merchant[]> {
    const payload = await request<unknown>("/v1/merchant-catalog/merchants");
    return listFrom(payload, "merchants").map(merchantFrom);
  },

  async createMerchant(input: CreateMerchantInput): Promise<void> {
    await request<unknown>("/v1/admin/merchants", {
      method: "POST",
      body: input,
    });
  },

  async removeMerchant(merchantId: string): Promise<void> {
    await request<unknown>(`/v1/admin/merchants/${encodeURIComponent(merchantId)}`, {
      method: "DELETE",
    });
  },

  async listMerchantProducts(merchantId: string): Promise<CatalogProduct[]> {
    const payload = await request<unknown>(
      `/v1/merchant-catalog/${encodeURIComponent(merchantId)}/products`,
    );
    return listFrom(payload, "products").map(productFrom);
  },

  async createMerchantProduct(merchantId: string, input: CreateProductInput): Promise<CatalogProduct> {
    const payload = await request<unknown>(
      `/v1/merchant-catalog/${encodeURIComponent(merchantId)}/products`,
      {
        method: "POST",
        body: input,
      },
    );
    return productFrom(payload);
  },

  async updateMerchantProductPublication(
    merchantId: string,
    productId: string,
    published: boolean,
  ): Promise<CatalogProduct> {
    const payload = await request<unknown>(
      `/v1/merchant-catalog/${encodeURIComponent(merchantId)}/products/${encodeURIComponent(productId)}/publish`,
      {
        method: "PATCH",
        body: { published },
      },
    );
    return productFrom(payload);
  },

  async updateMerchantProductImage(
    merchantId: string,
    productId: string,
    imageUrl: string,
  ): Promise<CatalogProduct> {
    const payload = await request<unknown>(
      `/v1/merchant-catalog/${encodeURIComponent(merchantId)}/products/${encodeURIComponent(productId)}`,
      {
        method: "PATCH",
        body: { imageUrl },
      },
    );
    return productFrom(payload);
  },

  async clearMerchantProductImage(
    merchantId: string,
    productId: string,
  ): Promise<CatalogProduct> {
    const payload = await request<unknown>(
      `/v1/merchant-catalog/${encodeURIComponent(merchantId)}/products/${encodeURIComponent(productId)}/image`,
      { method: "DELETE" },
    );
    return productFrom(payload);
  },

  async deleteMerchantProduct(merchantId: string, productId: string): Promise<void> {
    await request<unknown>(
      `/v1/merchant-catalog/${encodeURIComponent(merchantId)}/products/${encodeURIComponent(productId)}`,
      { method: "DELETE" },
    );
  },

  async uploadMerchantImage(merchantId: string, file: File): Promise<string> {
    const body = new FormData();
    body.append("merchantId", merchantId);
    body.append("file", file);

    const payload = await request<unknown>("/v1/media/uploads", {
      method: "POST",
      body,
    });
    const url = stringFrom(asRecord(unwrapData(payload)) ?? asRecord(payload), ["url"]);
    if (!url) {
      throw new ApiError("The upload did not return an image URL.");
    }
    return url;
  },
};
