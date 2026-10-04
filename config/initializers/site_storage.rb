# Cloudflare R2 credentials for SiteStorage (S3-compatible API).
#
# Shared bucket: ror-site-creator (override with R2_BUCKET)
# Site objects live under prefix: {site}.maysengreenwood.com/
#
# Theme starter files + iframe previews are local static assets:
#   public/theme_previews/{blank,portfolio,skeleton_react}/
# Served at /theme_previews/... and copied into R2 when a site is created.
#
# Required env:
#   R2_ACCOUNT_ID=...
#   R2_ACCESS_KEY_ID=<from R2 Manage API Tokens>
#   R2_SECRET_ACCESS_KEY=<from R2 Manage API Tokens>
#
# Optional:
#   R2_BUCKET=ror-site-creator
#   R2_ENDPOINT=https://<account_id>.r2.cloudflarestorage.com
#   R2_PUBLIC_BASE_URL=https://pub-xxxx.r2.dev   # public URLs for site objects
#   R2_REGION=auto
#
# Create tokens in the dashboard:
#   https://dash.cloudflare.com/<account_id>/r2/api-tokens
