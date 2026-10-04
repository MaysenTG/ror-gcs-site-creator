# Gusto Cloud

Rails app for editing and hosting static sites on Cloudflare R2.

## Requirements

- Ruby **3.2.3**
- PostgreSQL
- Redis (Sidekiq + production cache)
- Cloudflare R2 bucket + API token

## Setup

```bash
cp .env.example .env
# fill R2_* values in .env

bundle install
bin/rails db:prepare
bin/rails dev:cache          # enable local Rails.cache (recommended)
```

## Run locally

In three terminals (or use Overmind/Foreman with `Procfile.dev`):

```bash
bundle exec rails s
bundle exec sidekiq -C config/sidekiq.yml
# Redis must already be running, e.g. `redis-server`
```

App: [http://localhost:3000](http://localhost:3000)  
Site previews: `http://localhost:3000/s/:site_name/`

## Environment

Copy from `.env.example`. Important keys:

| Variable | Purpose |
|---|---|
| `R2_ACCOUNT_ID` / `R2_ENDPOINT` | R2 API endpoint |
| `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` | R2 credentials |
| `R2_BUCKET` | Shared bucket (sites are key prefixes) |
| `R2_PUBLIC_BASE_URL` | Public object URL base |
| `REDIS_URL` | Sidekiq + production cache |
| `DATABASE_URL` | Production Postgres (Fly sets this) |
| `SECRET_KEY_BASE` | Rails secret (production) |

## Fly.io (prepared, not deployed)

This repo includes `Dockerfile`, `fly.toml` (web + worker), and `.dockerignore`.

When you are ready to create a **new** Fly app:

```bash
fly auth login
fly apps create gusto-cloud          # or change `app` in fly.toml
fly mpg create                       # managed Postgres → sets DATABASE_URL
fly redis create                     # sets REDIS_URL
fly secrets set SECRET_KEY_BASE="$(bin/rails secret)" \
  R2_ACCOUNT_ID=... R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=... \
  R2_ENDPOINT=... R2_BUCKET=... R2_PUBLIC_BASE_URL=... R2_REGION=auto
fly deploy
fly scale count web=1 worker=1
```

`fly.toml` already defines:

- **web** — Puma (`./bin/rails server`)
- **worker** — Sidekiq
- **release_command** — `db:prepare` on each deploy
- health check on `/up`

Do **not** run `fly deploy` until secrets and Postgres/Redis are attached.
