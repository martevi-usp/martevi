# martevi — steering

Read this before changing anything. It is the short version of decisions
already made, so they don't get re-litigated by accident.

Decisions with a longer reasoning live as ADRs in `backend/docs/adr/` and
`frontend/docs/adr/`; this file only carries the rules those imply. The visual
system is captured here and, in full, in `STYLE.md`.

---

## What this is

A collection of virtual museums. Artworks from open collection APIs, shown at
**true physical scale** in a 3D room, with the record and a loupe next to them.

**Who it's for, in order:** someone who can't board a plane to see a Vermeer;
a teacher with no field-trip budget; anyone who wants to look slowly.

**The one idea everything serves:** a reproduction flattens every work to the
same size. martevi gives the size back. If a change weakens that, it's the
wrong change.

---

## Non-negotiables

1. **True scale.** Wall size comes from real cm × a px/cm scale factor. Never
   normalise artworks to a common height. A 24 cm Vermeer *should* look tiny.
2. **Never crop, never stretch.** Every thumbnail box is sized from the work's
   own aspect ratio. No `object-fit: cover` on a box that isn't already the
   right shape.
3. **Missing data stays visible.** When the API returns no dimension, the record
   says *"não informado pela API"*. Do not hide the field, do not invent a value.
4. **The mascot is neutral by construction.** No face, no hair, no gender or
   skin markers. One contour, one colour. If a pose needs a facial expression to
   read, it's the wrong pose.
5. **UI copy is pt-BR. Code, comments and docs are English.** Don't mix.

---

## Voice

Plain, concrete, unsentimental. Specific over grand: *"a pincelada ficou à
mostra no tecido e sumiu na pele"* beats *"a magia da arte"*. Never sell — state
the fact and let it land. Roughly 45–75 words per block; if one section runs
double the others, cut it, don't grow the rest.

---

## Design system

```
paper #F4F1EA   ink #17130E   ink-2 #4A4238   ink-3 #8C8375
accent #A8442A (terracotta)   accent-2 #C98A3E
hairline rgba(23,19,14,.16)
serif  Instrument Serif   sans Inter 300
```

Structure is made of **rules**, not boxes or shadows, outside the room/stage/
loupe (which get their own dark, physical treatment — see `STYLE.md`). Section
heads are hairline underlines; the hero is a masthead with a double rule.
Motion is slow and eased (`cubic-bezier(.66,0,.25,1)`), and honours
`prefers-reduced-motion`. Corner rounding is unconstrained — MUI's defaults
apply; there is no house rule against it.

See **`STYLE.md`** for the full system — every color's semantic role, the
type scale, the dark exception zones, responsive breakpoints — and
`frontend/src/theme.ts` for where it's actually implemented as an MUI theme.
If a token value disagrees between the two, `STYLE.md` is right; fix the
theme. The non-negotiables above win over anything in either.

---

## Architecture

**`frontend/`** — React + TypeScript, scaffolded with Vite, MUI as the
component library. `src/theme.ts` carries the full design system as an MUI
theme. Two screens exist, chosen by the URL hash (`src/routes.ts`): a
placeholder home page and the jigsaw puzzle. The puzzle's logic is pure
functions in `src/components/` (geometry, rules); only `src/pages/` touches
React. Its catalog and wall notes come from the backend (`src/api/`), never
hardcoded.

**`backend/`** — FastAPI. An abstract `MuseumProvider` with seven adapters
(Met, Art Institute of Chicago, Cleveland, Harvard, Rijksmuseum, Smithsonian,
V&A), a DI-based registry, and a `TranslatingProvider` decorator that
translates provider text to Portuguese with offline Argos Translate.
Cross-museum search fans out to every provider and reports a per-provider
status, so one slow or failing museum never fails the request. Curated
content that no museum API provides (puzzles, wall notes, tour links) is a
read-only SQLite file built into the image — the application reads and never
writes.

**Screens, once built:** **home → atrium → museum → room → detail**, plus
**tours** and, for the fictional museum, **search → artist** — an eight-state
flow. Keep the room driven by one shared context/state shape, so a curated
section and a list of search results render through the same code path. Don't
let that collapse into two parallel code paths as the screens are built.

**All API-specific code lives behind one adapter**, in the backend. Swapping a
provider should mean rewriting one normalizer function and nothing else. If
provider details start leaking into components, stop and put them back.

**Hosting.** Backend on Google Cloud Run, frontend as static assets on
Cloudflare Workers, each deployed by its own repo's workflow
(`backend/docs/adr/0006-deploy-cloud-run-and-static-frontend.md`).

---

## Data rules

Museums are in the collection **only if they publish an open API** — that is
the whole reason the museums in the backend's registry are there. Museums with just a guided
walkthrough go on the tours page and link out. Don't blur the line.

Hand-typed demo records are **not facts**. Anything shown as a real artwork
comes from a museum's live endpoint; curated content (puzzle catalog, wall
notes, tour links) carries its own provenance — `rights`, and a `verified`
flag for images — and a record that hasn't been checked says so rather than
passing as authoritative.

---

## Settled — don't reopen

Each of these was tried both ways during design and one won. Re-open only if
you have a concrete reason the context has changed — not just a fresh
preference.

| Decision | Why |
|---|---|
| Atrium is a horizontal card rail | The full-bleed version was tried and rejected |
| Museum index is an accordion with artwork rails | An orbital-ring layout was built and rejected |
| Hero is a newspaper masthead | Centred block and 2-col grid both left a dead gutter |
| No pills, no circles as a *default* shape language | Off-brand for a site built out of hairlines — MUI's own defaults are the one deliberate exception now |
| Detail view: only the left column scrolls | The artwork must stay put while you read |
| Paintings are procedural SVG placeholders | Only where the API gives no image; prefer the real file and fall back |
| Results are a masonry grid, not aligned rows | Rows of aligned thumbs wasted the vertical space real photographs need |
| Search never crops | `object-fit:contain`; tile height comes from the file's own ratio |
| The room uses the object's own aspect ratio; the grid uses the file's | Two different ratios for two different jobs — don't collapse them into one field |

---

## Known risks

- **The Smithsonian `DEMO_KEY` is throttled**, to roughly 30 requests an hour
  per IP. The backend uses `SMITHSONIAN_API_KEY` when set and falls back to
  `DEMO_KEY`; a free key from api.data.gov lifts it to 1,000 an hour. Provider
  responses are not cached yet (only translations are), so a cache is the
  other half of the answer.
- **Harvard needs a key** (`HARVARD_API_KEY`, free, non-commercial signup);
  without it Harvard's requests fail and it shows up as a failed museum in the
  search's per-provider status, while the other museums still answer.
- **EDAN dimensions are free text**, and the format varies by unit. The
  backend's dimension parser (`backend/src/martevi/providers/_internal/dimensions.py`)
  covers the shapes seen so far and returns `None` for the rest — every new
  unit is a chance for it to be wrong; add a case to
  `backend/src/tests/test_dimensions.py` before trusting a new one.
- **EDAN has no artist records.** No biography, no birthplace, nothing. Any
  artist page is assembled from the makers named on artworks and must say so.
  Do not paper over that with invented copy.
- **Tour URLs are unverified.** Compiled from a São Paulo education
  department's list and Google Arts & Culture's Museum Views
  (`backend/db/seed/tours.toml`); museums retire these pages constantly.
  Re-check before relying on them.
- **Translation runs fully offline (Argos Translate, backend ADR-0002 and
  ADR-0005)** — no external service, no rate limit, no SLA to worry about. It
  replaced the first, network-backed translator after real fan-out traffic hit
  its unofficial 5 req/s ceiling. The trade-offs are local: about 80 MB of
  model per language pair on disk, roughly 800 MB resident on x86 with both
  loaded, and translation cost is CPU time instead of network latency.
  Swapping the engine again only touches the `Translator` implementation
  behind `TranslatingProvider`.
- **Content is read-only at runtime** (backend ADR-0004): changing a puzzle,
  wall note or tour link means editing the seed files and redeploying. The
  wall-note endpoint withholds text until told the puzzle is solved, but the
  client reports its own progress, so that is a courtesy against casual
  spoilers, not a guarantee.
- **Hosting is a free tier with limits** (backend ADR-0006): Google requires a
  billing account for Cloud Run's free quota, the backend sleeps when idle and
  wakes on the first request (the frontend pings `/health` on load to hide
  part of that), and one vCPU makes a cross-museum search take on the order of
  ten to twenty-five seconds.

---

## Building it

Both repos have unit tests (`pytest` in the backend, Vitest in the frontend);
see each repo's README. There is no browser-level suite. As
screens are built, add a harness that walks them under jsdom and one that
feeds the normalizers real API responses.

**Always verify visually.** The drawing and layout bugs worth naming — fused
legs on the mascot, a roofline like a barn, a masonry grid that reflowed under
the cursor — were found by rendering and looking, never by reading the code.
Screenshot new screens before calling them done.
