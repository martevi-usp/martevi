# martevi — devops steering

Companion to `STEERING.md` (product rules) and `STYLE.md` (design system),
both alongside this file in `.claude/`. This file covers infrastructure: how
the three repos relate, how to run things locally, and what CI expects.
Read it before touching `docker-compose.yml`, any `Dockerfile`, or a
`.github/workflows/*.yml`.

**Convention: steering stays out of everyone else's way.** Nothing outside
`.claude/` — no README, no source comment, no CI file, no Dockerfile —
should reference `OVERVIEW.md`, `STEERING.md`, `STYLE.md`, or this file by
path. These docs guide contributors and coding agents; they shouldn't become
something a README or a build step depends on. If you're tempted to add "see
`.claude/STEERING.md`" to a README, don't — steering docs may reference
non-steering files freely, but not the other way around. The reverse also
holds: these docs describe only what is inside this repository (including
`backend/` and `frontend/`), never a tool, path or document that lives on
someone's machine.

---

## More steering docs (on-demand)

A few narrower topics live under `.claude/steering/` instead of in this
file, since they only matter for specific edits — read the relevant one
before you touch that area, don't load all of them by default:

- Bumping/moving submodule pointers, or writing a commit message here:
  `.claude/steering/git-workflow.md`
- Changing `docker-compose.yml`'s service wiring (`depends_on`, build
  contexts, mount targets): `.claude/steering/architecture.md`
- Changing the smoke test in `.github/workflows/ci.yml` or the Makefile's
  `test` / `test-docker` targets: `.claude/steering/testing.md`
- Touching submodule remotes/credentials, or a Dockerfile's non-root
  user setup: `.claude/steering/security.md`

---

## Repo structure

Three repos, not one monorepo:

- **`martevi/`** (this one) — orchestration only. `docker-compose.yml`,
  `.env.example`, `Makefile`, and — under `.claude/` — this steering doc
  plus the product docs (`OVERVIEW.md`, `STEERING.md`, `STYLE.md`). No
  application code.
- **`backend/`** — FastAPI, own repo. The actual Python project lives one
  level down at `backend/src/` (`pyproject.toml`, `main.py`). The importable
  `martevi` package itself lives one level further, at
  `backend/src/martevi/` (src-layout).
  That nesting is intentional, not a bug — don't try to flatten it without
  updating `pyproject.toml`'s `packages` setting, the Dockerfile, the CI
  workflow, and this doc together.
- **`frontend/`** — React + TypeScript + Vite + MUI, own repo, repo root is
  the project root (no extra nesting).

**Current state: wired up as real git submodules.** `backend/` and
`frontend/` each have a GitHub remote and are tracked via `.gitmodules`;
`martevi/`'s `.gitignore` no longer excludes them. Clone with
`git clone --recurse-submodules`, and use `make submodules-update` to pull
each submodule's `main` to its latest commit. The root `README.md`'s
**Submodules** section has the details.

**Submodule pointers always point at each submodule's `main`.** A commit in
this repo that records a `backend` or `frontend` commit not on that repo's
`main` leaves anyone cloning it with a broken submodule, so bump the pointers
only after the change is merged there (details in
`.claude/steering/git-workflow.md`).

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
(locked/non-editable install, no reload, no bind mounts). Build either
explicitly with `docker build --target <dev|production> ...`; see each
service's README for the exact commands. The backend's `production` image is
what gets deployed (to Google Cloud Run). The frontend is deployed as static
assets from its own build, so its `production` nginx image is built by CI but
not what runs in production.

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

Each of `backend/` and `frontend/` also owns a `deploy.yml` workflow that
deploys after its CI passes on `main` (backend to Google Cloud Run, frontend
to Cloudflare Workers); their setup is documented in each repo's README
(`backend/deploy/cloud-run/README.md`, `frontend/README.md`). This repo has no
deploy workflow.

If you add a new CI check, put it in the repo that owns the thing being
checked. The martevi-level workflow should stay an integration smoke test,
not grow into a third copy of lint/test.

---

## Infrastructure that exists, and what doesn't

Don't assume something is wired up just because a word appears elsewhere in
these docs:

- **Database: a read-only SQLite file, not a service.** The backend builds
  `martevi.db` into its image at build time (puzzles, wall notes, tour links;
  backend ADR-0004) and opens it read-only. There is no `db` service in
  `docker-compose.yml`, no ORM and no migrations — SQLAlchemy and Alembic were
  removed. The backend reads the optional `MARTEVI_DB_PATH` to point at a
  different file. `.env.example` still has a commented `DATABASE_URL`
  placeholder from before this; nothing reads it.
- **Museum-provider API keys are read, but optional.** The backend reads
  `HARVARD_API_KEY` (Harvard's requests fail without it) and
  `SMITHSONIAN_API_KEY` (falls back to the throttled shared `DEMO_KEY`); see
  `STEERING.md`'s "known risks". `docker-compose.yml` passes `.env` to the
  backend, so setting them there is enough for local runs.
- **`CORS_ORIGINS`** (backend) lists the origins allowed to call the API from
  a browser; it defaults to the two local Vite origins.
- **Deploy targets are decided; this repo deploys nothing.** Backend on
  Google Cloud Run, frontend on Cloudflare Workers static assets (backend
  ADR-0006). Each of `backend/` and `frontend/` deploys itself; there is no
  deploy workflow here, and don't add one — deployment belongs to the repo
  that owns the thing being deployed.

---

## Commands (run these yourself; never ask the human to)

This repo has no app code of its own — "commands" here means the
orchestration-level ones. `backend/` and `frontend/` each document their
own lint/typecheck/test commands in their own repos; don't duplicate those
here.

- Setup: `cp .env.example .env` (once)
- Fast check (run after touching `docker-compose.yml`, a `Dockerfile`, or
  a workflow): `make test` (backend pytest + frontend lint/tsc, native,
  no Docker)
- Boundary suite (the contract for *this* repo): `docker compose config`
  (compose file validates) && `docker compose build` (both images build)
  && `make up` then confirm `http://127.0.0.1:8000/docs` answers — this is
  exactly what the martevi-level CI workflow checks
- Full stack locally: `make up` (or `docker compose up --build`). UI
  check: open `http://127.0.0.1:5173` (frontend) and
  `http://127.0.0.1:8000/docs` (backend)

## How we work

- Intent first: if a task has no acceptance criteria, write them
  (behavior, edge cases, verify commands) before coding. Ask only about
  durable decisions: compose/Dockerfile contracts, CI ownership boundaries
  between the three repos, env var additions.
- Self-validate: run the fast check above after each change and loop
  until green. Report done only with passing output.
- Boundaries: no production access (deploys are owned by each service's own
  workflow — see "Infrastructure that exists" above), no credential files, no
  force-push, no publishing. Stop and ask before any irreversible action.
- When done with a substantial task, summarize it: outcome, checks run,
  decisions made, what was left out, and what needs human judgment.

## Module map

- `docker-compose.yml` — wires backend + frontend `dev` targets together;
  must not itself contain application logic
- `Makefile` — thin wrapper over `docker compose` / native test commands;
  must not grow business logic
- `.env.example` — the only place new env vars get declared for this repo;
  see "Env vars" above
- `.claude/` — these steering docs; nothing else depends on them
- `backend/`, `frontend/` — git submodules, each own their own module map;
  read their READMEs rather than duplicating this here
