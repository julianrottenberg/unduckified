# Unduckified - self-hosted static build for podman/nginx.
# The upstream project targets Cloudflare Pages; this produces a plain
# nginx image instead (see nginx.conf for the _headers equivalents).
FROM docker.io/oven/bun:1-alpine AS builder
WORKDIR /app
COPY . .
# Build in two steps so we can bump BANG_DATA_VERSION between packbang and the
# vite/worker build: the SW cache name includes the data version, and bumping
# it forces clients to drop their cached catalog (self-heal after bad deploys).
RUN bun install \
    && bun run src/bangs/packbang.ts \
    && sed -i 's/";$/-brfix";/' src/bangs/data-version.ts \
    && bunx --bun vite build \
    && bun run src/build-workers.ts

FROM docker.io/library/nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
