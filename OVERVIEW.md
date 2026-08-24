# martevi — project overview

*A three-minute read. `README.md` (once one exists) will be the manual;
`STEERING.md` is the rules; this is the vision.*

This is the production build of the product prototyped in the sibling
`salas/` repo. Everything below describing the product itself is carried
over unchanged from `salas/OVERVIEW.md` — the idea, the problem, the four
things worth keeping — because none of that changed when the stack did.
What's marked **built here** vs. **proven in the prototype** is the part
that's new to this document.

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

## What's proven, what's built here

**Six screens, proven in the prototype, not yet built here.** Home, Atrium,
Museum, Room, Detail, Tours — plus Search and Artist for the fictional
museum. `salas/salas.html` + `app.js` is a fully working, no-build
implementation of all of them; `salas/platform/frontend` is an earlier,
partial Angular port of the same six screens (superseded — this repo is
React instead). Neither is what ships; both are references for exactly how
each screen should look and behave once it's rebuilt here.

**Five museums, proven.** Four real ones, browsable because they publish an
open API: The Met, the Art Institute of Chicago, Harvard Art Museums, the
Rijksmuseum. The fifth, fictional *Museu SALAS*, runs on the Smithsonian
Open Access API — eleven million CC0 records across twenty-one units, with
real photographs, entered by search rather than a department tree.

**Built here so far: the frontend scaffold and its theme.** React +
TypeScript on Vite, MUI as the component library, and `frontend/src/theme.ts`
implementing the full "paper and ink" design system (see `STYLE.md`) as an
MUI theme — palette, type scale, one shared easing curve, hairline-flavored
overrides on the components MUI would otherwise render with Material's
elevation/shadow language. No routing or screens yet.

**Not started: the backend.** `salas/platform/backend` sketches a NestJS
shape — an abstract `MuseumProvider`, five concrete adapters, a caching
layer — that answers the prototype's biggest real gap (API keys client-side,
no way to blunt the Smithsonian `DEMO_KEY` throttle). Worth reusing as a
starting point.

## The four ideas worth keeping

**1 · True scale.** Every work carries height × width in cm; wall size
follows directly, never normalised, nothing cropped.

**2 · A mascot that is nobody.** A single-contour silhouette — one circle for
a head, one line for everything else. No face, no hair, no gender or skin
markers. It gives scale and life to the room without representing any
particular visitor.

**3 · Photograph → drawing.** The prototype's building sketches come from a
generator (`salas/gerar_predio.py`) that separates sky from architecture by
local standard deviation, then squares up the roofline and snaps interior
lines onto shared axes. Not yet ported here; still worth understanding
before rebuilding the atrium cards.

**4 · One adapter, many providers.** Everything provider-specific stays
behind a single boundary. Changing collections should mean rewriting one
normalizer function, never touching a view or a component.

## Open questions

Carried over from the prototype, still open:

- **EDAN dimensions are free text**, format varies by unit — how many works
  quietly fall through to "não informado" once real traffic hits it?
- **EDAN has no artist records** — is an assembled artist page honest enough,
  or should that tab go, here?
- Are the **30 tour links** better as a list, or should the strongest few be
  promoted onto the home page?
- Does the fictional museum stay fictional, or become the front door once a
  real search backend is wired up here?

New, specific to this build:

- How much of `salas/platform/backend`'s NestJS sketch gets reused vs.
  redesigned once real requirements (auth, caching strategy, deployment
  target) are settled?
- What's the actual component/screen breakdown for the React port — does it
  mirror the prototype's file layout, or does MUI's component model suggest
  a different split?

## Files

```
STEERING.md        rules and settled decisions
OVERVIEW.md         this file
STYLE.md            the design system, in full — colors, type, motion, shape
frontend/           React + TypeScript + MUI, Vite. Scaffold + theme only so far
backend/            not started
```

```
../salas/                  the working prototype — sibling repo, same family
  salas.html, app.js       vanilla JS, no build — full six-screen implementation
  platform/frontend/       earlier Angular attempt at this same rewrite (superseded)
  platform/backend/        NestJS sketch — starting point for backend/ here
```

*Interface copy is Brazilian Portuguese; code and documentation are English.*
