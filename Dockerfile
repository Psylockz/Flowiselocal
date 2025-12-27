# =========================
# BUILD STAGE
# =========================
FROM node:20-alpine AS builder
WORKDIR /usr/src/flowise

ENV NODE_OPTIONS=--max-old-space-size=4096
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV CI=true

RUN apk add --no-cache \
  libc6-compat \
  python3 \
  make \
  g++ \
  build-base \
  cairo-dev \
  pango-dev \
  curl \
  git

RUN npm install -g pnpm

COPY . .

RUN pnpm install -r --no-frozen-lockfile
RUN pnpm turbo run build --concurrency=1

# ✅ usuń dev deps bez odpalania postinstall (husky)
RUN rm -rf node_modules
RUN pnpm install -r --prod --no-frozen-lockfile --ignore-scripts


# =========================
# RUNTIME STAGE
# =========================
FROM node:20-alpine
WORKDIR /usr/src/flowise

RUN apk add --no-cache \
  libc6-compat \
  chromium \
  nss \
  freetype \
  harfbuzz \
  ca-certificates \
  ttf-freefont

ENV NODE_ENV=production
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

RUN npm install -g pnpm

COPY --from=builder /usr/src/flowise /usr/src/flowise

EXPOSE 3000
CMD ["pnpm", "start"]
