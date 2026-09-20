# martevi — style steering

Companion to `STEERING.md`. That file has an eight-line summary of this;
this is the long version — read it before touching the theme, adding a
screen, or skinning a new component. This file is the reference for token
values and component styling; if it disagrees with the non-negotiables in
`STEERING.md`, those win and this file is out of date.

The name for the language is **paper and ink**: a printed page, not an app.
Structure comes from rules (literal horizontal/vertical lines) and hairline
borders, never from boxes, shadows, or color blocks — except inside the
three deliberately different zones (the 3D room, the artwork stage, the
loupe) where the site briefly becomes a dark gallery instead of a page.

This document describes the system in the abstract; **`frontend/src/theme.ts`**
is where it's actually implemented, as an MUI theme. Keep the two in sync: if
a value here and the same value in the theme drift apart, this document is the
one to trust — fix the theme.

---

## Color

```
paper    #F4F1EA   page ground
paper-2  #EBE6DB   recessed panels, MUI's default `background.paper`
paper-3  #DED8CA   placeholder art background, thumbnail voids, skeleton loaders
ink      #17130E   text, rules, filled buttons — MUI's `text.primary`
ink-2    #4A4238   body copy — never headings, never labels — MUI's `text.secondary`
ink-3    #8C8375   metadata, captions, eyebrows, disabled/quiet state — MUI's `text.disabled`
line     rgba(23,19,14,.16)   structural hairlines — MUI's `divider`
line-soft rgba(23,19,14,.08)  quieter dividers (list rows, table rows)
accent   #A8442A   terracotta — the one warm, saturated color — MUI's `primary.main`
accent-2 #C98A3E   ochre — accent's companion, used only on dark grounds — MUI's `secondary.main`
```

Five neutrals plus two warm accents. That's the whole palette for the paper
zones — no blues, no greens, no second cool color anywhere. If a new
component needs a color and it isn't one of these seven, the answer is
almost always "use accent less often," not "add an eighth token" — and
never reach for one of MUI's other default palette slots (`error`, `warning`,
`info`, `success`) to sneak an eighth color in; if a status color is
genuinely needed later, it has to earn its place in this document first.

**What each neutral is for.** Paper and its two darker steps are grounds,
never text. Ink is reserved for things that must read as maximum contrast:
running text on light backgrounds, headings, filled button backgrounds,
rules that carry real structural weight (masthead double rule, section-open
underline). Ink-2 is body copy exclusively — a paragraph, never a label.
Ink-3 is everything quiet: uppercase eyebrows, timestamps, counts,
placeholder italics, disabled affordances. Getting ink-2 and ink-3 backwards
is the most common regression — a label in ink-2 reads too heavy, body copy
in ink-3 reads too faint to commit to.

**What accent is for, and the discipline around it.** Terracotta marks the
one thing on a screen that is alive or actionable: an italic word inside a
serif headline, an active filter/tab, a hover state, a progress fill, an
"open" section head, a link. It is never a background for large areas and
never doubles up with itself competing for attention — a screen should have
one terracotta thing drawing the eye, not four. Ochre (accent-2) exists only
because pure terracotta loses contrast on the room's near-black grounds; it
never appears on paper.

**Selection and focus.** Text selection is accent on paper — inverted from
every other use of accent, and the only place accent is a fill on light.
Focus rings are a 2px solid accent outline, 3px offset; on dark grounds they
switch to accent-2 so they stay visible against near-black. Mouse-driven
focus never shows a ring — only keyboard/`:focus-visible`.

### The dark exception zones

Three places abandon paper-and-ink for a lit, physical darkness, because
they represent actual gallery spaces rather than the page around them.
These are lighting/material values, not palette tokens — they don't belong
in `theme.ts`'s `palette`, and they don't get reused outside their zone:

- **The room**: walls are cool grays (`#5E6...#9AA4AC` range) lit from one
  side, the floor is warm walnut (`#4B3B2D`/`#443527`) with a perspective
  vignette, the ceiling holds a sky well (`#DCEAF4→#93AABC`) and two black
  track rails.
- **The frame and loupe**: a gold gradient
  (`#C9A567 → #8E6E33 → #E4C98C → #8A6A31 → #C6A263`), brass rings
  (`rgba(196,164,102,.92)` / `rgba(120,94,48,.95)`) for the loupe rim. These
  read as *metal*, deliberately outside the seven-token palette.
- **The artwork stage**: a near-black radial vignette
  (`#2A2723 → #14120F`) so the art itself is the brightest thing in view.

If you're building a new screen, it belongs to paper-and-ink by default.
Only a real physical gallery space earns a dark exception, and it gets its
own local values, styled locally, rather than new theme tokens.

---

## Type

```
serif  "Instrument Serif","Times New Roman",Times,serif
sans   "Inter",-apple-system,BlinkMacSystemFont,"Helvetica Neue",Arial,sans-serif
```

Two families, used for two different jobs — never swap them:

- **Serif, weight 400, is for anything that speaks**: every heading, pull
  quotes/ledes, the wordmark, numerals that need to feel like a headline. In
  `theme.ts` this is `typography.h1`–`h6` (and `subtitle1`). Line-height runs
  tight — `.94` to `1.14` — because display serif at large sizes needs the
  lines to sit close. An emphasized word inside a serif heading is *always*
  italic *and* accent-colored — that pairing is the site's one recurring
  rhetorical device: the word that matters, italicized and colored, inside
  an otherwise plain sentence. Don't italicize without coloring it or color
  without italicizing it; the two go together everywhere they appear. (In
  JSX this isn't a bare `<em>` — style it explicitly with
  `color: 'primary.main'`, since a plain `<em>` inherits the surrounding
  text color.)
- **Sans, weight 300, is for everything else**: body copy, buttons, form
  fields, navigation, metadata — `typography.body1`/`body2`/`button` in
  `theme.ts`. Body weight is light (300) by design — this is not a bug to
  "fix" by bumping to 400; the light weight is what keeps large amounts of
  ink-2 text calm at 13–14px.

**Micro-labels are their own convention**, used dozens of times: 9.5–10.5px,
letter-spacing .14em to .24em, uppercase, always ink-3 unless it's an
active/selected state (accent or ink). This is the site's "eyebrow" pattern —
section labels, breadcrumbs, footer, button text, tags, unit filters, HUD
chrome. MUI's `overline` and `caption` variants are mapped to this pattern in
`theme.ts` — reach for those variants before inventing a one-off `sx` block
for new micro-label text.

**Sizing is fluid, not fixed.** Size headings with CSS `clamp(min, vw, max)`
rather than a fixed value or a breakpoint override.
MUI's theme typography doesn't have a native fluid-clamp mechanism, so when a
heading needs this (mastheads, hero numerals), set `fontSize` with an
explicit `clamp()` string in the component's `sx` rather than picking a
single fixed size — don't let the absence of a built-in fluid API become an
excuse to make every heading a fixed px value again.

---

## Space, structure, shape

**Rules, not boxes.** The masthead is a double rule (border-top +
border-bottom on a 4px bar). Section heads are a hairline underline. A
divider is a 1px line — the `divider` token for structural separators,
line-soft for quieter repeated ones (list rows) — essentially never a
box-shadow or a filled background pretending to be a card. `theme.ts`
already flattens `Paper`/`Card`/`AppBar` to `elevation: 0` with a 1px border
instead of a shadow; when a component needs a visual container, use one of
those rather than reaching for `boxShadow` directly.

**Two button styles, nothing else.** A filled button (ink background, paper
text, hovers to accent) for the primary action, an outlined one (ink
border/text, inverts to filled ink on hover) for secondary — in MUI terms,
`variant="contained" color="primary"` and `variant="outlined" color="primary"`,
both handled by the `MuiButton` override in `theme.ts`. Both share a 44px
min-height and the uppercase micro-label text treatment. Don't introduce a
third button visual language (ghost, tonal, icon-only) without a reason that
survives the "why not outlined?" question.

**Corner rounding is unconstrained.** There is no "nothing is rounded" rule.
MUI's default `shape.borderRadius` applies unless a specific component earns
an override — don't invent a blanket rule from memory.

**Motion is one curve.** `cubic-bezier(.66,0,.25,1)` — a slow start, fast
middle, gentle landing — is wired into `theme.transitions.easing` in
`theme.ts` (overriding `easeInOut`/`easeOut`/`easeIn`/`sharp` uniformly), so
MUI's own transition-driven components (`Fade`, `Collapse`, `Grow`) inherit
it for free. Durations run long — `.3s`–`.9s`, some builds/animations up to
`1.7s` — nothing on this site snaps; a
hand-rolled transition should land in that range rather than a UI-standard
150–200ms. Everything with a duration must keep working under
`prefers-reduced-motion` — MUI respects this by default for its own
transitions; verify any custom CSS animation does too.

---

## Responsive

Design for three breakpoints — roughly 1100px (detail-view column ratio),
860px (tablet), 640px (phone) — all adjusting layout rather than introducing
new visual language, plus a 640px+landscape case for the detail view
specifically. Map these onto MUI's breakpoint system (`sm`/`md`/`lg`) rather
than hand-rolling new pixel values; a 44px minimum touch target and
`prefers-reduced-motion` apply at every width. (The jigsaw puzzle is
self-contained and stacks its wall note below 900px, measured from its own
surface; that is its own layout rule, not one of these.)

---

## Applying this to something new

1. Pick colors only from the seven tokens above, at the semantic role they
   already carry (heading vs. body vs. metadata vs. accent-as-action) — via
   the theme (`theme.palette.*`), never a hard-coded hex in a component.
2. Pick type from the two families at their existing job split — serif for
   things that speak, sans-300 for everything functional — via
   `theme.typography` variants, sizing fluid headings with an explicit
   `clamp()` in `sx` when needed.
3. Build structure from hairlines (`divider`, or the flattened
   `Paper`/`Card`/`AppBar`). Reach for a shadow or a color fill only inside
   the three named dark zones.
4. Corner rounding follows MUI's defaults — no need to force it to zero, and
   no need to add rounding as its own decision either; just don't fight it.
5. Animate with the theme's easing, slow, and verify it disappears under
   `prefers-reduced-motion`.
6. If a value here and the same value in `theme.ts` drift apart, this
   document is the one to trust — fix the theme, not the doc.
