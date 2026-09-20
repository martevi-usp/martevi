---
topic: security
load: on-demand
generated: 2026-09-13
verified: 2026-09-20
---
# Security steering

Covers what `.claude/CLAUDE.md` doesn't: the submodule access model, where
secrets live, and the non-root setup in each Dockerfile's `production`
target. (Which env vars exist and what reads them is in CLAUDE.md's
"Infrastructure that exists" section; it isn't restated here.)

## Rules
- Submodule access is SSH-keyed, not token/HTTPS-based: both remotes in
  `.gitmodules` are `git@github.com:martevi-usp/{backend,frontend}.git`.
  Anyone — or any CI runner — without an SSH key authorized for the
  `martevi-usp` org cannot `git submodule update --init` these.
- The root CI workflow assumes that SSH access may be absent and is
  written to degrade gracefully rather than require or expose a deploy
  key: it treats submodule-init failure as a warning and skips the rest
  of the job (`.github/workflows/ci.yml`, "Initialize submodules" step)
  instead of failing. Don't "fix" this by hard-requiring submodules in
  that workflow without first provisioning a deploy key/secret for the
  runner — that's a decision bigger than this workflow should make alone.
- **Secrets never enter git.** `.env` and `.env.*` are git-ignored except
  `.env.example`, which holds names and placeholders only. In deployed
  environments the museum API keys and the Cloudflare credentials live in
  the owning repo's GitHub secrets (in its `production` environment), and
  the backend's keys reach Cloud Run as environment variables.
- **Deploys use scoped credentials.** The backend authenticates to Google
  Cloud with Workload Identity Federation — no long-lived key is stored, and
  the provider trusts only the backend repository. The frontend uses a
  Cloudflare API token limited to editing Workers on the one account that
  owns the site. Deploy workflows request only the permissions they need
  (`backend/.github/workflows/deploy.yml`,
  `frontend/.github/workflows/deploy.yml`). Neither service's deploy needs
  anything from this repo.
- `backend`'s `production` Docker target drops root explicitly:
  `useradd --create-home --uid 1000 appuser` then `USER appuser` before
  the app starts (`backend/Dockerfile`). The `dev` target has no such
  step and runs as root — fine for local bind-mounted dev, but the `dev`
  image should never be the one that gets deployed anywhere. The
  translation models and the SQLite file are made world-readable at build
  time so the non-root user can read them.
- `frontend`'s `production` target has no explicit `USER` directive of
  its own — it relies on the `nginx:1.27-alpine` base image's default
  behavior (master starts as root, workers run as the image's own
  `nginx` user) rather than a project-specific non-root user like
  backend's (`frontend/Dockerfile`). If this base image is ever swapped,
  re-check that the non-root behavior still holds; it isn't guaranteed by
  anything in this repo's own Dockerfile. (That image isn't what is
  deployed — the frontend ships as static assets — but CI builds it.)
- The read-only content database is opened with `mode=ro`, so a request can
  never modify it. The wall-note endpoint's progress check is a courtesy
  against casual spoilers, not access control: there is no authentication,
  and the client reports its own progress.
