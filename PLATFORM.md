# Delivery Platform Architecture

## Runtime Topology

```text
Flutter customer app/web ----\
Admin + merchant web ---------> NestJS API -> PostgreSQL
Courier Flutter app ----------/       |
                                      +-> Redis/BullMQ
                                      +-> Cloudinary signed uploads
                                      +-> Stripe payment intents
                                      +-> Maps and Firebase configuration
```

## Applications

| Path | Purpose |
| --- | --- |
| `.` | Customer Flutter app for iOS, Android, and web. It reads public catalog data from the API when `API_BASE_URL` is supplied and otherwise uses safe local demo data. |
| `apps/operations-web` | Admin and merchant console for categories, merchants, products, inventory, and operations. |
| `apps/courier_app` | Courier availability, delivery offers, active delivery, and status workflow. |
| `services/api` | NestJS modular monolith, Prisma schema, RBAC, catalog, payments, media, and dispatch APIs. |
| `infra` | Local Docker Compose configuration and environment template. |

## Ownership Boundaries

- Admins manage global categories, merchant approval, platform policy, and support operations.
- Merchant users are limited to their own merchants, products, stock, substitutions, and incoming orders.
- Couriers can only see available offers and deliveries assigned to them.
- Customers only use public discovery endpoints plus their authenticated order/payment endpoints.

The API enforces these boundaries with JWTs and role/membership checks. Neither Flutter app nor the operations console accesses PostgreSQL directly.

## Local Startup

1. Install Docker Desktop and start it.
2. Copy `infra/compose.env.example` to `.env` in the repository root and replace local secrets.
3. Run `docker compose up --build`.
4. Run `docker compose exec api npm run prisma:seed` after API startup.
5. Open `http://localhost:3000/docs` for API documentation and `http://localhost:5173` for operations.

The local seed expects `SEED_PASSWORD` and `ADMIN_PASSWORD` in the untracked root `.env`. It creates these local-only accounts:

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin@example.test` | `ADMIN_PASSWORD` |
| Merchant | `merchant@example.test` | `SEED_PASSWORD` |
| Courier | `courier@example.test` | `SEED_PASSWORD` |
| Customer | `customer@example.test` | `SEED_PASSWORD` |

Never use these accounts or passwords outside local development.

## Product Images

The catalog workspace accepts JPEG, PNG, WebP, and GIF photos up to 5 MB. In local Docker development, uploaded files persist in the `media-data` volume and are served from `PUBLIC_API_URL/uploads`. A full image URL can also be attached to a product. Configure Cloudinary credentials for hosted production uploads.

For customer web development against the local API:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

For Android emulators, replace `localhost` with `10.0.2.2`. For physical devices, use a reachable HTTPS API domain rather than a loopback address.

For courier web development:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

Run the courier command from `apps/courier_app`.

## Deployment Sequence

1. Provision managed PostgreSQL and Redis in the same region as the API.
2. Set production secrets in the deployment platform, never in source control.
3. Deploy the API container and run `npm run prisma:deploy` once per release.
4. Deploy operations web with `NEXT_PUBLIC_API_URL` set to the public API origin.
5. Configure the API CORS allowlist for the customer web and operations web domains.
6. Build and submit the Flutter customer and courier apps with their API base URLs supplied through CI.
7. Add Cloudinary, Stripe, Maps, and Firebase credentials after their accounts and webhooks are configured.
