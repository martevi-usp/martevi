# martevi — project overview

*A three-minute read. `README.md` is the manual; `STEERING.md` is the rules;
this is the vision. The "what exists" section describes the state as of
2026-09-20, including backend decisions 0001–0006 in `backend/docs/adr/`.*

---

## In one paragraph

martevi is a collection of virtual museums. It pulls artworks from museums
that publish an open collection API, puts each one on a wall **at its real
physical size**, and stands a 1.72 m figure next to it so the size is legible
without reading a number. Around the artwork sit the things a gallery gives
you and a search result doesn't: the record, the provenance, a wall note,
and a loupe to get close to the surface.

## The problem it answers

Most of what is called art history sits in half a dozen cities in the
northern hemisphere. Seeing it depends on a plane ticket, a visa and a week
off. And when you do look it up online, every work arrives the same size:
*The Lacemaker* (24 cm) and *The Night Watch* (3.8 m) render as identical
rectangles on a screen. The scale — which is most of what a painting *is* in
a room — is the first thing the internet throws away.

## What exists, what's planned

**Backend — built.** A FastAPI service. One `MuseumProvider` interface with
seven adapters (The Met, Art Institute of Chicago, Cleveland Museum of Art,
Harvard Art Museums, Rijksmuseum, Smithsonian Open Access, Victoria and
Albert Museum), each converting that museum's response shape to martevi's
common schema; a DI-based registry that selects providers at runtime; a
`TranslatingProvider` decorator so provider text reaches the frontend already
in Portuguese, using offline Argos Translate; and fan-out search across every
museum, as one JSON response or streamed over SSE as each museum answers,
with a per-museum status when one fails. Editorial content no museum API
provides — 24 puzzles with their wall notes and 36 virtual-tour links — lives
in a read-only SQLite file built into the image. `GET /health` is the
liveness probe. Decisions and their reasoning: `backend/docs/adr/`.

**Frontend — built so far.** React + TypeScript on Vite, MUI as the component
library, and `frontend/src/theme.ts` implementing the full "paper and ink"
design system (see `STYLE.md`) as an MUI theme. Two screens, chosen by the
URL hash: a placeholder home page, and the jigsaw puzzle — pick an artwork,
reassemble it, and finishing unlocks a wall note about it. The puzzle's
catalog and notes come from the backend. Opening the app also pings the
backend so a sleeping free-tier host wakes early.

**Deployed.** Backend on Google Cloud Run, frontend as static assets on
Cloudflare Workers (`backend/docs/adr/0006-deploy-cloud-run-and-static-frontend.md`).

**Planned, not built: the museum experience.** Six screens — Home, Atrium,
Museum, Room, Detail, Tours — plus Search and Artist for the fictional museum
below; the 3D room, the mascot and the loupe. The backend already serves what
most of them need (search, artwork detail, tour links); the frontend does not
yet.

**The museums.** Real ones, browsable because they publish an open API (the
seven adapters above). Planned on top of the Smithsonian Open Access API is a
fictional museum, *Museu SALAS*: CC0 records with real photographs, entered by
search rather than a department tree.

## The four ideas worth keeping

**1 · True scale.** Every work carries height × width in cm; wall size
follows directly, never normalised, nothing cropped.

**2 · A mascot that is nobody.** A single-contour silhouette — one circle for
a head, one line for everything else. No face, no hair, no gender or skin
markers. It gives scale and life to the room without representing any
particular visitor.

**3 · Photograph → drawing.** The atrium's building sketches are meant to be
generated from photographs: separate sky from architecture by local standard
deviation, then square up the roofline and snap interior lines onto shared
axes. Not built yet.

**4 · One adapter, many providers.** Everything provider-specific stays
behind a single boundary. Changing collections should mean rewriting one
normalizer function, never touching a view or a component.

## Open questions

- **Smithsonian (EDAN) dimensions are free text**, format varies by unit — how
  many works quietly fall through to "não informado" once real traffic hits
  it?
- **EDAN has no artist records** — is an assembled artist page honest enough,
  or should that tab go?
- Are the **36 tour links** better as a list, or should the strongest few be
  promoted onto the home page?
- Does the fictional museum stay fictional, or become the front door once its
  search is wired up?
- Should wall notes unlock progressively while a puzzle is being solved, or
  only on completion? The backend supports both (`unlock_pct`); the frontend
  does completion only (`frontend/docs/adr/0005-puzzle-content-from-api.md`).
- What's the component/screen breakdown for the remaining screens — one page
  per screen with shared room state, or something MUI's component model
  suggests?
- A cross-museum search takes roughly 12 to 24 seconds on the free tier's one
  vCPU (12.5 s measured on the deployed service, 19–24 s locally; translation
  dominates). Is that acceptable for the demo, or is the extra cost of a
  second vCPU, or of pre-translating titles, worth paying?

## Files

```
.claude/
  CLAUDE.md          how the three repos fit together: running, Docker, CI
  STEERING.md        product rules and settled decisions
  STYLE.md           the design system, in full — colors, type, motion, shape
  OVERVIEW.md        this file
  steering/          narrower topics, read on demand
frontend/           React + TypeScript + MUI, Vite — the puzzle, home, theme
backend/            FastAPI — providers, translation, search, curated content
```

*Interface copy is Brazilian Portuguese; code and documentation are English.*
