# Local Infrastructure

Install Docker Desktop, copy `compose.env.example` to the repository-root `.env`, then run:

```powershell
docker compose up --build
```

The stack exposes PostgreSQL on `5432`, Redis on `6379`, the API on `3000`, Swagger on `http://localhost:3000/docs`, and the operations console on `http://localhost:5173`.

The API container runs committed Prisma migrations on startup. Seed local users and catalog data after the stack is healthy:

```powershell
docker compose exec api npm run prisma:seed
```

Do not use the default passwords or local JWT secret outside development.
