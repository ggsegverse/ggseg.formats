# AGENTS.md — ggseg.formats

Contributor guide for AI agents working in this repository. The goal is to
extend or fix the package **without breaking its intended structure or its
contract with the rest of the `ggsegverse` ecosystem**. Read this before
touching `R/`, `data-raw/`, or the atlas objects.

## What this package is

`ggseg.formats` is the foundational data-structure package of the
[`ggsegverse`](https://ggsegverse.github.io/ggseg/). It owns the `ggseg_atlas`
S3 class and the accessor API that `ggseg` (2D), `ggseg3d` (3D), and
`ggseg.extra` build on. It ships bundled atlases and FreeSurfer stat readers —
it does **not** itself do the high-level plotting beyond a base-R `plot()`
overview.

Because it sits at the bottom of the dependency tree, **any change to the class
shape, accessor signatures, or atlas object contents is a breaking change for
downstream packages**. Treat the public API as a contract. When in doubt, add
behaviour behind a new accessor rather than mutating an existing structure.

Dependencies are deliberately lean: `Imports` is only `cli`, `lifecycle`,
`rlang`, `sfheaders`. `sf` is in **Suggests** (see sf-optional below). Do not
add Imports without a strong reason — the ecosystem values a light base.

## The `ggseg_atlas` object

Built and validated by the `ggseg_atlas()` constructor in
[ggseg_atlas.R](../R/ggseg_atlas.R) — treat that constructor as the
authoritative signature, not any argument list copied here. Conceptually an
atlas is a classed list with:

- `atlas` — short name string (e.g. `"dk"`).
- `type` — the atlas kind, drawn from a fixed set (currently `"cortical"`,
  `"subcortical"`, `"tract"`, `"cerebellar"`) enforced by `match.arg()` in the
  constructor; extend there if a new type is ever added. It drives the subclass
  tag (`paste0(type, "_atlas")`).
- `palette` — named character vector of hex colours, keyed by `label`.
- `core` — data.frame, **one row per region**, required columns
  `hemi`, `region`, `label`; may carry extra metadata columns (lobe, network,
  Brodmann, …).
- `data` — a `ggseg_atlas_data` object matching `type`, built by the per-type
  constructors in [ggseg_atlas_data.R](../R/ggseg_atlas_data.R).

The class vector is `c("<type>_atlas", "ggseg_atlas", "list")`. **Preserve this
ordering** — the per-type `is_*_atlas()` predicates rely on the subclass tag,
and the `ggseg_atlas` validity check revalidates structure through the
constructor (a wrong-but-classed object is rejected). These are the contract;
extend behaviour by adding accessors rather than reshaping the object.

### The 2D `geom` slot (sf-optional)

2D geometry lives in a **single `geom` slot** inside `data`, holding _either_:

- an `sf` data.frame (`label`, `view`, `geometry`), **or**
- a `brain_polygons` data.frame (sf-free, see `sf_to_polygons()`).

The class of `geom` selects the rendering path. Atlases released before the
unified slot store geometry in a legacy slot, and the accessors fall back to it.
**Never reach into the raw geometry slots directly** — always go through the
`atlas_*()` accessor family in
[atlas_accessors.R](../R/atlas_accessors.R), which is the single place that
handles the legacy fallback, the sf⇄polygon conversion, and guarding every
sf-producing path with `require_sf()`. When a new code path needs geometry, call
an existing accessor or add one; never special-case the storage layout at the
call site.

## Bundled atlases

The package ships a small set of ready-made atlases, each returned by a zero-arg
accessor that hands back an internal `sysdata` object
([atlases.R](../R/atlases.R)). The current set:

| fn          | type        | source                                |
| ----------- | ----------- | ------------------------------------- |
| `dk()`      | cortical    | Desikan-Killiany (FreeSurfer `aparc`) |
| `aseg()`    | subcortical | FreeSurfer `aseg` segmentation        |
| `tracula()` | tract       | TRACULA white-matter bundles (MNI)    |
| `suit()`    | cerebellar  | SUIT lobular atlas (polygon `geom`)   |

The backing objects live in `R/sysdata.rda`. **Do not hand-edit `sysdata.rda`.**
Regenerate it from the scripts in [data-raw/](../data-raw): the `make_*`
builders feed `make_sysdata.R`. `suit()` is the reference example for the
sf-optional polygon format. To add an atlas, add its builder under `data-raw/`,
wire it into the sysdata build, and expose it through a zero-arg accessor
following the same pattern — don't break the existing ones.

## sf-optional discipline

`sf` is a Suggests, not an Imports. Every code path that uses `sf` must:

1. Call `require_sf("<what>")` first, which aborts with an actionable message
   pointing to the polygon alternative (`as_polygon_atlas()`), **or**
2. Branch on `has_sf()` when a graceful fallback exists, **or**
3. Not use `sf` at all, which is usually the right answer.

**When a gate is warranted.** `sf` is required only for computation that needs
GEOS, GDAL or PROJ: `st_difference`, `st_intersection`, `st_union`,
`st_sym_difference`, `st_make_valid`, `st_area`, `st_bbox`, `st_cast`, and CRS
transforms. Everything else — reading coordinates out of a geometry, building a
geometry, restoring the `sf` class and its `sf_column` attribute — goes through
`sfheaders`, which is an Imports and has no system dependencies. Reach for
`sfheaders::sfg_to_df()` / `sfc_to_df()` to read and the `sf_*()` / `sfc_*()` /
`sfg_*()` constructors to build. A gate in front of work that only reads or
builds geometry is a bug, not caution: it refuses something the package can do.

Two paths may keep a gate even though they touch no GEOS, because handing back
an `sf` object is their entire purpose and a caller who wants one wants `sf`
too: `atlas_sf()` and `as.data.frame.ggseg_atlas()`.

**Never rely on an `sf::` call for its namespace-load side effect.** Calling
`sf::anything()` loads the `sf` namespace, which registers `merge.sf`, `[.sf`
and the rest. Code *below* such a call can therefore depend on those methods
without naming them, and deleting the call — even one whose return value is
provably an identity — silently drops the `sf` class and `sf_column` attribute
from a later `merge()` or `[`. This has already shipped once and been reverted.
When a path must return an `sf`-classed object without `sf`, set the class and
`sf_column` attribute explicitly, as `polygons_to_sf()` does.

In tests, gate sf-only assertions with `skip_if_not_installed("sf")`, and use
`local_mocked_bindings(has_sf = function() FALSE)` to exercise the no-sf path.
The package and its full test suite must pass with `sf` **uninstalled**. See
[sf_availability.R](../R/sf_availability.R).

## Code style

- **Formatter: `air`** (tidyverse style), _not_ styler. CI runs
  `air format --check .` — run `air format .` before committing.
- **Linter: `lintr`** via `lint_package()`. Config in
  [.lintr](../.lintr): default linters, 80-char lines, `cyclocomp` and
  `object_usage` disabled. Keep lines ≤ 80.
- Follow the global R standards: tidyverse style, self-explanatory names,
  **no comments except to explain a necessary workaround**, base-R patterns
  where they fit.
- **User-facing messages use `cli`** (`cli::cli_abort/cli_warn/cli_inform`),
  never `stop`/`warning`/`message`/`cat`. Use cli inline markup
  (`{.arg}`, `{.cls}`, `{.val}`, `{.fn}`, `{.run}`).
- Deprecations go through `lifecycle` (see `brain_atlas()` →
  `ggseg_atlas()`), not ad-hoc warnings.

## Documentation

- roxygen2 with **markdown enabled**; regenerate with `devtools::document()`,
  never edit `man/*.Rd` or `NAMESPACE` by hand.
- Shared `@param` blocks live in [man-roxygen/](../man-roxygen)
  (`@template geom`, `@template geom_dots`) — reuse them for new geometry
  arguments rather than re-documenting.
- Use `@family` tags to keep atlases and accessors grouped in the reference
  index. Exported atlas builders carry full `@references` with `\doi{}`.
- Keep `README.Rmd` as the source of truth (knit to `README.md`); edit the
  `.Rmd`. Preserve existing vignette content — only change sections explicitly
  requested.

## Testing

- **testthat 3e**, `describe()`/`it()` structure (config:
  `Config/testthat/edition: 3`). Mirror file names: `R/foo.R` →
  `tests/testthat/test-foo.R`.
- **100% line coverage is a CI gate.** Ship every new function, branch, and
  conditional with a test that exercises it, in the same change. "Add tests
  later" is not acceptable here.
- Prefer focused expectations (`expect_s3_class`, `expect_identical`,
  `expect_error(.., "message")`). Match error messages on a stable substring.
- Keep test output clean (no stray prints/warnings); use `withr` for any state
  changes.
- **Do not namespace testthat in tests.** `tests/testthat.R` attaches it, so
  write `skip_if_not_installed("sf")`, not `testthat::skip_if_not_installed()`
  — including in `helper-*.R`, which is sourced after testthat is attached.

## CI gates (all must be green before merge)

- **R-CMD-check** — multi-OS / multi-R matrix.
- **code-quality** — `air format --check` + `lintr::lint_package()`, **plus a
  `goodpractice` hard gate** running the union of all goodpractice and
  tidyverse checks (only `lintr_strings_as_factors_linter` is excluded; the
  package Depends on R ≥ 4.1.0 where `stringsAsFactors = FALSE` already).
- **test-coverage** — must stay at 100%.
- **ecosystem-check** (manual `workflow_dispatch`) — installs and
  `R CMD check`s `ggseg`, `ggseg3d`, and `ggseg.extra` against your branch.
  Run this for any change to the class, accessors, or atlas data shape to
  confirm you haven't broken downstream packages.

Treat "merged with green CI" as done — not "code written".

## Maintaining package infrastructure

- Update **`NEWS.md`** for every user-visible change, under the current
  development heading, grouped (e.g. _sf-optional migration_, _Internal &
  tooling_). Flag breaking changes explicitly.
- Update **`DESCRIPTION`** (and bump the dev version) when changing deps,
  exports surface, or metadata.
- `man/`, `NAMESPACE`, and `codemeta.json` are generated — regenerate, don't
  hand-edit.

## Workflow expectations

- **Feature branches only** — never commit to `main` unless explicitly told.
- Stage paths explicitly; never `git add .`/`-A` (pre-existing WIP must not be
  swept in).
- Open a PR with a Summary and Test Plan, and shepherd it to green CI.
- Local pre-PR loop: `air format .` → `devtools::document()` →
  `devtools::test()` → `lintr::lint_package()` →
  `devtools::check()`. Fix the formatter/linter before committing; do not
  suppress lints to paper over a failure.
