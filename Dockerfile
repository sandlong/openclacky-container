# syntax=docker/dockerfile:1.7

ARG OPENCLACKY_IMAGE=ghcr.io/clacky-ai/openclacky:latest
ARG UPSTREAM_PLATFORM=linux/amd64
ARG RUBY_IMAGE=ruby:3.4-slim
ARG NODE_IMAGE=node:24-bookworm-slim
ARG UV_IMAGE=ghcr.io/astral-sh/uv:0.12.1

# Upstream currently publishes only amd64. Its /usr/local/bundle is copied as
# architecture-independent payload into a native runtime for each target.
FROM --platform=${UPSTREAM_PLATFORM} ${OPENCLACKY_IMAGE} AS openclacky
FROM ${NODE_IMAGE} AS node
FROM ${UV_IMAGE} AS uv
FROM ${RUBY_IMAGE}

ARG RUBY_IMAGE
ARG SOURCE_REPOSITORY=https://github.com/sandlong/openclacky-container
ARG UPSTREAM_IMAGE_NAME=ghcr.io/clacky-ai/openclacky:latest
ARG UPSTREAM_DIGEST=unknown
ARG UPSTREAM_VERSION=unknown

LABEL org.opencontainers.image.title="openclacky-standard" \
      org.opencontainers.image.description="Multi-architecture OpenClacky runtime with common agent CLIs" \
      org.opencontainers.image.source="${SOURCE_REPOSITORY}" \
      org.opencontainers.image.url="https://github.com/clacky-ai/openclacky" \
      org.opencontainers.image.version="${UPSTREAM_VERSION}" \
      org.opencontainers.image.licenses="MIT" \
      io.github.sandlong.openclacky.source.image="${UPSTREAM_IMAGE_NAME}" \
      io.github.sandlong.openclacky.source.digest="${UPSTREAM_DIGEST}" \
      io.github.sandlong.openclacky.runtime.image="${RUBY_IMAGE}"

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

# This is the exact gem bundle built into the official image. The publishing
# workflow verifies that it contains no architecture-specific native files.
COPY --from=openclacky /usr/local/bundle /usr/local/bundle

# Node/npm/npx/corepack and uv/uvx come from native multi-architecture images.
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && ln -sf ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack
COPY --from=uv /uv /uvx /usr/local/bin/

# Match the official image's mise installation, but install a native binary for
# the target architecture rather than copying its amd64 executable.
RUN curl -fsSL https://mise.run | sh
ENV PATH="/root/.local/bin:${PATH}"

VOLUME ["/root/.clacky"]
EXPOSE 7070

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:7070/health || exit 1

ENTRYPOINT ["tini", "--", "openclacky"]
CMD ["server", "--host", "0.0.0.0"]
