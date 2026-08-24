# martevi — steering

Read this before changing anything. It is the short version of decisions
already made, so they don't get re-litigated by accident.

This is the production build. The working reference is the vanilla-JS
prototype in the sibling `salas/` repo (`salas.html` + `app.js`) — it stays
the source of truth for the visual system and product decisions until a
screen is actually ported here. `salas/platform/frontend` also holds an
earlier Angular attempt at this same rewrite (abandoned in favor of React —
see below); its `room`/`mascot` port is worth reading before re-deriving
that logic from scratch, even though the framework changed.

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
apply; there is no house rule against it here (there was, in the prototype —
deliberately dropped for this build).

See **`STYLE.md`** for the full system — every color's semantic role, the
type scale, the dark exception zones, responsive breakpoints — and
`../frontend/src/theme.ts` for where it's actually implemented as an MUI theme.
If a value disagrees between the two, `STYLE.md` is right; fix the theme.

---

## Architecture

**`frontend/`** — React + TypeScript, scaffolded with Vite, MUI as the
component library. `src/theme.ts` carries the full design system as an MUI
theme (palette, typography, one shared easing curve, hairline-flavored
component overrides on `Paper`/`AppBar`/`Card`/`Button`). Nothing beyond the
scaffold and the theme exists yet — no routing, no screens.

**`backend/`** — not started. `salas/platform/backend` sketches a NestJS
shape worth reusing rather than redesigning from zero: an abstract
`MuseumProvider` with five concrete adapters (Met, Art Institute of Chicago,
Harvard, Rijksmuseum, Smithsonian), a DI-based registry, and a caching layer
that answers the prototype's own flagged gap — no backend meant API keys
client-side and no way to blunt the Smithsonian `DEMO_KEY` throttle.

**Screens, once built:** **home → atrium → museum → room → detail**, plus
**tours** and, for the fictional museum, **search → artist** — the same
eight-state flow as the prototype's `S.view` in `app.js`. Keep the room
driven by one shared context/state shape, so a curated section and a list of
search results render through the same code path — the way `S.ctx` does in
the prototype. Don't let that collapse back into two parallel code paths as
the port proceeds.

**All API-specific code lives behind one adapter**, wherever that lands
(most likely the backend, once one exists). Swapping a provider should mean
rewriting one normalizer function and nothing else. If provider details
start leaking into components, stop and put them back.

---

## Data rules

Museums are in the collection **only if they publish an open API** — that is
the whole reason the four curated ones are there. Museums with just a guided
walkthrough go on the tours page and link out. Don't blur the line.

The prototype's seed works (`ACERVO`, `FX_ROWS` in `salas/app.js`) are
**demo records, not facts** — hand-typed to give the prototype something to
draw. Don't port them in as if they were verified; go to the live endpoint.

---

## Settled — don't reopen

Carried over from the prototype, where each of these was tried both ways and
one won. Re-open only if you have a concrete reason the context has changed —
not just a fresh preference.

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
  per IP. A free personal key from api.data.gov lifts it to 1.000/hour; the
  backend's caching layer is the other half of the answer.
- **EDAN dimensions are free text**, and the format varies by unit. The
  prototype's `cmDe()` covers the shapes seen so far and returns `null` for
  the rest — every new unit is a chance for it to be wrong; add a test case
  before trusting a new one.
- **EDAN has no artist records.** No biography, no birthplace, nothing. Any
  artist page is assembled from the makers named on artworks and must say so.
  Do not paper over that with invented copy.
- **Tour URLs are unverified.** Compiled from a São Paulo education
  department's list; museums retire these pages constantly. Re-check before
  shipping.
- **The prototype's Harvard seed works are the least certain** of the four
  curated collections — don't treat them as fact when porting.

---

## Building it

There's no harness yet — write one as soon as there's a normalizer or a
screen worth regression-testing, the way `salas/tests/` does for the
prototype (`harness.mjs` boots the app under jsdom and walks every screen;
`live.mjs` feeds the normalizer real API responses).

**Always verify visually.** Every drawing/layout bug worth naming in the
prototype's own history — fused legs on the mascot, a roofline like a barn,
a masonry grid that reflowed under the cursor — was found by rendering and
looking, never by reading the code. Screenshot new screens before calling
them done.
