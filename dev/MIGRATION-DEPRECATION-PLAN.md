# Deprecating the migration path

Drafted 2026-11-21, during the S7 release work on `explore/s7-object-system`.

The migration path stays in `ggseg.formats`.
Moving it to `ggseg.extra` was tried and reversed:
migration reads slots, rewrites geometry representations and edits file layout,
so as an outside consumer it forced `ggseg.formats` to export `atlas_slot()`,
`set_atlas_slot()` and three geometry primitives —
the exact escape hatch this release exists to close.
Migration is about the format, which is why it lives with the format.

## The one number that governs this plan

**0 of 109 published atlas objects are S7. All 109, across 28 packages, are legacy tagged lists.**

Measured 2026-11-21 by calling every zero-argument exported accessor in the
installed `ggseg*` atlas packages.

So the legacy path is not a courtesy for stragglers.
It is currently the only reason any published atlas works.
Nothing can be deprecated until that number moves, and the plan below is
mostly about moving it.

## What "the migration path" is

Two groups, which deprecate on different clocks.

**Group A — the explicit migration verbs.** User-called, one-shot, removable.

| Function                       | What it does                                           |
| ------------------------------ | ------------------------------------------------------ |
| `migrate_atlas_files()`        | rewrites every `.rda` in a package's `R/`              |
| `migrate_atlas_hemi()`         | repairs a legacy `hemi` spelling in `core`             |
| `migrate_atlas_display()`      | adds the `display` column                              |
| `convert_legacy_brain_atlas()` | pre-2.0 `brain_atlas` → current (already `superseded`) |

**Group B — the silent legacy acceptance.** Not called by users; reached by
every plot of a published atlas. Spread across 14 files in `R/`.

- `convert_atlas.brain_atlas()`, `.ggseg3d_atlas()`, `.list()` — the non-S7 methods
- `repair_legacy_core()`, `normalise_legacy_hemi()`, `dedupe_legacy_core_labels()`
- `legacy_region_map`
- `tag_legacy_atlas_classes()` and the unqualified class tags
- the legacy branches in `atlas_slot()`, the accessors, the `has_atlas_*()`
  predicates and the base generics
- `atlas_schema()` reading 0 for an unstamped object

Group B is the expensive half, and it cannot go until Group A has been _used_
everywhere.

## Stages

Each stage has a gate that is measured, not judged.
No stage starts before its gate reads true.

### Stage 0 — now, for 3.0.0

Migration and legacy acceptance are fully supported and documented as
transitional. No deprecation markers anywhere.

Ship with 3.0.0:

- the `migrate_rda_file()` atomic-write fix, so migrating cannot truncate a
  user's `.rda`
- a vignette section: how to convert a published atlas package, in one page
- `atlas-contract-check` made automatic on pull requests rather than
  `workflow_dispatch`-only. It is the only gate that drives a published atlas
  through both renderers, and this release proved that nothing else sees a
  conversion regression — six atlases stopped converting with 1946 tests green.

### Stage 1 — convert the universe

The long pole. Nothing else can start until this is done.

- Run `ggseg.extra::upgrade_atlas_package(repair = TRUE)` across all 28 atlas
  packages, one PR each, and republish.
- Verify with the harness this release used: every zero-argument exported
  accessor in every installed `ggseg*` package, through `as_ggseg_atlas()`
  **and** a geometry verb. 109/109 must pass.
- Three packages are recorded as un-rebuildable — `ggsegPower` (annots
  missing), `ggsegAal3` (no build script), `ggsegAal-lemaitreh` (hardcoded to a
  contributor's machine). **Verify that claim before relying on it.** For these,
  conversion is the only route, which is precisely why conversion exists and
  must keep working.
- Six objects need `repair = TRUE` rather than a plain upgrade, because they
  ship a legacy `hemi` spelling: three cerebellar atlases in `ggsegCraddock`,
  one in `ggsegMcalt`, `aal3_cerebellum` in `ggsegAal`, and `ggsegDemoatlas`.

**Gate:** the harness reports 109 S7 / 0 legacy, on a clean machine, against
the published r-universe builds rather than local checkouts.

### Stage 2 — deprecate Group A

Only once Stage 1's gate reads true.

- `lifecycle::deprecate_soft()` on the four migration verbs. Soft, not warn:
  the people who still need them are maintainers of unconverted third-party
  atlases, and a warning on every call punishes the converted majority.
- Leave Group B entirely alone and silent.

**Gate:** two consecutive r-universe build cycles with no atlas package calling
a migration verb. Grep the universe, do not assume.

### Stage 3 — deprecate Group B

- `lifecycle::deprecate_warn(always = FALSE)` when `as_ggseg_atlas()` converts a
  tagged list, a `brain_atlas` or a `ggseg3d_atlas`. Once per session, so a
  third-party atlas still draws but its user learns why it is slow to load.
- Document the removal release in the warning itself.

**Gate:** one full release cycle after Stage 2, and the warning has been live
long enough to appear in at least one r-universe cycle.

### Stage 4 — remove, in a major release

- `migrate_*` become defunct, then deleted.
- `as_ggseg_atlas()` accepts an S7 atlas and nothing else; the three non-S7
  `convert_atlas` methods go.
- Delete `repair_legacy_core()`, `normalise_legacy_hemi()`,
  `dedupe_legacy_core_labels()`, the legacy branches in `atlas_slot()`, the
  accessors, the `has_atlas_*()` predicates, and `atlas_schema()`'s unstamped
  case.
- Keep `legacy_region_map` and the unqualified class tags. The map rewrites
  other people's published figures if it changes, and the tags are what
  `inherits()` asks for across the ecosystem. Neither is migration.

**Gate:** Stage 3 lived through a release, and the harness still reads
109 S7 / 0 legacy.

## What would make this plan fail

- **Starting Stage 2 before Stage 1's gate.** Every published atlas would warn
  on every plot, and the warning would be about something the user cannot fix.
- **Treating the test suite as evidence.** Every fixture in `ggseg.formats` is
  built from `as.list()` of a _current_ bundled atlas, so the suite cannot see a
  conversion regression. The harness over installed packages is the evidence.
- **Deleting Group B while any atlas package is unconverted.** Those atlases
  stop drawing, and three of them cannot be rebuilt.
- **Letting the migration verbs rot while they are still the only route.** They
  are load-bearing until Stage 1 finishes, so they keep their tests and their
  place in CI.
