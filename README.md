# Gusto Cloud

Rails app for editing and hosting static sites on Cloudflare R2.

Live: [https://static-site-creator.fly.dev](https://static-site-creator.fly.dev)

## What it does

- **Browser editor** for site files (CodeMirror). Create, rename, upload and delete files and folders.
- **Starter themes**: blank, portfolio and a React skeleton. Theme and colour palette remixes can be applied to an existing site.
- **Hosting on R2**: one shared bucket, each site is a key prefix. Published sites are served by the app at `/s/:site_name/` or on a `*.maysengreenwood.com` subdomain.
- **File history**: short-lived text file versions (about 2 days) you can restore, plus named whole-site snapshots ("moments", up to 12 per site) with a diff against the live site.
- **Password gate**: optionally lock a site behind a visitor password.
- **Custom domains**: add a domain and run a DNS check against the expected CNAME / A records (it also spots Cloudflare-proxied records).
- **Analytics**: page views, top paths, countries and devices, shown on customisable dashboards.
- **Ship check**: quick pre-launch audit (index.html, 404.html, large files, basic HTML and SEO checks).
- **Plans + Stripe Checkout** for paid tiers, and an internal admin area for accounts, sites and plans.

Stack: Rails 8.1, Hotwire (Turbo + Stimulus), importmap, Bootstrap, Devise, `aws-sdk-s3` for R2, RSpec.

## Requirements

- Ruby **3.2.3**
- PostgreSQL (development)
- Cloudflare R2 bucket + API token
- Redis, only if you want Sidekiq (cron cleanup jobs) or the Redis cache. Jobs run in-process with the async adapter by default.

## Setup

```bash
cp .env.example .env
# fill R2_* values in .env

bundle install
bin/rails db:prepare
bin/rails dev:cache          # enable local Rails.cache (recommended)
```

## Run locally

```bash
bin/rails server
```

Background jobs use the async adapter in development, so you don't need Sidekiq to create or clone sites. If you want Sidekiq and the cron jobs from `config/schedule.yml`, start Redis and run both processes from `Procfile.dev` (Overmind/Foreman), or:

```bash
bin/rails server -p 3000
bin/sidekiq -C config/sidekiq.yml
```

App: [http://localhost:3000](http://localhost:3000)  
Site previews: `http://localhost:3000/s/:site_name/` (or `http://:site_name.localhost:3000/`)

## Tests

```bash
bundle exec rspec
```

The test database is SQLite, so you don't need Postgres running for the suite.

## Environment

Copy from `.env.example`. Important keys:

| Variable | Purpose |
|---|---|
| `R2_ACCOUNT_ID` / `R2_ENDPOINT` | R2 API endpoint |
| `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` | R2 credentials |
| `R2_BUCKET` | Shared bucket (sites are key prefixes) |
| `R2_PUBLIC_BASE_URL` | Public object URL base |
| `REDIS_URL` | Optional. Sidekiq and Redis cache |
| `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` | Optional. Falls back to Rails credentials |
| `DATABASE_PATH` | Production SQLite file (Fly volume) |
| `SECRET_KEY_BASE` | Rails secret (production) |

## Fly.io

Deployed as the `static-site-creator` Fly app in `syd`. Pushes to `main` deploy through `.github/workflows/fly.yml` (needs a `FLY_API_TOKEN` repo secret).

Production is kept cheap on purpose: a single Machine running Puma on port 8080, with SQLite on a 1 GB volume mounted at `/data`. There is no separate worker or Postgres. Jobs run with the async adapter unless you set `ACTIVE_JOB_ADAPTER=sidekiq` and provide `REDIS_URL`.

First-time setup:

```bash
fly auth login
fly volumes create data --region syd --size 1 -a static-site-creator
fly secrets set SECRET_KEY_BASE="$(bin/rails secret)" \
  R2_ACCOUNT_ID=... R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=... \
  R2_ENDPOINT=... R2_BUCKET=... R2_PUBLIC_BASE_URL=... R2_REGION=auto
fly deploy
```

`fly.toml` and the Dockerfile already handle:

- **web**: Puma (`./bin/rails server -b 0.0.0.0 -p 8080`)
- **database**: `bin/docker-entrypoint` runs `db:prepare` and `db:seed` against the volume on boot
- health check on `/up`
- `min_machines_running = 1`, so the app doesn't sleep
