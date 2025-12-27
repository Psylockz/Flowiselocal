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
  curl \
  git

RUN npm install -g pnpm

# kopiujemy całe repo
COPY . .

# instalacja workspace + build
RUN pnpm install -r --no-frozen-lockfile
RUN pnpm turbo run build
RUN pnpm turbo run build --concurrency=1


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
