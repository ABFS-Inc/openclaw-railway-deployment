FROM node:24-bookworm

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    tini \
    procps \
    python3 \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw@2026.3.13

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile --prod

COPY src ./src

RUN mkdir -p /data

ENV NODE_ENV=production
ENV PORT=8080
ENV OPENCLAW_ENTRY=/usr/local/lib/node_modules/openclaw/dist/entry.js
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD curl -f http://localhost:8080/setup/healthz || exit 1

ENTRYPOINT ["tini", "--"]
CMD ["node", "src/server.js"]
