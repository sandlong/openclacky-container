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

## Persistent instance environment

The image loads `/root/.clacky/.env` before OpenClacky starts. Because
`/root/.clacky` is the persistent volume, instance-level credentials and other
environment variables can survive container recreation without being repeated
in every `docker run` command.

```dotenv
GITHUB_TOKEN=...
CLOUDFLARE_API_TOKEN=...
OPENAI_API_KEY=...
```

Blank lines, comments, quoted values, and optional `export KEY=value` syntax are
supported. The file is parsed as data rather than sourced as a shell script, so
it cannot execute commands. Variables already present in the container
environment take precedence over values in `/root/.clacky/.env`.

## Updates and tags

The workflow checks the official image daily and rebuilds only when its digest changes. An unchanged scheduled run performs only remote manifest checks; it does not create a builder, pull images, or run emulated containers. Pushes to `main` still publish immediately.

Published tags include:

- `latest`
- `upstream-<OpenClacky version>`
- `upstream-<official image digest prefix>`
- `sha-<repository commit>`

Each image records the exact official payload digest and native Ruby runtime image in OCI labels.

## Relationship to upstream

This repository is an independent container build and is not affiliated with the OpenClacky project. OpenClacky remains licensed under its upstream license.
