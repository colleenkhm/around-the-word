# Changelog

All notable changes to Forin (renamed from whereabout 2026-08-31, which was
itself renamed from "Around the Word" — see the 0.4.0 entry below) are
logged here, one entry per version
bump in [pubspec.yaml](pubspec.yaml). Loosely follows
[Keep a Changelog](https://keepachangelog.com/) and
[Semantic Versioning](https://semver.org/) — while the app is pre-1.0
(`0.x.y`), minor bumps mean "new feature," patch bumps mean "fix," and none
of it implies API/data stability the way it would post-1.0. See `CLAUDE.md`
for what a version bump should actually mean day to day.

This is a **user-facing-change log**, not a commit log — git history already
has the commit-by-commit detail; this file is for "what changed and why
would a tester/traveler notice," one entry per release. Skip pure internal
refactors/doc updates unless they're worth calling out.

## [Unreleased]

### Changed
- **App renamed from "whereabout" to "Forin"** (tagline: "making the foreign
  familiar"). App title, iOS/Android bundle identifiers, and web app name
  all updated — same class of change as the 0.4.0 rename below.
- New "Holidays" section on the country page — public holidays, sourced
  from Nager.Date.

## [0.4.0] — 2026-08-21

### Changed
- **App renamed from "Around the Word" to "whereabout."** App title, iOS/
  Android bundle identifiers, and web app name all updated; no functional
  change. The header wordmark ("Where" + "about" next to the globe icon,
  added in 0.3.0) already anticipated this.

## [0.3.0] — 2026-08-18

### Changed
- **Every searchable country now opens a real country page — no more
  dead-end "coming soon" screen.** A country with no curated content yet
  shows the same page as any other, with each section (Visa & Entry,
  Cities, When to Visit, Travel Advisory, Language, Practical Norms)
  reading "Coming soon" once expanded, instead of a separate page with a
  short message and generic links.
- The rest of the app — category checkboxes, "Personalizing your
  dictionary," Learn/Use, vocab lists, flashcards, and the About page —
  now matches the country page's fonts and colors. Previously only the
  country page and search screen had been restyled.
- Search screen: fixed a leftover cream-colored search field and an
  off-palette blue focus ring, tightened the gap between the search field
  and results, added breathing room around the header text, and turned
  off the debug-mode ribbon.
- A "Whereabout" wordmark now appears next to the globe icon in the header
  on every screen, not just search.

## [0.2.0] — 2026-08-18

### Changed
- Country page (Costa Rica preview) redesigned as a **collapsible-sections
  accordion** — Visa & Entry, Cities, When to Visit, Travel Advisory,
  Language, and Practical Norms each expand/collapse independently, with an
  "Expand all / Collapse all" shortcut on the ticket header. Previously
  everything rendered as one long, always-expanded stack.
- A section with no curated content yet now expands to say "Coming soon"
  instead of being left off the page — every section always shows, so it's
  clear what's still being filled in versus what's simply collapsed.
- New color palette and typeface for the country page specifically (ink,
  lavender, sage, rose, butter, and sky tones; Fraunces/DM Sans/DM Mono),
  replacing the navy-and-gold "boarding pass" look from the previous
  release. Search and the About page are unchanged for now.
- Visa & Entry and Travel Advisory are separate sections again, each citing
  its own source, rather than one combined card.

## [0.1.0] — 2026-08-17

### Added
- Versioning convention established: `0.x.y` through pre-V1 development,
  `1.0.0` reserved for the first real release to actual travelers (see
  `CLAUDE.md`'s Current Plan). Previously the untouched `flutter create`
  default (`1.0.0+1`).
