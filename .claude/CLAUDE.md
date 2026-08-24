# martevi — devops steering

Companion to `STEERING.md` (product rules) and `STYLE.md` (design system),
both alongside this file in `.claude/`. This file covers infrastructure: how
the three repos relate, how to run things locally, and what CI expects.
Read it before touching `docker-compose.yml`, any `Dockerfile`, or a
`.github/workflows/*.yml`.

**Convention: steering stays out of everyone else's way.** Nothing outside
`.claude/` — no README, no source comment, no CI file, no Dockerfile —
should reference `OVERVIEW.md`, `STEERING.md`, `STYLE.md`, or this file by
path. `.claude/` is treated as local-only and shouldn't become something a
README or a build step depends on. If you're tempted to add "see
`.claude/STEERING.md`" to a README, don't — steering docs may reference
non-steering files freely, but not the other way around.

---

## Repo structure

Three repos, not one monorepo:

- **`martevi/`** (this one) — orchestration only. `docker-compose.yml`,
  `.env.example`, `Makefile`, and — under `.claude/` — this steering doc
  plus the product docs (`OVERVIEW.md`, `STEERING.md`, `STYLE.md`). No
  application code.
- **`backend/`** — FastAPI, own repo. The actual Python project (per
  fastapi-gen's scaffold) lives one level down at `backend/martevi/`
  (`pyproject.toml`, `main.py`). The importable `martevi` package itself
  lives one level further, at `backend/martevi/src/martevi/` (src-layout).
  That nesting is intentional, not a bug — don't try to flatten it without
  updating `pyproject.toml`'s `packages` setting, the Dockerfile, the CI
  workflow, and this doc together.
- **`frontend/`** — React + TypeScript + Vite + MUI, own repo, repo root is
  the project root (no extra nesting).

**Current state (as of the initial devops setup): local-only.**
`backend/` and `frontend/` are `git init`'d but have no remotes yet, and
`martevi/`'s `.gitignore` excludes both paths so the parent repo doesn't
try to track them as embedded content. There is no `.gitmodules`. The root
`README.md`'s **Submodules** section has the exact steps for wiring them up
for real once each has a remote — do that migration there, not by
improvising a different structure here.

Don't add backend/frontend code to git tracking *inside* the martevi repo.
If you need to reference something from one repo while working in another,
read it off disk — don't copy files across the boundary.

---

## Running things locally

Preferred path — Docker Compose, from `martevi/`:

```bash
cp .env.example .env   # once
docker compose up --build
```

This builds both services with their `dev` Docker target (reload/HMR) and
bind-mounts source for live editing. `make up` / `make down` / `make logs`
wrap the common commands (see the root `Makefile`).

Native path — each service's own README documents running it directly
(`backend/README.md`: `fastapi dev main.py`; `frontend/README.md`:
`npm run dev`). Prefer this when iterating fast on one service and you
don't need the other running.

**Ports:** backend `8000`, frontend `5173` — overridable via `BACKEND_PORT`
/ `FRONTEND_PORT` in `.env`. Backend docs/entrypoints:
http://127.0.0.1:8000/docs.

**Env vars** live in `.env` (git-ignored), templated by `.env.example` at
the repo root — not duplicated per-service. Add a new var there first, with
a comment explaining what reads it, before wiring it into a service.

---

## Docker

Both `backend/Dockerfile` and `frontend/Dockerfile` are multi-stage with a
`dev` target (what `docker-compose.yml` builds) and a `production` target
(locked/non-editable install, no reload, meant for an actual deploy —
there's no deploy target configured yet, this is just the image). Build
either explicitly with `docker build --target <dev|production> ...`; see
each service's README for the exact commands.

When changing a Dockerfile: keep the `dev`/`production` split. Don't
collapse them into one target "for simplicity" — the dev target needs
`pip install -e` / bind mounts and reload, the production target needs a
locked install and a non-root user, and conflating them tends to leak dev
conveniences (reload, editable installs) into what would ship.

---

## CI

Each of the three repos owns its own `.github/workflows/ci.yml`:

- **backend**: ruff, mypy (non-blocking for now — tighten once there's real
  coverage), pytest, then a `production`-target Docker build.
- **frontend**: oxlint, `npm run build` (which runs `tsc -b` first), then a
  `production`-target Docker build.
- **martevi** (this repo): doesn't re-run either service's suite — it only
  checks that the two fit together: `docker compose config` validates the
  compose file, `docker compose build` builds both images, then the stack
  comes up and the backend answers on `/docs`.

If you add a new CI check, put it in the repo that owns the thing being
checked. The martevi-level workflow should stay an integration smoke test,
not grow into a third copy of lint/test.

---

## Adding a new piece of infrastructure

A few things flagged as "not yet" during the initial setup — don't assume
they're wired up just because the words appear elsewhere in these docs:

- **No database.** SQLAlchemy + Alembic are backend dependencies (installed
  by fastapi-gen) but there's no DB service in `docker-compose.yml`, no
  `alembic.ini`, no migrations. When this lands, add a `db` service to
  compose, a `DATABASE_URL` to `.env.example`, and document the migration
  workflow here.
- **No museum-provider API keys wired up.** `.env.example` has commented
  placeholders (`SMITHSONIAN_API_KEY` etc., see `STEERING.md`'s "known
  risks" for why the Smithsonian one matters) but nothing reads them yet.
- **No deploy target.** Docker images build; nothing pushes them anywhere
  or runs them in production. Don't add a deploy workflow without deciding
  target infra first — that's a bigger decision than this doc should make
  unilaterally.
