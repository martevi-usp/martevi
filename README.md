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

`backend/` and `frontend/` are meant to become real git submodules of this
repo once each has a remote to point at. Until then they're independent
local git repos that this repo's `.gitignore` deliberately excludes — see
**Submodules** below for the current state and how to graduate them.

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
`make backend-shell`, `make frontend-shell`, `make test`.

## Submodules

**Current state:** `backend/` and `frontend/` are each their own local git
repo (`git init`'d, not yet pushed anywhere). This repo's `.gitignore`
excludes both paths so the parent repo stays clean in the meantime —
there's no `.gitmodules` yet.

**Once each has a remote** (GitHub or otherwise):

```bash
# from a fresh clone of the remote, for each of backend/ and frontend/:
git remote add origin <url>
git push -u origin main

# back in martevi/, swap the .gitignore exclusion for a real submodule:
git rm -r --cached backend  # only if it was ever accidentally tracked; usually a no-op
rm -rf backend
git submodule add <backend-url> backend
# repeat for frontend

# then remove the /backend/ and /frontend/ lines from .gitignore
```

After that, clone the whole project with:

```bash
git clone --recurse-submodules <martevi-url>
```

and uncomment the `submodules: recursive` line in
`.github/workflows/ci.yml`.

## CI

Each repo lints/tests/builds itself independently
(`backend/.github/workflows/ci.yml`, `frontend/.github/workflows/ci.yml`).
This repo's `.github/workflows/ci.yml` only checks that the two fit
together — compose file validity, both images build, the stack comes up and
answers on `/docs`.
