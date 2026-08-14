# Fieldwork Operations

An admin and merchant operations console built with Next.js App Router. It provides protected workspaces for category governance, merchant onboarding, and merchant-specific catalog creation.

## Run locally

1. Install dependencies with `npm install`.
2. Copy `.env.local.example` to `.env.local`.
3. Set `NEXT_PUBLIC_API_URL` to the NestJS API origin, such as `http://localhost:3000`.
4. Start the console with `npm run dev`; it listens on `http://localhost:5173`, which is included in the API example CORS configuration.

## API contract

The browser calls the API directly and sends the saved access token as `Authorization: Bearer <token>` on every protected request.

| Purpose | Method and path | Request body |
| --- | --- | --- |
| Sign in | `POST /v1/auth/login` | `{ email, password }` |
| List admin categories | `GET /v1/admin/categories` | None |
| List catalog categories | `GET /v1/categories` | None |
| Create category | `POST /v1/admin/categories` | `{ name, description?, isActive }` |
| List merchants | `GET /v1/admin/merchants` | None |
| Create merchant | `POST /v1/admin/merchants` | `{ name, type, contactEmail, description?, phone?, streetAddress?, city? }` |
| List a catalog | `GET /v1/merchant-catalog/:merchantId/products` | None |
| Create a product | `POST /v1/merchant-catalog/:merchantId/products` | `{ name, description?, price, sku, inventoryQuantity, allowSubstitutions, categoryId }` |

The Nest login response provides `accessToken` and a `user` with `id`, `email`, `firstName`, `lastName`, and `role`. The console stores the JWT in browser local storage, maps category status to `isActive`, and maps catalog stock/substitution controls to `inventoryQuantity` and `allowSubstitutions`. Merchant-specific access is enforced by the API using merchant membership; the current login response does not include a merchant ID.

## Validation

Run `npm run lint` and `npm run build` before deployment.
