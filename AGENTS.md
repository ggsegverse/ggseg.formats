# AGENTS.md — ggseg.formats

Contributor guide for AI agents working in this repository. The goal is
to extend or fix the package **without breaking its intended structure
or its contract with the rest of the `ggsegverse` ecosystem**. Read this
before touching `R/`, `data-raw/`, or the atlas objects.

## What this package is

`ggseg.formats` is the foundational data-structure package of the
[`ggsegverse`](https://ggsegverse.github.io/ggseg/). It owns the
`ggseg_atlas` S3 class and the accessor API that `ggseg` (2D), `ggseg3d`
(3D), and `ggseg.extra` build on. It ships bundled atlases and
FreeSurfer stat readers — it does **not** itself do the high-level
plotting beyond a base-R
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) overview.

Because it sits at the bottom of the dependency tree, **any change to
the class shape, accessor signatures, or atlas object contents is a
breaking change for downstream packages**. Treat the public API as a
contract. When in doubt, add behaviour behind a new accessor rather than
mutating an existing structure.

Dependencies are deliberately lean: `Imports` is only `cli`,
`lifecycle`, `rlang`, `sfheaders`. `sf` is in **Suggests** (see
sf-optional below). Do not add Imports without a strong reason — the
ecosystem values a light base.

## The `ggseg_atlas` object

Built and validated by the
[`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)
constructor in
[ggseg_atlas.R](https://ggsegverse.github.io/R/ggseg_atlas.R) — treat
that constructor as the authoritative signature, not any argument list
copied here. Conceptually an atlas is a classed list with:

- `atlas` — short name string (e.g. `"dk"`).
- `type` — the atlas kind, drawn from a fixed set (currently
  `"cortical"`, `"subcortical"`, `"tract"`, `"cerebellar"`) enforced by
  [`match.arg()`](https://rdrr.io/r/base/match.arg.html) in the
  constructor; extend there if a new type is ever added. It drives the
  subclass tag (`paste0(type, "_atlas")`).
- `palette` — named character vector of hex colours, keyed by `label`.
- `core` — data.frame, **one row per region**, required columns `hemi`,
  `region`, `label`; may carry extra metadata columns (lobe, network,
  Brodmann, …).
- `data` — a `ggseg_atlas_data` object matching `type`, built by the
  per-type constructors in
  [ggseg_atlas_data.R](https://ggsegverse.github.io/R/ggseg_atlas_data.R).

The class vector is `c("<type>_atlas", "ggseg_atlas", "list")`.
**Preserve this ordering** — the per-type `is_*_atlas()` predicates rely
on the subclass tag, and the `ggseg_atlas` validity check revalidates
structure through the constructor (a wrong-but-classed object is
rejected). These are the contract; extend behaviour by adding accessors
rather than reshaping the object.

### The 2D `geom` slot (sf-optional)

2D geometry lives in a **single `geom` slot** inside `data`, holding
*either*:

- an `sf` data.frame (`label`, `view`, `geometry`), **or**
- a `brain_polygons` data.frame (sf-free, see
  [`sf_to_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/sf_to_polygons.md)).

The class of `geom` selects the rendering path. Atlases released before
the unified slot store geometry in a legacy slot, and the accessors fall
back to it. **Never reach into the raw geometry slots directly** —
always go through the `atlas_*()` accessor family in
[atlas_accessors.R](https://ggsegverse.github.io/R/atlas_accessors.R),
which is the single place that handles the legacy fallback, the
sf⇄polygon conversion, and guarding every sf-producing path with
`require_sf()`. When a new code path needs geometry, call an existing
accessor or add one; never special-case the storage layout at the call
site.

## Bundled atlases

The package ships a small set of ready-made atlases, each returned by a
zero-arg accessor that hands back an internal `sysdata` object
([atlases.R](https://ggsegverse.github.io/R/atlases.R)). The current
set:

| fn | type | source |
|----|----|----|
| [`dk()`](https://ggsegverse.github.io/ggseg.formats/reference/dk.md) | cortical | Desikan-Killiany (FreeSurfer `aparc`) |
| [`aseg()`](https://ggsegverse.github.io/ggseg.formats/reference/aseg.md) | subcortical | FreeSurfer `aseg` segmentation |
| [`tracula()`](https://ggsegverse.github.io/ggseg.formats/reference/tracula.md) | tract | TRACULA white-matter bundles (MNI) |
| [`suit()`](https://ggsegverse.github.io/ggseg.formats/reference/suit.md) | cerebellar | SUIT lobular atlas (polygon `geom`) |

The backing objects live in `R/sysdata.rda`. **Do not hand-edit
`sysdata.rda`.** Regenerate it from the scripts in
[data-raw/](https://ggsegverse.github.io/data-raw): the `make_*`
builders feed `make_sysdata.R`.
[`suit()`](https://ggsegverse.github.io/ggseg.formats/reference/suit.md)
is the reference example for the sf-optional polygon format. To add an
atlas, add its builder under `data-raw/`, wire it into the sysdata
build, and expose it through a zero-arg accessor following the same
pattern — don’t break the existing ones.

## sf-optional discipline

`sf` is a Suggests, not an Imports. Every code path that uses `sf` must:

1.  Call `require_sf("<what>")` first, which aborts with an actionable
    message pointing to the polygon alternative
    ([`as_polygon_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_polygon_atlas.md)),
    **or**
2.  Branch on `has_sf()` when a graceful fallback exists.

In tests, gate sf-only assertions with `skip_if_not_installed("sf")`,
and use `local_mocked_bindings(has_sf = function() FALSE)` to exercise
the no-sf path. The package and its full test suite must pass with `sf`
**uninstalled**. See
[sf_availability.R](https://ggsegverse.github.io/R/sf_availability.R).

## Code style

- **Formatter: `air`** (tidyverse style), *not* styler. CI runs
  `air format --check .` — run `air format .` before committing.
- **Linter: `lintr`** via `lint_package()`. Config in
  [.lintr](https://ggsegverse.github.io/.lintr): default linters,
  80-char lines, `cyclocomp` and `object_usage` disabled. Keep lines ≤
  80.
- Follow the global R standards: tidyverse style, self-explanatory
  names, **no comments except to explain a necessary workaround**,
  base-R patterns where they fit.
- **User-facing messages use `cli`**
  (`cli::cli_abort/cli_warn/cli_inform`), never
  `stop`/`warning`/`message`/`cat`. Use cli inline markup (`{.arg}`,
  `{.cls}`, `{.val}`, `{.fn}`, `{.run}`).
- Deprecations go through `lifecycle` (see
  [`brain_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)
  →
  [`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)),
  not ad-hoc warnings.

## Documentation

- roxygen2 with **markdown enabled**; regenerate with
  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html),
  never edit `man/*.Rd` or `NAMESPACE` by hand.
- Shared `@param` blocks live in
  [man-roxygen/](https://ggsegverse.github.io/man-roxygen)
  (`@template geom`, `@template geom_dots`) — reuse them for new
  geometry arguments rather than re-documenting.
- Use `@family` tags to keep atlases and accessors grouped in the
  reference index. Exported atlas builders carry full `@references` with
  `\doi{}`.
- Keep `README.Rmd` as the source of truth (knit to `README.md`); edit
  the `.Rmd`. Preserve existing vignette content — only change sections
  explicitly requested.

## Testing

- **testthat 3e**, `describe()`/`it()` structure (config:
  `Config/testthat/edition: 3`). Mirror file names: `R/foo.R` →
  `tests/testthat/test-foo.R`.
- **100% line coverage is a CI gate.** Ship every new function, branch,
  and conditional with a test that exercises it, in the same change.
  “Add tests later” is not acceptable here.
- Prefer focused expectations (`expect_s3_class`, `expect_identical`,
  `expect_error(.., "message")`). Match error messages on a stable
  substring.
- Keep test output clean (no stray prints/warnings); use `withr` for any
  state changes.

## CI gates (all must be green before merge)

- **R-CMD-check** — multi-OS / multi-R matrix.
- **code-quality** — `air format --check` +
  [`lintr::lint_package()`](https://lintr.r-lib.org/reference/lint.html),
  **plus a `goodpractice` hard gate** running the union of all
  goodpractice and tidyverse checks (only
  `lintr_strings_as_factors_linter` is excluded; the package Depends on
  R ≥ 4.1.0 where `stringsAsFactors = FALSE` already).
- **test-coverage** — must stay at 100%.
- **ecosystem-check** (manual `workflow_dispatch`) — installs and
  `R CMD check`s `ggseg`, `ggseg3d`, and `ggseg.extra` against your
  branch. Run this for any change to the class, accessors, or atlas data
  shape to confirm you haven’t broken downstream packages.

Treat “merged with green CI” as done — not “code written”.

## Maintaining package infrastructure

- Update **`NEWS.md`** for every user-visible change, under the current
  development heading, grouped (e.g. *sf-optional migration*, *Internal
  & tooling*). Flag breaking changes explicitly.
- Update **`DESCRIPTION`** (and bump the dev version) when changing
  deps, exports surface, or metadata.
- `man/`, `NAMESPACE`, and `codemeta.json` are generated — regenerate,
  don’t hand-edit.

## Workflow expectations

- **Feature branches only** — never commit to `main` unless explicitly
  told.
- Stage paths explicitly; never `git add .`/`-A` (pre-existing WIP must
  not be swept in).
- Open a PR with a Summary and Test Plan, and shepherd it to green CI.
- Local pre-PR loop: `air format .` →
  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html)
  → [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
  →
  [`lintr::lint_package()`](https://lintr.r-lib.org/reference/lint.html)
  →
  [`devtools::check()`](https://devtools.r-lib.org/reference/check.html).
  Fix the formatter/linter before committing; do not suppress lints to
  paper over a failure.
