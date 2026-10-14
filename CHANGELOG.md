# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **A product's design repository shoots every page in every state, the surface alone.** `design-repo`'s skeleton gains `bin/shots` and its generator `lib/shots.js`, which walk each page's state bar in the installed Chrome and screenshot the `[data-surface]` element in each state into `tmp/shots/`, with a contact sheet; a caption or paragraph drawn beside the surface never reaches a shot. A page that breaks the contract — not exactly one surface, no state, several states and no state bar, a bar whose tabs disagree with the states — is named, for a brief to fix. `bin/sync` runs it after mirroring a project export, and `test/shots_test.rb` holds each rule, skipping where node or a browser is missing.
- **A page with many states groups them into families.** `design-handoff` §4: a Family row above the State row, a family's states contiguous and named `<Family> · <state>` without repeating the family, every state carrying `[data-family]` or none. `lib/shots.js` reads a grouped bar — each tab labelled with the state part, `Default` for the bare family — reaches the tabs it hides, and names a split family, a state outside its family's name and one repeating it.
- **A page states its surface and states in its markup.** `design-handoff` §4: `[data-surface]`, `[data-state="<Name>"]` and a `[role="tablist"][aria-label="State"]` bar; the rule goes into the project's `readme.md` with the rest of §4, so no brief restates it.

### Changed

- **Renamed to `agentic-sdlc`.** The template covers the whole lifecycle of building software with agents — plan, design, build, verify, release, decide — and the shorter name says so; GitHub's template flag already marks it as a template.
- **A product owns the components its experience needs, and promotes one only when it is generic.** `design-handoff` §5: a shared component is used as it is where it serves the job as well as anything could; otherwise the product draws its own and keeps it. That the shared system lacks a component is no reason to move it there: it is promoted — through the stand-in route — only once it is generic enough to serve other applications unchanged.
- **A terminal client's page is snapshots only.** `design-handoff` §4: a terminal redraws a whole grid per key press, so one frame per state is everything the user sees, and a page answering keys would write the application's key map a second time. A step through the surface is a run of named states. A behaviour question is drawn as candidate states and raised in the design chat, never labelled on the page.

## [0.4.2] - 2026-10-08

### Added

- **Every decision-log issue carries the `decision-log` label.** `docs/adr/README.md` states the issue's shape — titled `decision-log: <theme>`, one comment per amendment, open for as long as its record exists — and the filter that lists every theme's history, `gh issue list --label decision-log --state all`. `AGENTS.md` points an agent at it, and the themes table gains a Decision log column.

## [0.4.1] - 2026-10-08

### Fixed

- **`design-handoff` §5 states its rejected alternative in one line.** The hand-kept receipt is given with the technical reason it loses, without an account of how it failed.

## [0.4.0] - 2026-10-08

### Added

- **A page reaches its states through a switcher.** `design-handoff` §4: a surface's states share one page, one panel each, reached through a state switcher on the page, and no view shows two at once; each state's name is the switcher's label, and the page carries no other caption.
- **A component's example page is held to the page format.** `design-handoff` §4: it shows the component's cases as states and nothing else; each rule it carried goes to the shared system's component file, the comment beside the class, or a request upstream, and options weighed, research and rollout sweeps go to the design chat and the tracker.
- **A design project's agent context holds principles only.** `design-handoff` §2: the file the project reads before it draws states principles that hold for elements not drawn yet; a decision about one element is drawn in that element's page, so the file grows with the product's ideas, not its elements.
- **Triage the brief queue before a reshape.** `design-handoff` §8: a sweep or redraw across many pages starts only once every open brief has been checked against the current export — deleted when landed or outdated, moved when it belongs to the shared system, carried into the reshape or rechecked after it when still open.
- **How a product's design project knows its copy of the shared system is current.** `design-handoff` §5: the project draws against its own frozen `_ds/` copy, which only the project refreshes; the landing steps in order; and `bin/ds-status`, in the `design-repo` skeleton with its test, which compares the copy's `_ds_manifest.json` with the shared system's and names every token and component the copy lacks. The manifests are written by Claude Design on every export, so the check needs no hand-kept receipt.

### Removed

- **The request-queue check.** `layout_test.rb` no longer guards against `ds-graduation/` or `handoffs/` inside an export, and `layout.md` no longer lists them: both were folder names this template's adopters invented, not Claude Design conventions, and with the folders gone the check guarded a name nobody creates. A request is still a brief in the repository that will draw it.

## [0.3.0] - 2026-10-05

### Added

- **A `design-repo` skill** that creates a design repository — a product's design or a shared design system — from one skeleton: the root files, `briefs/README.md`, the weekly CI, a `Rakefile` whose `rake` is the gate, and a `bin/sync` for either export kind that refuses an export of the wrong kind, a page that is not one canonical prototype per surface, and an edit to a file the repository authors upstream, with a test for each. It also adopts the layout check in an existing repository.
- **A layout check for design repositories**, `test/layout_test.rb` in the `design-repo` skill's skeleton: each design repository copies it into its own `test/`, so `rake` fails when the repository leaves the layout — an unnamed root entry, a symlink, an ignored part of an export, a request queue inside an export, a misnamed brief or vendored system, a `CLAUDE.md` that is not an import, scratch left trackable.

## [0.2.0] - 2026-10-05

### Changed

- **Renamed to `agentic-engineering-template`.** "AI engineering" names building applications on language models; this template is about engineering *with* agents.
- **Every corpus an agent reads is bounded.** Decision records move to `docs/adr/`: a few broad themes, one record each, named for the theme and amended in place, with superseded reasoning on a per-theme decision-log issue. `/epic` amends themes once, at close-out, instead of writing a record per ticket. `docs/adr/decision-records.md` records why.
- **Design content moves to a sibling `<project>-ds` repository**, with one generated artefact crossing. The `design-handoff` skill is the procedure, including the three routes into a Claude Design project.

- **Each ticket gets its own worktree**, `claude --worktree issue-<N>` under a git-ignored `.claude/worktrees/`, so two agents never share a checkout and the same name re-enters it.

### Added

- **A `brief-closer` agent**, which closes a brief once its surface ships and verifies each ask before deleting anything.
- **A `design-handoff` skill**, the Claude Design procedure an agent follows when it writes a brief or reads an export back. It rules that a page draws the surface — every state, interaction included — and never the application's behaviour, a rule seeded into the design project's own `readme.md`; names a design project for its codebase and a shared design system for its brand, never its platform; lands a component the shared system lacks through one byte-identical stand-in and a brief in the shared system's own repository, deleted when the component ships; and states in `layout.md` the one layout every design repository keeps, folder by folder — a product's design and a shared design system alike.
- **README §10 lists the skills the workflow uses**: the ones shipped here, the ones each project creates (`read-designs`, `design-curator`), and the user-level ones created once for every project (`tracker-plan`, `tracker-resume`, `tracker-pause`, `tracker-close`, `deps-upgrade`, knowledge capture), with the phase of the work each carries.

### Removed

- **`docs/features/`, `docs/specs/`, `docs/guides/`, `docs/architecture/` and `docs/designs/`.** Each grew one file per feature, decision or brief. Behaviour is stated by tests, the reasoning by themed records, commands by the README and procedures by skills; nothing describes how the code works, because the code and its tests already do.

## [0.1.0] - 2026-08-13

First tagged release of the AI-engineering template — the agent-driven workflow scaffold that a project copies to give its coding agents a single, current source of truth.

### Added

- **Agent instruction source of truth** — `AGENTS.md` (surfaced to Claude via `CLAUDE.md`) carrying the portable principles: deliberate model selection and task-complexity tagging, the documentation taxonomy, testing guidelines (test the real thing; verify the runtime surface), the Claude Design workflow, and the standard development workflow.
- **Documentation taxonomy under `docs/`** — Architecture Decision Records (`docs/architecture/decisions/`) with a README, numbered template, and the seed ADR-0001; how-it-works explainers (`docs/architecture/`) with an explainer template; how-to guides (`docs/guides/`); feature docs (`docs/features/`); and a security note (`docs/SECURITY.md`).
- **Feature-specification layer (`docs/specs/`)** — the design=surface / spec=behaviour boundary, with code citing the spec (never a design file) via a relative markdown anchor link, cross-cutting behaviour consolidated into one shared spec every instance cites, and no design section-anchor in user-facing copy. (Closes #1.)
- **Claude Design workflow** — brief → canvas → build-to-it → verify-and-promote, bound to a repo design system recorded in `docs/designs/DESIGN-SYSTEM.md`, with brief scaffolding under `docs/designs/briefs/`, plus the rule to validate a design against the codebase and raise the hand — by comment or brief, sized to the discrepancy — rather than silently implementing a wrong design or diverging from it in code.
- **Skills** — `epic` (turn a design doc into a phased GitHub epic, shipped one ticket at a time) and `template-feedback` (raise a reusable, project-agnostic improvement back to this upstream template).
- **MIT license** and project README.

[Unreleased]: https://github.com/dsaenztagarro/agentic-sdlc/compare/v0.4.2...HEAD
[0.4.2]: https://github.com/dsaenztagarro/agentic-sdlc/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/dsaenztagarro/agentic-sdlc/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/dsaenztagarro/agentic-sdlc/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/dsaenztagarro/agentic-sdlc/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/dsaenztagarro/agentic-sdlc/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/dsaenztagarro/agentic-sdlc/releases/tag/v0.1.0
