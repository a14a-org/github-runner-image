# a14a-org/github-runner-image

Custom self-hosted GitHub Actions runner image for a14a-org's fleet. Extends
[`myoung34/github-runner`](https://github.com/myoung34/docker-github-actions-runner)
with the toolchain the fleet's CI workflows expect.

## What's in it

| Tool | Source |
|---|---|
| Runner agent, `gh`, `git`, `curl`, `jq` | inherited from `myoung34/github-runner:latest` |
| Node.js 20 + `npm` | NodeSource Debian repo |
| Bun (latest) | `bun.sh/install` |
| Python 3 + `pip` | Debian package |
| `build-essential` (gcc, make) | Debian package |
| `docker` CLI | Docker's official Debian repo |

The Docker CLI is included but **needs `/var/run/docker.sock` mounted into
the container** to actually invoke Docker. That mount is configured in
Coolify, not here.

## How it's published

`.github/workflows/release.yml` builds and pushes to
`ghcr.io/a14a-org/github-runner` on every push to `main` (as `:latest`) and
on every `v*` tag (as `:vX.Y.Z` and `:vX.Y`).

## How to update the runner

Tag a new version locally:

```bash
git tag v0.2.0
git push origin v0.2.0
```

CI builds the image, pushes to ghcr.io.

Then in Coolify → `github-runner-ri7ng8lqvntvie43rgq0bn91` service → change
the image tag and restart. The Coolify service is configured with
`/var/run/docker.sock` mounted (set this up once).

## Verifying

After the runner restarts, dispatch the probe workflow at
`a14a-org/cantrip/.github/workflows/runner-probe.yml` (or any private repo
with that workflow) — it prints versions of every tool.
