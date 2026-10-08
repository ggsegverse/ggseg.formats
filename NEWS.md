# ggseg.formats

## ggseg.formats (development version)

### Breaking changes

- `region` is now a short, hemisphere-free key derived from `label`
  (`"bankssts"`), not a long-form display name. `label` is unchanged. Translate
  your own tables with the new `legacy_region_map()`; see
  `vignette("migrating-atlases")`.

  ```r
  my_data$region <- unname(legacy_region_map(dk())[my_data$region])
  ```

- Every verb that takes a pattern matches it against `label` by default.
  `atlas_region_remove()`, `atlas_region_keep()`, `atlas_region_contextual()`
  and `atlas_region_rename()` matched `region`; `atlas_region_op()`,
  `atlas_view_remove_region()` and `atlas_structure_reorder()` already matched
  `label`. `label` is the identifier that is unique within an atlas and stable
  across them. A pattern written for a region spelling that differs from its
  label, such as `"brain stem"` for `Brain-Stem`, now needs
  `match_on = "region"`.

  `atlas_region_rename()` picks its rows by the matched column and always
  edits the region text those rows already have, so renames can be chained
  (`atlas_region_rename(atlas, "Left-", "") |> atlas_region_rename("-", " ")`).
  Matching on `label` used to rebuild the region from the label. Pass a
  function to set a region outright
  (`atlas_region_rename(atlas, "^Brain-Stem$", \(region) "brainstem")`); a
  string that matches labels but changes no region now warns.

- `atlas_regions()`, `atlas_labels()` and `atlas_names()` return their `core`
  column unchanged — one per `core` row, in row order, repeats and `NA`s kept —
  instead of a sorted set of unique values, so the three are now row-aligned.
  `sort(unique(x))` recovers the old value. `atlas_views()` is unchanged.
- `names` is part of the `core` schema, read by the new `atlas_names()`, and
  `suit()` gains it. A non-character `names` is an error; a missing one only
  informs the atlas author once per session at construction, so plotting,
  accessing or class-checking an older atlas package stays silent.
- `ggseg_atlas()` warns when `core$label` is not unique, since the palette and
  every geometry slot are joined on it (ggseg3d#55).
- `aseg()` drops its alias rows (`core` 47 to 29 rows, `"Thalamus Proper"` gone),
  gains the `diencephalon` and `corpus callosum`/`ventricle` `structure` levels,
  and leaves no region unclassified.
- `tracula()` labels carry the `.bbr.prep` suffix again, as FreeSurfer emits it;
  stripping it in 0.0.4.9001 broke every join and palette. The suffix-free name
  moved to a new `label_short` column.

### Atlas data

- The bundled atlases were rebuilt with lighter geometry, shrinking
  `R/sysdata.rda` from 3.4 MB to 2.1 MB, and `tracula()` from anatomical slabs.
  Figures are visually unchanged.

### New features

- New `legacy_region_map()` gives the pre-0.1.0 `region` to current `region`
  mapping for a bundled atlas.
- New accessors `atlas_names()`, `atlas_centerlines()` and
  `atlas_plot_palette()`, the last substituting a fallback for an unusable
  palette; renderers should read the palette through it.
- New setters `set_atlas_palette()` and `set_atlas_type()` keep the coupled
  subclasses in agreement.
- New `relabel_atlas()` re-keys `label` across `core`, the palette and every
  geometry payload at once.
- New `atlas_structure_reorder()` moves structures with `.before`/`.after`
  anchors, deciding which is drawn over which.
- New `atlas_view_select()` keeps each region only in the views where it holds at
  least `threshold` of its best view's area, comparing regions whole.
- `atlas_region_rename()` gains `match_on`; it still only writes to `region`.
- `atlas_centerlines()` returns a `ggseg_centerlines` object with a print
  method, matching `atlas_sf()`, `atlas_vertices()` and `atlas_meshes()`.
- The exported API is organised into three `@family` groups: accessors, setters
  and manipulations.

### Bug fixes

- The `atlas_region_*` verbs warn when their pattern matches no region, instead
  of silently returning the atlas unchanged.
- `plot()` falls back to distinguishable colours, with a warning, when a palette
  resolves every region to one colour; contextual geometry stays grey.
- `atlas_view_reorder()` reorders the geometry rows, not just their coordinates,
  so the new order shows up in a plot.
- `plot()` orders panels by view position, and splits a view by hemisphere where
  that is unambiguous rather than guessing from coordinate gaps. Of the bundled
  atlases only `suit()` changes (#18).
- Geometry columns beyond `label`, `view` and `geometry` now survive conversion
  between the sf and polygon representations, so `migrate_atlas_files()` no
  longer silently deletes atlas metadata when it rewrites `data/*.rda`.
- `migrate_atlas_files()` gains `force`: it aborts, naming the columns and the
  file, when a migration cannot carry every column across.
- `atlas_labels()` gains the `data.frame` method its `atlas_regions()` and
  `atlas_names()` siblings already had.
- `atlas_view_select()` warns and returns the atlas unchanged on a
  geometry-less atlas, like the other view verbs, instead of aborting.
- The five `brain_atlas`-rename deprecations stamped 0.2.0 now say 0.1.0, the
  version they ship in.
- The view verbs warn when a requested view matches nothing, per element, so a
  half-valid request like `c("coronal_3", "axial_3")` no longer passes silently
  on the half that matches.
- `atlas_views()` rejects a non-atlas instead of failing on `$`; the accessors
  now all gate on the same cheap class check.
- `read_atlas_files()` aborts naming `subjects_dir` and the pattern when no
  stats file matches, instead of failing inside `strsplit()`.
- `read_freesurfer_stats()` aborts with both counts and the path when a file's
  `# ColHeaders` line and its table disagree.
- `ggseg_data_tract(meshes = )` now signals its deprecation, like the sibling
  `sf` argument.
- Argument checks in `atlas_sf()`, `atlas_region_op()`, `validate_sf()` and
  `ggseg_data_*(sf = )` run before the `sf` availability gate, so a bad
  argument reports itself rather than a missing optional dependency.

### Internals

- `.Rbuildignore` excludes `revdep/`, `*.Rcheck/` and `*.tar.gz`; `LazyData` is
  dropped, as the package has no `data/`.
- Examples, vignettes and tests no longer require the suggested `sf`:
  `R CMD check` with `_R_CHECK_DEPENDS_ONLY_` goes from 4 errors to 0.
  Fixtures build geometry in either representation, so the sf-free code paths
  are now actually exercised on an install without sf.
- `order_context_behind()` was defined twice and open-coded a third time in
  `as.data.frame()`; one definition remains and both call sites use it.
- Documentation fixes: `get_brain_mesh()` states its face index base, stale
  `coronal_3` / long-form region names in the README and vignettes now name
  values the bundled atlases actually have, and the introductory vignette no
  longer contradicts itself about `$` versus accessors.

## ggseg.formats 0.0.4

### sf-optional bundled atlases

- The bundled `dk()`, `aseg()`, and `tracula()` atlases now ship in the
  `brain_polygons` format, joining `suit()`. They install and plot without
  `sf` (and its GDAL / GEOS / PROJ system libraries) — previously they were
  sf-backed, so plotting them still required `sf` even though the package
  itself did not. The conversion is lossless, so figures are unchanged;
  callers who want sf geometry can still obtain it on demand with
  `as_sf_atlas()`.

### Bug fixes

- Atlas and atlas-data print methods now render the first `n` (default 10)
  rows of their data as a plain `data.frame`, summarising list-columns as
  compact `<int [n]>` / `<df [r x c]>` tokens. Output no longer depends on
  whether `tibble` happens to be installed (the package tags frames as
  `tbl_df` only for cosmetics and does not depend on `tibble`), which makes
  printed output — and the snapshot tests that capture it — deterministic
  across environments.

- `plot.ggseg_atlas()` now draws contextual regions (those not in the atlas
  core) behind the labelled core regions, instead of in alphabetical label
  order. Previously a context region whose label sorted after a core region
  could be drawn on top of it and occlude small structures (e.g. neighbouring
  subcortical structures hiding the hypothalamic subunits). This matches the
  ordering already used by the `geom_brain()` / `as.data.frame()` path.

## ggseg.formats 0.0.3

### sf-optional atlas format

`sfheaders` joins Imports. **`sf` moves from Imports to Suggests.** The
package can now be installed without GDAL / GEOS / PROJ system libraries —
enabling wasm builds and air-gapped installs. Functions that genuinely need
sf (e.g. `validate_sf()`, `as.data.frame.ggseg_atlas()`, `plot.ggseg_atlas()`,
the `atlas_view_*` repositioning helpers) check `requireNamespace("sf")` at
entry and error with a clear pointer to `as_polygon_atlas()` if sf is
unavailable. The bundled `dk`, `aseg`, and `tracula` atlases still carry
their `sf` slots, so callers who have sf installed see no behavioural change.

- New `brain_polygons` representation: a nested tibble keyed by `label`, with a
  `geometry` list-column containing per-view, per-ring point coordinates
  (`view`, `x`, `y`, `group`, `subgroup`). Renderable directly by
  `geom_polygon()` via the `subgroup` aesthetic (which handles holes
  through `grid::pathGrob` even-odd fill).
- Geometry round-trips between sf and `brain_polygons` losslessly. The sf-side
  conversion uses `sfheaders` (pure Rcpp, no GDAL/GEOS/PROJ system libraries),
  enabling wasm builds and air-gapped installation paths. The low-level
  converters are internal; the public API is the atlas-level `as_sf_atlas()` /
  `as_polygon_atlas()` and the `atlas_sf()` / `atlas_polygons()` accessors.
- `validate_data_labels()` checks 2D label coverage against whichever 2D source
  is present (`sf` or `polygons`), preserving the same 80%/90% thresholds.
- New vignette `vignette("migrating-atlases")` — a three-line recipe for
  downstream atlas-package maintainers to migrate their `data/*.rda` to the
  sf-optional polygon format with `migrate_atlas_files()`.
- `as_polygon_atlas()` now aborts with an actionable message naming
  `migrate_atlas_files()` when it meets a still-sf-backed atlas on an install
  where `sf` is not available, instead of a generic "sf is required" error.

### Unified `geom` slot (breaking)

Atlas 2D geometry now lives in a single `atlas$data$geom` slot whose class
(`sf` or `brain_polygons`) determines the rendering path. The parallel `sf` and
`polygons` slots are gone — conversion between the two is lossless, so only one
representation is ever stored.

- New accessors: `atlas_geom()`, `atlas_polygons()`, `atlas_geometry_type()`,
  `is_atlas_sf()`, `is_atlas_polygon()`. `atlas_sf()` now converts from the
  polygon representation when needed and is the single interception point for
  ggseg plotting. `atlas_geom()` falls back to a legacy `sf` slot, so atlases
  built before this change keep working. Reverse dependencies should call these
  accessors rather than reaching into `atlas$data`.
- `ggseg_data_cortical()` / `ggseg_data_subcortical()` /
  `ggseg_data_cerebellar()` / `ggseg_data_tract()` now take a single `geom`
  argument. A released `sf` argument is still accepted via `...` (converted to
  polygons via `sf_to_polygons()`) with a deprecation warning.
- `as_polygon_atlas()` / `as_sf_atlas()` set the single `geom` slot.
- `migrate_atlas_files()` rewrites atlases to the single `geom` slot
  (polygons by default; `keep_sf = TRUE` stores sf). It walks a package's
  `data/` directory and rewrites every `ggseg_atlas` `.rda`. Intended for
  downstream atlas-package maintainers across the ggsegverse ecosystem.

### Base-R `plot()` (breaking)

`plot.ggseg_atlas()` is reimplemented with base graphics
(`graphics::polygon()` / `graphics::polypath()`), and **`ggplot2` is dropped
from Imports** — the package no longer depends on ggplot2 for its own plotting.

- `plot()` now returns the atlas invisibly rather than a `ggplot` object; it is
  called for its side effect. Each spatially separate piece (e.g. a hemisphere
  surface or a slice) is drawn in its own panel, arranged in a near-square grid
  for a legible overview of the atlas. Code that captured the return value to
  add ggplot2 layers (`plot(atlas) + ...`) must be updated.
- The `show.legend` argument is removed; the base-R plot draws no legend. Extra
  arguments in `...` are forwarded to the underlying `polygon()` / `polypath()`
  primitives (e.g. `lwd`, `border`).
- `vdiffr` is dropped from Suggests; the plot tests no longer snapshot SVG.

### `atlas_palette()` (breaking)

- `atlas_palette()` now takes a `ggseg_atlas` object only (its first argument
  is `atlas`). Looking an atlas up by name string (e.g. `atlas_palette("dk")`)
  is no longer supported — pass the atlas, e.g. `atlas_palette(dk())`.

### Bundled SUIT cerebellar atlas

- New `suit()` bundled atlas — the SUIT cerebellar parcellation (lobules + deep
  nuclei) from ggsegSUIT, stored in the sf-optional polygon (`geom`) format with
  3D vertices (lobules) and meshes (nuclei). ggseg.formats now ships one atlas of
  each kind: `dk()` (cortical), `aseg()` (subcortical), `tracula()` (tract),
  `suit()` (cerebellar).

### Region geometry operations

- New `atlas_region_op()` combines two sets of region geometry with a boolean
  operation per view (`difference`, `intersection`, `union`, `symdifference`),
  writing the result to a new region. Boolean ops need a geometry engine, so
  this helper always requires `sf`; a polygon-only atlas is rehydrated for the
  operation and the result returned in polygon form.
- `atlas_region_contextual()` now operates on whichever 2D representation an
  atlas carries (`sf` and/or `polygons`) and keeps both in sync — it needs no
  `sf` for a polygon-only atlas. It also gains an `ignore.case` argument.
- The atlas manipulation helpers no longer leave a stale `polygons` slot behind
  a freshly rewritten `sf` slot; the two 2D representations stay consistent
  after every operation.

### sf-free view manipulation

- `atlas_context_remove()`, `atlas_view_remove()`, `atlas_view_keep()`,
  `atlas_view_remove_region()`, `atlas_view_remove_small()`,
  `atlas_view_gather()`, and `atlas_view_reorder()` now run on polygon-only
  atlases with no `sf` installed. Filtering, polygon area (shoelace), and view
  repositioning are implemented in pure R against the `brain_polygons`
  coordinate table; the polygon results match the sf path to floating-point
  precision. sf-backed atlases continue to use the existing sf code path
  unchanged.
- `atlas_views()` reads view names from `polygons` when `sf` is absent.
- `atlas_region_keep()` and `atlas_region_remove()` no longer drop 2D geometry
  on polygon-only atlases (they previously rebuilt from the `sf` slot only).
- View helpers now warn about "no 2D geometry" (rather than "no sf data") only
  when an atlas carries neither `sf` nor `polygons`.

### Lighter dependency tree

- Dropped the `dplyr` and `tidyr` Imports in favour of base-R equivalents,
  shrinking the recursive dependency tree from 32 to 20 packages (also removes
  `tibble`, `pillar`, `purrr`, `stringi`, `stringr`, `tidyselect`, `generics`,
  `magrittr` and more). Returned data objects keep the `tbl_df`/`tbl` classes
  so they continue to integrate with `tibble`/`dplyr` workflows, but `tibble`
  is no longer required at install time.
- `print()` for a `ggseg_atlas` now shows the first 10 core rows by default
  (atlases can have hundreds of regions); pass `n` to control how many rows
  print, e.g. `print(dk(), n = 50)`.

### Bug fixes

- `atlas_sf()` no longer re-sorts geometry rows alphabetically by `label`. The
  underlying `merge()` defaulted to `sort = TRUE`, which discarded the
  context-behind-core draw order established by the manipulation helpers, so
  contextual regions could draw on top of focus regions. The ordering is now
  preserved and re-applied after the join, matching `as.data.frame()`.
- `atlas_type()` can again guess the type of an atlas whose `type` is unset:
  `guess_type()` now reads views from the unified `$data` geometry slot instead
  of the legacy bare `$sf` slot, which a modern `ggseg_atlas` never populates
  (it previously always guessed `"subcortical"`).
- `read_atlas_files()` extracts the subject id by stripping the `subjects_dir`
  prefix by length rather than as a regular expression, so directories
  containing regex metacharacters (or a trailing slash) no longer yield the
  wrong subject.
- `read_freesurfer_table(measure = )` strips the `_<measure>` suffix literally
  from the end of each label instead of with an unanchored regex, so a label
  that contains the measure mid-string is no longer over-stripped.
- `atlas_palette()` given a non-atlas object now errors with a class-specific
  message instead of interpolating the whole object into "Could not find
  atlas".

### Documentation & internals

- Corrected the package-level help page: the title and `?ggseg.formats` alias
  are now derived from `DESCRIPTION` (previously titled "Plot brain
  segmentations with ggplot" and aliased as `ggseg`).
- Dropped the vestigial `utils::globalVariables()` registration, which no
  longer referenced any global used by the package.
- Added a package hex logo: the brain as atlas data — dk lobes traced as a
  sparse "connect-the-dots" network of vertices and edges, in a plum take on
  the ggsegverse house style. Reproducible via `data-raw/make_hex.R`.
- The package now passes the full `goodpractice` + tidyverse check suite as a
  CI hard gate, at 100% line coverage. Formatting is enforced with `air` and
  linting with `lintr`.

## ggseg.formats 0.0.2

### Deep cerebellar nuclei support

- `ggseg_data_cerebellar()` gains an optional `meshes` parameter for deep
  cerebellar structures (e.g. dentate, interposed, fastigial nuclei) that
  are not on the SUIT cortical surface. Surface regions use `vertices`
  (shared SUIT mesh), deep structures use individual `meshes` (like
  subcortical atlases).
- Validation now checks the union of `vertices` + `meshes` labels against
  core when both are present, rather than requiring each to cover all labels
  independently.
- `rebuild_atlas_data()` preserves cerebellar data type and handles mixed
  vertices + meshes correctly.

### Bug fixes

- `reposition_views()` now handles `sfc_GEOMETRY` (mixed geometry types) by
  casting to `MULTIPOLYGON` before coordinate operations.
- `atlas_view_gather()` is more robust against non-sf or empty sf data,
  preventing errors in subcortical and tract pipelines.

## ggseg.formats 0.0.1

Initial CRAN release. Extracts and formalises the atlas data structures that
were previously embedded in `ggseg` and `ggseg3d`.

### Unified `ggseg_atlas` S3 class

- `ggseg_atlas()` constructor with typed data containers for cortical,
  subcortical, tract, and cerebellar atlases.
- Type-checking predicates: `is_ggseg_atlas()`, `is_cortical_atlas()`,
  `is_subcortical_atlas()`, `is_tract_atlas()`, `is_cerebellar_atlas()`.
- Coercion with `as_ggseg_atlas()`, `as.data.frame()`, and `as.list()`
  methods.
- `plot()` method for quick atlas visualisation via ggplot2.

### Accessors

- `atlas_type()`, `atlas_regions()`, `atlas_labels()`, `atlas_palette()`,
  `atlas_sf()`, `atlas_vertices()`, `atlas_meshes()`, and `atlas_views()`
  for querying atlas contents without reaching into slots.

### Atlas manipulation

- Pipe-friendly region operations: `atlas_region_keep()`,
  `atlas_region_remove()`, `atlas_region_rename()`,
  `atlas_region_contextual()`.
- Metadata enrichment with `atlas_core_add()`.
- View management: `atlas_view_keep()`, `atlas_view_remove()`,
  `atlas_view_remove_region()`, `atlas_view_remove_small()`,
  `atlas_view_gather()`, `atlas_view_reorder()`.

### Bundled atlases

- Ships three ready-to-use atlases: `dk()` (Desikan-Killiany cortical),
  `aseg()` (FreeSurfer subcortical), and `tracula()` (white matter tracts).
- `get_brain_mesh()` and `get_cerebellar_mesh()` provide 3D surface meshes
  for rendering.

### Legacy conversion

- `convert_legacy_brain_atlas()` and `unify_legacy_atlases()` bridge old
  `ggseg`/`ggseg3d` atlas objects to the unified format.
- Deprecated wrappers (`brain_atlas()`, `brain_regions()`, etc.) ease
  migration from the old API.

### FreeSurfer I/O

- `read_freesurfer_stats()`, `read_atlas_files()`, and
  `read_freesurfer_table()` for reading FreeSurfer statistics into R.
