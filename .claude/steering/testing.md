---
topic: testing
load: on-demand
generated: 2026-09-13
verified: 2026-09-20
---
# Testing steering

martevi (this repo) has no test suite of its own — "testing" here means
the integration smoke test that proves backend+frontend fit together,
plus the Makefile shortcuts that shell out to each submodule.

## Rules
- The only test this repo owns is the compose smoke test in
  `.github/workflows/ci.yml`: bring the stack up with `docker compose up
  -d`, then poll `http://localhost:${BACKEND_PORT:-8000}/docs` in a loop
  of up to 30 attempts, 2 seconds apart (60s max), before one more
  unretried `curl -sf` that actually fails the step if the loop never
  succeeded (`.github/workflows/ci.yml`, "Bring the stack up..." step). If
  backend startup time grows (e.g. slow init work added), this budget may
  need to grow with it.
- The smoke test tears the stack down unconditionally
  (`if: always() && steps.submodules.outputs.ready == 'true'`) with
  `docker compose down -v`, even if the polling loop never succeeded —
  check the "Bring the stack up and smoke-test it" step's own logs, not
  just the teardown step, when the job fails (`.github/workflows/ci.yml`).
- `make test` runs a fast native check of each submodule, back to back,
  from their own directories: `cd backend/src && pytest -q`, then `cd
  frontend && npm run lint && npx tsc -b --noEmit`. It does not touch
  Docker, and it does **not** run the frontend's unit tests — that is `npm
  test` in `frontend/` (`Makefile`).
- `make test-docker` runs the same checks but inside the already-running
  compose containers (`docker compose exec backend pytest -q`, etc.) —
  requires `make up` first; it's the containerized counterpart to
  `make test`, not an additional check (`Makefile`).
- CI treats missing submodules as a soft failure, not a hard one: if
  `git submodule update --init --recursive` fails (e.g. no SSH access to
  the private submodule repos, such as from a fork), the workflow emits
  `::warning::` and every later step (validate/build/up/smoke-test/
  teardown) is skipped via `if: steps.submodules.outputs.ready ==
  'true'` guards, rather than failing the job (`.github/workflows/ci.yml`,
  "Initialize submodules" step).

## Commands
- `make test` — fast native run of both, no Docker required.
- `make test-docker` — same checks, run inside containers; requires
  `make up` first.
- `docker compose config && docker compose build && docker compose up -d`
  — reproduce the CI smoke test locally, then poll
  `http://127.0.0.1:8000/docs` yourself.

## Where things go
- Actual test code lives in `backend/` and `frontend/` (own repos) — this
  repo only adds the cross-service smoke test in
  `.github/workflows/ci.yml`. A new integration-level check spanning both
  services belongs here; anything that tests one service in isolation
  belongs in that service's own repo/CI.
