# =====================================================
# BUILDER STAGE
# =====================================================
FROM node:20-alpine AS builder

WORKDIR /usr/src/flowise

# System deps tylko do builda
RUN apk add --no-cache \
    libc6-compat \
    python3 \
    make \
    g++ \
    build-base \
    cairo-dev \
    pango-dev \
    curl

# pnpm
RUN npm install -g pnpm

# Najpierw manifesty (lepszy cache)
COPY package.json pnpm-lock.yaml ./

# Instalacja zależności (w tym dev)
RUN pnpm install --frozen-lockfile

# Reszta źródeł (custom nodes / credentials też)
COPY . .

# Build Flowise
RUN pnpm build


# =====================================================
# RUNTIME STAGE
# =====================================================
FROM node:20-alpine AS runtime

WORKDIR /usr/src/flowise

# Runtime deps (chromium zostawione)
RUN apk add --no-cache \
    libc6-compat \
    chromium

# pnpm do startu
RUN npm install -g pnpm

# Env dla puppeteera / node
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV NODE_OPTIONS=--max-old-space-size=8192
ENV NODE_ENV=production

# Kopiuj gotową aplikację z buildera
# --chown zamiast chown -R (nie robi giga-warstwy)
COPY --from=builder --chown=node:node /usr/src/flowise /usr/src/flowise

# Non-root
USER node

EXPOSE 3000

CMD ["pnpm", "start"]
