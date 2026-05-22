# Stremio Node 20.x
ARG NODE_VERSION=20-alpine
FROM node:$NODE_VERSION AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable && corepack prepare pnpm@9.15.0 --activate
RUN apk add --no-cache git

LABEL Description="Stremio Web" Vendor="Smart Code OOD" Version="1.0.0"

RUN mkdir -p /var/www/stremio-web
WORKDIR /var/www/stremio-web

FROM base AS app

COPY package.json pnpm-lock.yaml /var/www/stremio-web
RUN pnpm i --frozen-lockfile

COPY . /var/www/stremio-web
RUN git config --global user.email "build@build.com" && \
    git config --global user.name "Build" && \
    git init && git add -A && git commit -m "build"
RUN pnpm build

FROM base AS server
RUN pnpm i express@4

FROM base

COPY http_server.js /var/www/stremio-web
COPY --from=server /var/www/stremio-web/node_modules /var/www/stremio-web/node_modules
COPY --from=app /var/www/stremio-web/build /var/www/stremio-web/build

EXPOSE 8080
CMD ["node", "http_server.js"]