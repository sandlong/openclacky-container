# OpenClacky standard container

A thin extension of OpenClacky's official container image with a practical baseline of local tools and stdio MCP package runners.

The image does **not** rebuild or pin a separate OpenClacky release. Its Dockerfile starts from:

```dockerfile
FROM ghcr.io/clacky-ai/openclacky:latest
```

Each workflow run resolves that tag to an immutable digest, builds from that exact digest, and records it in the image label `org.opencontainers.image.base.digest`.

## Added tools

- Node.js 24 LTS, npm, `npx`, and Corepack
- `uv` and `uvx`
- `curl`, Git, `jq`, and `ripgrep`
- `file`, `patch`, `xz`, and `unzip`
- `procps`, `lsof`, and `tini`
- Python 3

OpenClacky's existing Ruby runtime and `mise` installation come directly from the official image.

## Architecture

The current official OpenClacky image is published only for `linux/amd64`, so this extension is also amd64-only. The Dockerfile can become conventionally multi-platform once upstream publishes an arm64 image; it intentionally does not transplant upstream files into a separately constructed arm64 runtime.

## Pull

```bash
docker pull ghcr.io/sandlong/openclacky:latest
```

## Run

```bash
docker run --rm -p 7070:7070 \
  -v openclacky-data:/root/.clacky \
  ghcr.io/sandlong/openclacky:latest
```

## Build locally

```bash
docker build -t openclacky:standard .
```

## Publishing

The workflow runs when `main` changes, on manual dispatch, and once per day. Scheduled runs compare the current official-image digest with the base digest recorded in the published image and skip rebuilding when nothing changed.

Published tags include:

- `latest`
- `upstream-<OpenClacky version>`
- `upstream-<official digest prefix>`
- `sha-<repository commit>`

Before publishing, the workflow verifies that the inherited OpenClacky version matches the official image, checks every bundled CLI, and tests the `/health` endpoint.

## Relationship to upstream

This repository is an independent container extension and is not affiliated with the OpenClacky project. OpenClacky remains licensed under its upstream license.
