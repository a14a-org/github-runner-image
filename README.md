# a14a-org/github-runner-image

Custom self-hosted GitHub Actions runner image for a14a-org's fleet. Extends
[`myoung34/github-runner`](https://github.com/myoung34/docker-github-actions-runner)
with the toolchain the fleet's CI workflows expect.

## What's in it

| Tool | Source |
|---|---|
| Runner agent, `gh`, `git`, `curl`, `jq` | inherited from a digest-pinned `myoung34/github-runner:latest` |
| Node.js 20 + `npm` | NodeSource apt repo |
| Bun 1.3.14 (installed to `/usr/local/bin/bun`) | version-pinned `bun.sh/install` |
| Python 3 + `pip` | apt package |
| `build-essential` (gcc, make) | apt package |
| Docker CLI (static binary, `/usr/local/bin/docker`) | `download.docker.com/linux/static` |

The Docker CLI is included but **needs `/var/run/docker.sock` mounted into
the container** to actually invoke Docker. That mount is configured in
Coolify, not here.

Renovate should update the inherited image digest deliberately. Treat that
update as an entrypoint/lifecycle change and repeat the persistence proof below
before promoting it to Coolify.

## How it's published

`.github/workflows/release.yml` builds and pushes to
`ghcr.io/a14a-org/github-runner-image` on every push to `main` (as `:latest`) and
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

Do not leave production workers on `:latest`. Promote an immutable version tag
after the image workflow is green so a future restart cannot silently change
the runner agent or its entrypoint behavior.

## Coolify lifecycle contract

The base image treats any non-empty `EPHEMERAL` value as enabled. In
particular, `EPHEMERAL=false` still registers an ephemeral runner and GitHub
deletes that registration after a job. Reusable workers must therefore satisfy
all of these invariants:

- `EPHEMERAL` is absent from the `Runner.Listener` process environment. The
  service entrypoint should explicitly unset it before executing the inherited
  entrypoint because Coolify may inject a value that is not present in the
  Compose source.
- Every replica has a fixed, unique `RUNNER_NAME`; do not generate a new name
  on every container start.
- Every replica has its own named volume mounted at `/runner/config` and sets
  `CONFIGURED_ACTIONS_RUNNER_FILES_DIR=/runner/config`.
- `DISABLE_AUTOMATIC_DEREGISTRATION=true` prevents an ordinary container stop
  from deleting the server-side registration.
- Registration files are never shared between replicas.

After any lifecycle change, prove persistence rather than relying on container
health alone:

1. record the three fixed runner names and GitHub agent IDs;
2. run at least two sequential probe jobs through the pool;
3. restart each container one at a time;
4. confirm the same names and agent IDs reconnect; and
5. run another protected repository workflow before removing stale offline
   registrations.

Keep a recoverable backup of `.runner`, `.credentials`, and
`.credentials_rsaparams` while changing volumes or entrypoints. Never print
their contents.

## Credentials and incident handling

Store the organization runner credential only as a masked Coolify secret. To
rotate it, install the replacement, prove all workers reconnect and complete
jobs, then revoke the previous credential. Never paste the service environment
or rendered Compose source into logs, issues, or chat.

If GitHub serves an invalid or expired certificate, stop registration retry
loops and retain the registration volumes. Do not disable TLS verification,
backdate the host clock, or permanently pin an upstream IP. Resume workers only
after the affected GitHub hostname presents a valid chain again.

The current Docker socket mount gives CI jobs control of the host Docker
daemon. Treat it as an interim compatibility seam: keep workflow permissions
minimal and move the runner pool to a dedicated host or isolated Docker daemon
before considering the fleet fully hardened.

## Verifying

After the runner restarts, dispatch the probe workflow at
`a14a-org/cantrip/.github/workflows/runner-probe.yml` (or any private repo
with that workflow) — it prints versions of every tool.
