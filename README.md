# OpenClacky standard container

A minimally extended build of [OpenClacky](https://github.com/clacky-ai/openclacky), published for both `linux/amd64` and `linux/arm64`.

The Dockerfile keeps the official Ruby build and runtime structure, then adds a practical baseline for local tools and stdio MCP servers:

- Node.js 24 LTS, npm, `npx`, and Corepack
- `uv` and `uvx`
- `curl`, Git, `jq`, and `ripgrep`
- `file`, `patch`, `xz`, and `unzip`
- `procps`, `lsof`, and `tini`
- Python 3 and OpenClacky's existing `mise` installation

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

The pinned upstream release is stored in `OPENCLACKY_VERSION`.

```bash
VERSION="$(cat OPENCLACKY_VERSION)"
docker build \
  --build-arg OPENCLACKY_VERSION="$VERSION" \
  -t openclacky:standard .
```

## Publishing

Pushes to `main` publish these GHCR tags:

- `latest`
- the upstream OpenClacky version, such as `1.5.4`
- `sha-<commit>`

The workflow first tests the command-line baseline and the `/health` endpoint, then publishes one multi-platform manifest containing `linux/amd64` and `linux/arm64` images.

## Relationship to upstream

This repository is an independent container build and is not affiliated with the OpenClacky project. OpenClacky remains licensed under its upstream license.
