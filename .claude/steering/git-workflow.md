---
topic: git-workflow
load: on-demand
generated: 2026-09-13
verified: 2026-09-20
---
# Git workflow steering

This repo's history is mostly submodule-pointer bumps and infra commits —
the mechanics of moving those pointers correctly matter more here than
typical app commit hygiene.

## Rules
- **Submodule pointers always point at the submodule's `main`.** A commit
  here that records a `backend` or `frontend` commit which is not on that
  repo's `main` leaves anyone cloning with a submodule they cannot check
  out. Merge the change in the submodule first, then bump the pointer.
  Before committing a bump, check that the recorded commit is reachable
  from the submodule's `origin/main`
  (`git -C backend merge-base --is-ancestor <sha> origin/main`).
- A pointer only moves in this repo when the resulting change under
  `backend`/`frontend` is committed — `make submodules-update` alone does
  not commit anything, it only updates the working tree/index. Your own
  `git status` showing `backend`/`frontend` as modified just means a
  submodule is checked out at a commit other than the recorded one, for
  example while you develop on a feature branch there; don't stage that.
- Several bumps between pushes are noise: squash them into one bump that
  records the final `main` tips. Squash only local, unpushed commits.
- After editing `.gitmodules` (e.g. changing a submodule URL), run
  `git submodule sync` to update `.git/config` — the local git config can
  silently keep the old URL otherwise.
- Submodule remotes are SSH (`git@github.com:...`), not HTTPS/token-based
  — cloning or updating requires a working SSH key with access to the
  `martevi-usp` org (`.gitmodules`).
- Commit messages use `type: description` (conventional-commit style,
  lowercase type, no scope) — e.g. `chore: update frontend submodule
  reference`, `docs: document museum provider API keys in .env.example`.
  Earlier commits with a plain capitalised imperative subject predate the
  convention and are not a pattern to match.

## Commands
- `git submodule update --init --recursive` — first-time submodule init
  after a plain clone (`README.md`).
- `make submodules-update` (wraps `git submodule update --init --remote
  --merge`) — pull each submodule's `main` to latest; still requires a
  manual `git add backend frontend && git commit` afterward to record the
  new pointers (`Makefile`, `README.md`).
- `git submodule sync` — run after changing a URL in `.gitmodules`, before
  the next update/clone.
