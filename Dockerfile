# =========================
# BUILD STAGE
# =========================
FROM node:20-alpine AS builder
WORKDIR /usr/src/flowise

ENV PUPPETEER_SKIP_DOWNLOAD=true

RUN apk add --no-cache \
  libc6-compat \
  python3 \
  make \
  g++ \
  build-base \
  cairo-dev \
  pango-dev \
  git \
  curl

# pnpm przez corepack (mniej bałaganu niż npm -g)
RUN corepack enable

# Kopiuj tylko to, co potrzebne do instalacji (lepszy cache)
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json turbo.json ./
COPY packages ./packages

# install + build
RUN pnpm install -r --frozen-lockfile
RUN pnpm turbo run build --concurrency=1

# Zrób “deploy” tylko dla serwera (produkcyjne node_modules + zbudowane artefakty)
# Uwaga: podmień nazwę filtra jeśli Twój package nazywa się inaczej niż "flowise"
RUN pnpm --filter ./packages/server... deploy --prod /out


# =========================
# RUNTIME STAGE
# =========================
FROM node:20-alpine
WORKDIR /app

ENV NODE_ENV=production
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV PUPPETEER_SKIP_DOWNLOAD=true

# Chromium + minimalne runtime libs
RUN apk add --no-cache \
  chromium \
  nss \
  freetype \
  harfbuzz \
  ca-certificates \
  ttf-freefont \
  libc6-compat \
  python3

# Skopiuj tylko “wydestylowany” serwer
COPY --from=builder /out /app

EXPOSE 3000
CMD ["node", "dist/index.js"]
