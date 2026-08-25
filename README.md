# martevi

A collection of virtual museums — artworks from open collection APIs, shown
at true physical scale.

This is the orchestration repo: it doesn't contain application code itself,
just what wires `backend/` and `frontend/` together for local dev
(`docker-compose.yml`).

## Repo layout

```
martevi/            this repo — orchestration only, no app code
  backend/           FastAPI service — own git repo (see backend/README.md)
  frontend/          React + TS + Vite + MUI — own git repo (see frontend/README.md)
  docker-compose.yml  wires backend + frontend together for local dev
```

`backend/` and `frontend/` are real git submodules of this repo — see
**Submodules** below for how to clone and update them.

## Quickstart

```bash
cp .env.example .env
docker compose up --build
```

- Backend: http://127.0.0.1:8000 — interactive docs at
  http://127.0.0.1:8000/docs
- Frontend: http://127.0.0.1:5173

Or run each service natively without Docker — see `backend/README.md` and
`frontend/README.md`.

A `Makefile` wraps the common commands: `make up`, `make down`, `make logs`,
`make backend-shell`, `make frontend-shell`, `make test`,
`make submodules-update`.

## Submodules

`backend/` and `frontend/` are real git submodules, tracked via
`.gitmodules`:

```
backend  -> git@github.com:martevi-usp/backend.git
frontend -> git@github.com:martevi-usp/frontend.git
```

Clone the whole project with:

```bash
git clone --recurse-submodules <martevi-url>
```

If you already have a clone without submodules initialized:

```bash
git submodule update --init --recursive
```

To pull each submodule's `main` branch to its latest commit, use
`make submodules-update` (wraps `git submodule update --init --remote
--merge`). Submodule pointers only move in the parent repo when you commit
the resulting change under `backend`/`frontend` in `git status` — running
the make target alone doesn't commit anything.

## CI

Each repo lints/tests/builds itself independently
(`backend/.github/workflows/ci.yml`, `frontend/.github/workflows/ci.yml`).
This repo's `.github/workflows/ci.yml` only checks that the two fit
together — compose file validity, both images build, the stack comes up and
answers on `/docs`.
