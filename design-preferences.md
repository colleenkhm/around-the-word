# Design Preferences

*Living doc of Colleen's visual/design taste, kept separate from
[CLAUDE.md](CLAUDE.md) (product scope) and [HANDOFF.md](HANDOFF.md)
(implementation decisions) because it's neither — it's aesthetic
judgment that should carry into *new* design work, not just explain past
changes. Read this before making UI/visual decisions on request, the same
way CLAUDE.md gets read for product-scope ones. Add to it as new taste
surfaces; don't remove entries unless she says they no longer apply.

## Color & surfaces

- **A panel/card must not be the exact same color as the page behind it
  with nothing else distinguishing it.** Flagged 2026-08-17 against
  `TravelInfoSection`'s Travel Advisory card: `CountryTheme.card` and
  `CountryTheme.paper` are literally the same hex, and with no shadow (just
  a thin dashed border), the card read as flush with the page — "looks
  very AI-esque." Give it a lighter/distinct tone, a shadow, or real
  texture — not a flat color-match. **This is a repeat of earlier feedback
  2026-08-11** on the same root cause (`TicketPanel`'s doc comment: "plain
  rounded-rect cards with a border and no shadow read as generic/AI-default
  UI") — evidently a recurring instinct to watch for proactively in new
  work, not just fix reactively when flagged again.
  - Practical fix used: this app's theme already had unused alternate
    tones (`cardWarm`/`cardCool`/`cardMint`/`aged`) mapped to specific
    mockup sections that just hadn't been wired up. Prefer reusing an
    existing token/precedent over inventing a new color when one already
    fits the slot.
- Depth can come from a real shadow (`cardShadow`) *or* a tone shift *or*
  genuine texture (a dashed/notched "ticket" edge) — but zero of the three
  reads as a placeholder, not a finished panel.
- **Stay in the warm/cream family — cool or blue-leaning tones don't fit
  this page even as subtle accents.** The mockup's `.card-cool` panel
  (Visa/Entry) was a pale gray-green (`#E8EEE8`); once actually on screen
  it read as "light blue" and didn't belong next to everything else's
  cream/tan warmth. Swapped to cream 2026-08-17. When a mockup or spec
  calls for a cool-toned accent on this page, treat that as a signal to
  double-check rather than implement literally — the rest of the palette
  (paper/card/cardWarm/aged, gold, navy) is consistently warm or neutral,
  and a cool tone stands out as wrong even at low saturation.
  - **Deliberate, flagged exception: 2026-08-18's accordion restyle**
    (`trip-dashboard-v5.html`, `AccordionTheme`) is fully cool/pastel —
    sky blue, lavender, sage — the exact family this note rejects.
    Flagged as a direct reversal before building (per the Working Style
    section below); Colleen's call was to override anyway. Scoped to the
    country page only, as its own parallel token set — this note's
    guidance still governs `CountryTheme`, untouched by that pass. If a
    cool tone in the new accordion palette reads wrong once actually on
    screen (the same failure mode this note describes for `.card-cool`),
    that's worth a fast look, not a surprise — see HANDOFF.md's
    2026-08-18 entry for the full reasoning.
- **Gold-on-navy reads "corporate"/"AI-looking" when it's a CTA
  button/accent stripe — but the same gold as a literal star icon is
  fine.** Flagged 2026-08-17 against the Word of Day card's gold stripe +
  "Learn ___" button. The distinction she drew: a gold *star* is a
  recognizable, specific motif ("gold star is a common thing") worth
  keeping as-is on `CitiesSection`'s featured-city marker and the header's
  top stripe; gold used more generically as a CTA/badge accent color read
  as generic and got swapped to a new warm terracotta/clay tone
  (`CountryTheme.terracotta`, `#C1653D`) instead. **Takeaway: gold's
  problem isn't the hue itself, it's using it as a general-purpose accent
  rather than for something it's specifically, recognizably right for** —
  don't assume a whole-palette swap is wanted just because one use of a
  color is unwanted elsewhere; scope color complaints to where they were
  actually pointed at before changing a shared token everywhere it's used.

## Typography

- Don't undersize functional text. Flagged 2026-08-17 against the ticket
  stub's local-time/currency fields (8-22px range) as "pretty teeny" —
  bumped 2-6px across the board. When in doubt, size up rather than down
  for anything a user actually needs to read at a glance.

## Spacing & alignment

- **Symmetric spacing around a dividing line reads as intentional;
  lopsided spacing reads as a bug**, even if neither side is individually
  wrong. Explicitly requested 2026-08-17: "same amount of visual space on
  either side of the line."
- Thin dividers over thick ones by default — a 1.5px rule read as heavy;
  1.0px was the fix. Default to a subtle line unless there's a specific
  reason (like a section-boundary accent) to make it bolder.
- Don't leave a large gap "just because a container has padding" — closed
  gaps get explicitly called out ("very little room," "a lot of empty
  space") more often than tight ones do in this project. Default toward
  tighter spacing and let her ask for more room, not the reverse.

## Structural chrome vs. content

- Site-wide chrome (nav elements present on every screen) and
  page-specific chrome (content tied to what's currently being viewed) are
  different things and should read as different things — but *how* they
  should differ (color-blocked apart vs. one continuous surface with a
  thin divider marking the seam) went through several rounds of real
  back-and-forth before landing (2026-08-17: site header tried gold, then
  matched the page navy, then a moved/re-tightened divider between the two
  ended up being the actual fix). **Takeaway isn't "always color-block
  site vs. page chrome"** — it's that the boundary between them needs to
  read clearly *somehow*, and a well-placed thin divider can do that job
  as well as a color change, sometimes better. Ask which one she means
  ("site header" vs. "page header") if a request uses that language and
  it's not obvious from context — those terms mean specific, different
  things in this codebase now (see `CountryHeader`'s and `SiteHeader`'s
  class docs).

## Working style during design iteration

- She iterates by screenshot, fast — expect several rounds of small
  corrections on any new visual work, not one-shot approval. Make the
  change, verify it compiles/tests pass, describe plainly what changed and
  where, and let the next screenshot drive the next correction rather than
  trying to anticipate every adjustment up front.
- Reserve clarifying questions for genuine *structural* ambiguity (e.g.
  which of two widgets "the header" refers to, or where a divider actually
  belongs) — not for simple numeric tweaks (padding, font size), where a
  reasonable default plus a quick description of what was chosen works
  better than pausing to ask.
- If a described visual change produces literally zero visible difference
  after it's confirmed correct in source, suspect the environment (stale
  build, hot-reload miss) before re-guessing the values — see HANDOFF.md's
  `flutter clean` note for the concrete gotcha this surfaced.
