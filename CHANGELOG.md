# Changelog

All notable changes to Around the Word are logged here, one entry per version
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
