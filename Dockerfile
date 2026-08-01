# syntax=docker/dockerfile:1.7

ARG RUBY_IMAGE=ruby:3.4.4-slim
ARG NODE_IMAGE=node:24-bookworm-slim
ARG UV_IMAGE=ghcr.io/astral-sh/uv:0.12.1

FROM ${NODE_IMAGE} AS node
FROM ${UV_IMAGE} AS uv

FROM ${RUBY_IMAGE} AS builder

ARG OPENCLACKY_VERSION=1.5.4

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Build the requested upstream release from source, matching OpenClacky's
# official Dockerfile rather than relying on the published gem.
RUN git clone --depth 1 --branch "v${OPENCLACKY_VERSION}" \
    https://github.com/clacky-ai/openclacky.git /src
WORKDIR /src
RUN gem build openclacky.gemspec \
    && gem install ./openclacky-*.gem --no-document \
    && ruby -e 'require "clacky"; abort "bad version" unless Clacky::VERSION'

FROM ${RUBY_IMAGE}

ARG OPENCLACKY_VERSION=1.5.4
ARG SOURCE_REPOSITORY=https://github.com/sandlong/openclacky-container

LABEL org.opencontainers.image.title="openclacky-standard" \
      org.opencontainers.image.description="OpenClacky with common agent CLIs and amd64/arm64 support" \
      org.opencontainers.image.source="${SOURCE_REPOSITORY}" \
      org.opencontainers.image.url="https://github.com/clacky-ai/openclacky" \
      org.opencontainers.image.version="${OPENCLACKY_VERSION}" \
      org.opencontainers.image.licenses="MIT"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    file \
    git \
    jq \
    lsof \
    patch \
    procps \
    python3 \
    ripgrep \
    tini \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bundle /usr/local/bundle

# Node/npm/npx/corepack, copied from the official multi-architecture Node image.
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node /usr/local/bin/npx /usr/local/bin/npx
COPY --from=node /usr/local/bin/corepack /usr/local/bin/corepack
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

# uv and uvx, copied from Astral's official multi-architecture image.
COPY --from=uv /uv /uvx /usr/local/bin/

# Retained from OpenClacky's official image.
RUN curl -fsSL https://mise.run | sh
ENV PATH="/root/.local/bin:${PATH}"

VOLUME ["/root/.clacky"]

EXPOSE 7070

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:7070/health || exit 1

ENTRYPOINT ["tini", "--", "openclacky"]
CMD ["server", "--host", "0.0.0.0"]
