# whereabout: Scratch Notes

*Loose ends from the planning conversation that didn't fit into the three main docs. Not decisions — just useful things worth not losing.*

---

## Working with Claude Code

**Use a `CLAUDE.md` at the project root.** Claude Code reads it automatically at the start of every session, so it's the right place for a condensed version of the system design and data architecture — not the full docs, which should live in `docs/` for reference. The condensed version should cover: architecture decisions, the data model, and an explicit "don't build this" list, so Claude Code doesn't add a backend or accounts because it seemed reasonable in the moment.

**Build in phases, not "build the whole app."** One large prompt produces a diff too big to review. Natural phase order:
1. Scaffold the Flutter project + folder structure, drop in placeholder JSON (don't wait on real content to start building)
2. Data models + JSON/API parsing, tested in isolation before any UI exists
3. Screens in flow order
4. Wire navigation + state between screens
5. Swap in real integrations

**De-risk the hardest piece first, in isolation.** Whatever the highest-uncertainty component is, prototype it standalone before other screens depend on it. Better to discover a package doesn't work on day one than after four screens are built around it.

**Commit after each phase.** Rollback points if a session goes sideways, and keeps diffs reviewable.

---

## Drawing continent/country graphics (if a map ever comes back)

The map got dropped in favor of search, but if it returns:

- **Figma** — free, browser-based, gentle learning curve, exports clean SVG. Name each layer and draw each region as a *separate* shape (not one merged blob) so the exported SVG keeps them as individually tappable paths.
- **Inkscape** — free, offline, native format *is* SVG so there's no export step. Less polished UI than Figma.

Tips either way:
- Trace from a real world map image rather than freehanding; rough outlines are fine, geographic precision isn't needed
- Simplify outlines (fewer anchor points) after tracing — thousands of points per region bogs down tap-hit-testing and rendering on mobile for no visual benefit at this zoom

---

## AI use and academic policy — the short version

- **Building the app now:** no concern. Personal/commercial work, not coursework, not covered by any academic integrity policy.
- **If it becomes coursework later:** Columbia's policy is disclosure-based, not a ban — assignments specify whether AI is allowed and how, and failure to attribute AI-assisted work is treated as dishonesty. Confirm with the specific advisor, since it's assignment-specific.
- **Application materials — be careful here.** Couldn't find TC's specific written policy for admissions essays; worth confirming when the portal reopens. General pattern across peer programs: fine for researching programs, brainstorming, and grammar; not for outlining, drafting, or writing the essay. Apply that line regardless — write the actual sentences yourself.
- Worth knowing: TC's doctoral track includes a language-and-technology specialization focused on AI in language pedagogy. Hands-on experience building this reads as an asset, not something to downplay.

---

## Contributor form design

Structured questions (multi-select, true/false, ratings) plus a few short free-text prompts. Friend input is **verification and nuance**, not content generation — confirming what's found online, catching what's stale or overstated, surfacing what's missing.

Things to include on the form:
- "In your own words, briefly" on free-text fields — avoids pasted text of unknown provenance entering the research pile
- A plain sentence noting responses will be used in a travel app that may become a paid product
- Credit checkbox, plus a free-text "how should we be credited" field (let people choose first name, handle, whatever)
- **When did you visit?** — recency changes how much weight a response carries
- Attach responses to the specific thing being verified where possible, not just to a country

Credit is country-level, not per-item, since published content is a synthesis of multiple inputs.

---

## Odds and ends

- **Correction reports should be contextual, not a general form.** A report button on the leadership card that already knows the country and field gets usable reports; a standalone "something's wrong" page gets vague ones. Ask for a source URL — "leadership changed, here's the announcement" is a two-minute fix versus a from-scratch verification.
- **Bump `last_verified` even when a correction report turns out to be wrong.** A false alarm still means the data was checked that day.
- **Leadership data is the highest staleness risk** in the whole dataset — nobody reports a wrong prime minister, they just quietly lose trust in everything else on the page. If maintenance gets burdensome at scale, dropping the field beats showing stale data.
- **Advisory data availability varies by government.** Some publish structured feeds, others only a web page. **Partly resolved for the US:** the State Department runs an official Consular Affairs Data API (`cadataapi.state.gov`) covering both advisories and `entry_exit_requirements` — no scraping, no API key. See the data architecture doc's "External Data Sources" and "Automated refresh" sections. Global Affairs Canada also publishes a usable JSON feed (`data.international.gc.ca/travel-voyage/`). The UK FCDO still needs checking separately before assuming an importer covers all three.

---

## Open questions never resolved

- ~~**Whether the career/timeline doc belongs in the same Claude project as the app docs**~~ — **resolved: separate project.** Career/grad-school planning moves out of this project entirely; this project stays scoped to the app.
- ~~**Per-country vs. single-sheet Words/Phrases in the collection spreadsheet**~~ — **resolved: single-sheet stays**, confirming what the workbook already implements (one sheet per entity type, filtered by `country_code`). Current volume (Portugal: 1 row each in Words/Phrases) is nowhere near the 10,000-row ergonomics concern this was anticipating. If a sheet gets uncomfortably long before Supabase exists, use a filtered view (Google Sheets filter view / Excel AutoFilter) for per-country ergonomics without an actual split — never restructure the sheet itself. The real fix is Supabase's admin UI (sequencing step 4), which was already the plan and makes the tension moot on its own. Keep `Categories` shared and single either way, as originally noted.
