# OpenClacky standard container

A multi-architecture OpenClacky image with a practical baseline of agent and stdio MCP tools.

```bash
docker pull ghcr.io/sandlong/openclacky:latest
```

## What is added

- Node.js 24 LTS, npm, `npx`, and Corepack
- `uv` and `uvx`
- `curl`, Git, `jq`, and `ripgrep`
- `file`, `patch`, `xz`, and `unzip`
- `procps`, `lsof`, and `tini`
- Python 3 and OpenClacky's existing `mise` capability

## Architecture design

The official image, `ghcr.io/clacky-ai/openclacky:latest`, currently publishes an amd64 runtime only. This repository nevertheless publishes native `linux/amd64` and `linux/arm64` images without rebuilding OpenClacky from source:

1. Resolve the official `latest` tag to an immutable digest.
2. Copy its exact `/usr/local/bundle` into a Ruby runtime matching the official Ruby version for each target architecture.
3. Install architecture-native Node, uv, mise, system packages, and Ruby itself.
4. Verify the OpenClacky bundle contains no native `.so` or `.bundle` files before publishing.
5. Run CLI and HTTP health tests on both amd64 and arm64.

The workflow intentionally fails if upstream introduces an architecture-specific Ruby dependency. Once the official image itself supports arm64, this workaround can be replaced by a simpler direct wrapper around the official multi-architecture image.

## Run

```bash
docker run --rm -p 7070:7070 \
  -v openclacky-data:/root/.clacky \
  ghcr.io/sandlong/openclacky:latest
```

## Updates and tags

The workflow checks the official image daily and rebuilds only when its digest changes. Pushes to `main` also publish immediately.

Published tags include:

- `latest`
- `upstream-<OpenClacky version>`
- `upstream-<official image digest prefix>`
- `sha-<repository commit>`

Each image records the exact official payload digest and native Ruby runtime image in OCI labels.

## Relationship to upstream

This repository is an independent container build and is not affiliated with the OpenClacky project. OpenClacky remains licensed under its upstream license.
