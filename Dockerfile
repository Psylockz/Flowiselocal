# =========================
# Stage 1: Build
# =========================
FROM node:20-alpine AS build
WORKDIR /usr/src/flowise

ENV PUPPETEER_SKIP_DOWNLOAD=true

# build deps (TYLKO do kompilacji)
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

# monorepo files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./
COPY packages/*/package.json packages/*/

# jeśli lockfile Ci się często rozjeżdża, użyj --no-frozen-lockfile
RUN pnpm install -r --no-frozen-lockfile

# reszta kodu (tu wchodzą Twoje custom nodes/credentials)
COPY . .

# build wszystkiego
RUN pnpm -r build


# =========================
# Stage 2: Runtime
# =========================
FROM node:20-alpine
WORKDIR /usr/src/flowise

# runtime deps (chromium jeśli używasz puppeteer features)
RUN apk add --no-cache \
  libc6-compat \
  chromium

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV NODE_ENV=production

RUN npm install -g pnpm

# kopiuj gotową aplikację
COPY --from=build /usr/src/flowise /usr/src/flowise

EXPOSE 3000
CMD ["pnpm", "start"]
