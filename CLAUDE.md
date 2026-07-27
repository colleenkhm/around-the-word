# Working notes for Claude — Around the Word

Directions Colleen has given while building this project, kept here so future
sessions don't need to be re-told. Add to this as new direction comes in;
don't remove entries unless she says they no longer apply.

## Current plan

[language-app-system-design.md](language-app-system-design.md) is the
authoritative system design and roadmap — read it first in any new session.
Short version: Flutter app, no backend in V1, continent→country map for
destination selection, checkbox category selection, cosmetic "personalizing"
step, then a Learn (flashcards) / Use (category→vocab list) fork. Content is
static JSON bundled as assets, keyed **per country** (not per language) so
Costa Rica/Mexico/Argentina etc. can each have their own regionally-accurate
Spanish vocab. First language: Spanish. First country: Costa Rica.

Two earlier product directions were explored and superseded — see the
superseded-notices at the top of [app-design-doc.md](app-design-doc.md) and
[HANDOFF.md](HANDOFF.md) for what changed and why. Nothing from them was
deleted; ideas that got scoped out (trip/activity-specific curation, grammar-
tagged vocab + fill-in-blank exercises, a personal phrasebook) are flagged in
the new doc's roadmap as things that could resurface later, not abandoned.

## External context (why V1 is scoped the way it is)

- This ties to Colleen's existing **nightglow.studio** stack/experience.
- Real budget constraint: **5-8 hrs/week**. This is why V1 has no backend, no
  accounts, and no persistence — anything requiring a server is deliberately
  deferred past V1-V3.
- V1 timeline: **Jan-Aug 2027**, per a separate career/roadmap document.
  Longer-term, itinerary-aware/SLA-theory-driven work is described there as
  **master's-dependent** — i.e. gated on her master's program, not just app
  progress. Worth keeping roadmap suggestions realistic against both
  constraints, not just technical scope.

## Product direction

- MVP content should stay simple. Don't over-build (e.g. audio, elaborate
  exercise mechanics) beyond what the current authoritative doc actually
  calls for.
- Alongside topic-based categories (Food, Transportation, etc.), it's fine to
  add core-vocab-style categories that aren't tied to a situation — e.g. "20
  Common Verbs." These don't need special modeling, just another category.

## Docs to keep current

- [language-app-system-design.md](language-app-system-design.md) — **the**
  system design/roadmap doc. Living doc, built section by section. This is
  the one to update when scope, architecture, or roadmap decisions change.
- [app-design-doc.md](app-design-doc.md) — earlier product/design decisions,
  now superseded but kept as history (marked inline where superseded).
- [HANDOFF.md](HANDOFF.md) — implementation-level decisions made while
  building, and why. Update this when a non-obvious technical call gets made
  (data modeling, navigation structure, scope cuts), not for routine code
  changes.

## Working style

- When a newly-provided doc/handoff conflicts with what's already recorded in
  the project, **flag the specific conflicts before proceeding** rather than
  silently picking one or merging them quietly. Confirmed good approach on
  2026-07-27: flagging a conflict between a pasted system-design doc and the
  existing app-design-doc.md got a fast, decisive resolution ("default to the
  new doc, update anything else accordingly") rather than friction — she
  wants the flag, then to make the call herself.
