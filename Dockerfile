# =====================================================
# BUILDER
# =====================================================
FROM node:20-alpine AS builder
WORKDIR /usr/src/flowise

RUN apk add --no-cache \
    libc6-compat \
    python3 \
    make \
    g++ \
    build-base \
    cairo-dev \
    pango-dev \
    curl

RUN npm install -g pnpm

# Ważne pliki monorepo + lockfile
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./

# Manifesty paczek (żeby pnpm zainstalował workspace deps i cache działał)
COPY packages/*/package.json packages/*/

# Teraz instalacja workspace
RUN pnpm install -r --frozen-lockfile

# Reszta źródeł
COPY . .

# Build
RUN pnpm -r build


# =====================================================
# RUNTIME
# =====================================================
FROM node:20-alpine AS runtime
WORKDIR /usr/src/flowise

RUN apk add --no-cache \
    libc6-compat \
    chromium

RUN npm install -g pnpm

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV NODE_OPTIONS=--max-old-space-size=8192
ENV NODE_ENV=production

COPY --from=builder --chown=node:node /usr/src/flowise /usr/src/flowise

USER node
EXPOSE 3000
CMD ["pnpm", "start"]
