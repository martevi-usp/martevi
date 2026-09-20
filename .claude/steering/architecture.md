---
topic: architecture
load: on-demand
generated: 2026-09-13
verified: 2026-09-20
---
# Architecture steering

The repo/module map, the three-repo split, and the `backend/src/martevi`
nesting are already covered in `.claude/CLAUDE.md`'s "Repo structure" —
read that first; it isn't restated here. This file only adds what that
doc doesn't: dependency direction and mount layout at the orchestration
layer.

## Rules
- Dependency direction is one-way, declared entirely in
  `docker-compose.yml`: `frontend` has `depends_on: [backend]` and is
  given `VITE_API_URL` pointing at the backend; `backend` has no
  `depends_on` and no knowledge of the frontend at all
  (`docker-compose.yml`). Don't add a reverse dependency (e.g. backend
  reading a frontend-owned env var, or backend's compose service
  depending on frontend) without a specific reason — nothing in this
  repo currently needs it. (The one place the backend learns about the
  frontend is its `CORS_ORIGINS` allow-list, which is configuration, not
  a dependency.)
- Each service's build context and bind-mount target mirror its own
  internal layout, not a shared convention: `backend` builds from
  `./backend` and mounts `./backend/src:/app` (because its Python project
  root is one level down — see CLAUDE.md's nesting note); `frontend`
  builds from `./frontend` and mounts the whole `./frontend:/app` plus an
  anonymous `/app/node_modules` volume (because its repo root is already
  the project root) (`docker-compose.yml`). When wiring up a third
  service, derive its mount target from where *that* service's own
  project root is — don't copy one of these two mappings verbatim.
- Anything a service builds into its image and needs at runtime must not
  live under its bind-mount target, or the dev mount shadows it. The
  backend's SQLite file is built to `/opt/martevi/martevi.db` rather than
  under `/app` for exactly this reason (`backend/Dockerfile`, backend
  ADR-0004).

Architecture decisions for each service are recorded as ADRs in that
service's own repo (`backend/docs/adr/`, `frontend/docs/adr/`). This repo
has none of its own, and no application code whose import rules would need
documenting.
