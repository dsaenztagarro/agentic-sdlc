---
name: design-repo
description: Create a design repository — a product's design or a shared design system — from one skeleton, so it starts in the layout every design repository keeps; or adopt the layout check in an existing one. Use when a project first needs a design repository, when a shared design system gets its own, or when an existing design repository should be held to the layout.
---

# Creating a design repository

Every design repository keeps one layout, stated folder by folder in the `design-handoff` skill's `layout.md`. Read it first.
This skill starts a repository in that layout from `skeleton/`, and `skeleton/test/layout_test.rb` keeps it there: copied into the repository, it fails `rake` when the repository drifts.

## 1. Decide, before anything is created

| decision | the rule | who decides |
|---|---|---|
| **kind** | a product's design (one application's surfaces) or a shared design system (what a family of applications shares) | the person, if not already clear |
| **name** | `<project>-ds` beside the application `<project>`; a shared system `<brand>-ds`, for its brand or package, never its platform | derived; confirm |
| **export kind** | `project` (a Claude Design Project → `pages/`) or `system` (a Design System → `system/`) | from the Claude Design project type |
| **the artefact that crosses** | a stylesheet bundle, a token file — what the application vendors from `dist/` | the person, if not already clear |
| **upstream paths** | files authored here and pushed with `/design-sync` (a palette, a component tier) | none by default |

## 2. Create the repository

Creating a repository is outward-facing: confirm the name first.

```bash
gh repo create <owner>/<name> --private --clone
```

Always `--private` unless the person asked for a public one in this conversation.

## 3. Copy the skeleton and fill in the names

```bash
cp -R <this skill>/skeleton/. <name>/
cd <name>
grep -rl '__NAME__' . | xargs sed -i '' 's/__NAME__/<name>/g'     # GNU sed: -i without ''
sed -i '' 's/^KIND="__KIND__"$/KIND="<project|system>"/' bin/sync
chmod +x bin/sync bin/ds-status
```

A product bound to a shared system replaces `__SHARED__` in `bin/ds-status` with that system's repository name. A shared system, or a product bound to none, deletes `bin/ds-status` and `test/ds_status_test.rb`.
A shared system deletes `bin/shots`, `lib/shots.js` and `test/shots_test.rb` too: it has no pages to shoot.

Then resolve every `FILL` marker (`grep -rn FILL .`):

- **`README.md`** — the opening paragraph, and the tree: keep the lines that apply, delete the rest.
- **`AGENTS.md`** — the consuming application, and which paths flow which way.
- **`briefs/README.md`** — what belongs here, for this kind.
- **`bin/sync`** — `UPSTREAM` lists the authored paths; `EXCLUDES` keeps its default unless the project carries other authoring noise.
- **`Rakefile`** — the generator's task and its `:check`, ahead of `:test`.

## 4. Add the generator

`lib/` holds it, `dist/` its committed output, and `rake` fails when the two disagree — that check is what makes *generated, not copied* true.
It is plain Ruby with no gems, so the repository clones and runs with nothing installed.
A product's stylesheet bundle is wrapped in its own cascade layer, declared after the shared system's.
Each refusal or guarantee it adds gets a test named for the rule.

## 5. Create the Claude Design project

Same name as the repository. Seed its own `readme.md` through `/design-sync` with the rules that must hold in every export — for a product's project, the surface-only rule and its markup contract (`design-handoff` §4), so that `bin/shots` can shoot every page and no brief has to restate it.
When paths flow upstream, record the project's id and namespace in `.design-sync/config.json`, and what a future `/design-sync` must know in `.design-sync/NOTES.md`.

## 6. First export, then the gate

```bash
bin/sync       # mirror the first export; a product's also shoots every page into tmp/shots/
rake           # the generator's check, then every test — layout_test.rb included
```

Commit the mirror as produced. The repository is done when `rake` passes and `grep -rn FILL .` finds nothing.

## Adopting the layout check in an existing design repository

1. Copy `skeleton/test/layout_test.rb` into its `test/`, and run `rake`.
2. Each failure is drift: fix it in the same change when it is small, or open an issue per failure on that repository.
3. A folder the layout does not name is either moved, or argued into `layout.md` first — never allowed by editing the copy.

## Refreshing the check

`layout_test.rb` is copied, not shared: when a rule changes here, copy it again into each design repository, and fix what the new rule finds there. A local edit forks the rule from every other repository.
