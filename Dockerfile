# syntax=docker/dockerfile:1.7

ARG OPENCLACKY_IMAGE=ghcr.io/clacky-ai/openclacky:latest
ARG NODE_IMAGE=node:24-bookworm-slim
ARG UV_IMAGE=ghcr.io/astral-sh/uv:0.12.1

FROM ${NODE_IMAGE} AS node
FROM ${UV_IMAGE} AS uv

# Reuse OpenClacky's official image so this container contains exactly the
# upstream image's OpenClacky build rather than rebuilding a separate release.
FROM ${OPENCLACKY_IMAGE}

ARG SOURCE_REPOSITORY=https://github.com/sandlong/openclacky-container
ARG UPSTREAM_DIGEST=unknown

LABEL org.opencontainers.image.title="openclacky-standard" \
      org.opencontainers.image.description="The official OpenClacky image with common agent CLIs" \
      org.opencontainers.image.source="${SOURCE_REPOSITORY}" \
      org.opencontainers.image.url="https://github.com/clacky-ai/openclacky" \
      org.opencontainers.image.base.name="ghcr.io/clacky-ai/openclacky:latest" \
      org.opencontainers.image.base.digest="${UPSTREAM_DIGEST}" \
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

# Node/npm/npx/corepack, copied from the official Node image.
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && ln -sf ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack

# uv and uvx, copied from Astral's official image.
COPY --from=uv /uv /uvx /usr/local/bin/

# Keep the official command, adding a minimal init for child-process reaping.
ENTRYPOINT ["tini", "--", "openclacky"]
CMD ["server", "--host", "0.0.0.0"]
