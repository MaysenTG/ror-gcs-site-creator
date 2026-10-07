# syntax=docker/dockerfile:1
# Single Machine: Puma on :8080, SQLite on /data volume. No nginx.

ARG RUBY_VERSION=3.2.3
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libsqlite3-0 libvips && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH=/usr/local/bundle

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libsqlite3-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .
RUN SECRET_KEY_BASE=1 bundle exec rails assets:precompile

FROM base

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

COPY bin/docker-entrypoint /rails/bin/docker-entrypoint
RUN chmod +x /rails/bin/docker-entrypoint

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 8080
# Entrypoint runs as root for /data volume; Puma drops to rails.
CMD ["bash", "-c", "exec su -s /bin/bash rails -c './bin/rails server -b 0.0.0.0 -p 8080'"]