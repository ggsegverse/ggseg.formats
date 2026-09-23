# ggseg.formats

## ggseg.formats 0.0.4.9006 (development)

- `atlas_region_rename()` gains `match_on`, bringing it in line with the rest
  of the `atlas_region_*` family. It still only ever writes to `region`;
  `match_on` chooses the column the pattern is matched and substituted
  against. The default `"region"` is the existing behaviour, while `"label"`
  derives display names from the source identifiers, so
  `atlas_region_rename(atlas, "^ctx-lh-", "", match_on = "label")` turns label
  `ctx-lh-superiorfrontal` into region `superiorfrontal`.

## ggseg.formats 0.0.4.9005 (development)

- `plot()` on an atlas whose palette cannot tell its regions apart now falls
  back to automatically assigned, distinguishable colours instead of drawing
  the atlas faithfully as one solid silhouette. Several atlases are built from
  colour lookup tables that give every region `0 0 0`, so they rendered as a
  black brain in which no parcel could be told from its neighbour, and in the
  subcortical ones the grey `cortex_` backdrop went black too and read as a
  region. A palette counts as unusable only when every one of the atlas's
  regions resolves to a single colour: a palette that is merely dark, or an
  atlas with a single region, is left alone. Contextual geometry -- the
  `cortex_` silhouette and the `unknown` medial wall, whether or not the atlas
  keeps them in `core` -- stays its conventional grey in the fallback, so
  backdrop is never mistaken for a parcel. Falling back warns and names the
  atlas, because the real fix belongs in the atlas's lookup table.

- New `atlas_plot_palette()` exposes that decision, returning the atlas palette
  when it is usable and the fallback when it is not. Downstream renderers
  should read the palette through it rather than reaching for `atlas$palette`.

## ggseg.formats 0.0.4.9004 (development)

- New `atlas_structure_reorder()` moves structures within an atlas's geometry
  the way `dplyr::relocate()` moves columns, with `.before` and `.after`
  anchors. Geometry rows are drawn in the order they appear, so this is what
  decides which structure is painted over which where two overlap - common in
  subcortical atlases, where a thick slab flattens structures onto one panel
  that never touch in the brain. Note that the order belongs to the structure
  rather than to a view: an atlas holds one geometry row per structure with
  its views nested inside, so a structure keeps the same depth everywhere it
  is drawn.

- `atlas_view_reorder()` now reorders the geometry rows as well as
  repositioning them, so the new order actually shows up in a plot.
  Consumers read view order off the row order - `ggseg::geom_brain()` lays
  panels out in the order it meets the views - so moving the coordinates
  without moving the rows left the plot unchanged. The sf branch always
  rebuilt its rows group by group; the pure-R polygon branch, which every
  bundled atlas has used since the sf-optional migration, did not. The
  reposition parity tests compared coordinates only, which is how it went
  unnoticed; they now compare row order too.

- New `atlas_centerlines()` accessor returns a tract atlas's centerlines,
  joined with core region info and palette colours, like `atlas_meshes()` and
  `atlas_vertices()` do for the other geometry types. A tract atlas represents
  each pathway as a curve swept into a tube rather than as a stored surface,
  so the centerline is the geometry that defines it — and it was the one
  payload with no getter, leaving callers reaching into `atlas$data`.

- New `atlas_view_select()` keeps each region only in the views that show it
  well. A slice or projection slab catches a structure in cross-section as
  readily as along its length, so most regions leave a sliver in most views,
  leaving every panel cluttered and every region drawn several times over. A
  region is kept only where it holds at least `threshold` of the area it
  reaches in its best view.

  Regions are compared as a whole, across the labels sharing a `region` in
  `core`, so bilateral structures stay together — assigning left and right
  independently splits pairs across panels, which reads as an error rather
  than a choice. Every region survives in at least one view, and context
  geometry is never touched. Single-hemisphere views (a sagittal panel cuts
  one hemisphere while axial and coronal panels show both) are detected from
  the hemispheres actually present and weighted up so they compete fairly;
  `weights` overrides this per view.

  This was previously hand-rolled in atlas build scripts, where it ran to
  roughly ninety lines apiece and drifted between them.

## ggseg.formats 0.0.4.9003 (development)

- New `set_atlas_palette()` setter replaces a palette without requiring users to assign `atlas$palette` directly; it validates the value and warns if the new palette does not cover every atlas label.
- New `set_atlas_type()` setter replaces an atlas type without assigning
  `atlas$type` directly. Type is coupled to both the `<type>_atlas` subclass and
  the `ggseg_data_<type>` payload class, so a direct field assignment leaves the
  subclass stale and `is_tract_atlas()` disagreeing with `atlas_type()`. The
  setter reconstructs through `ggseg_atlas()`, so it keeps all three in
  agreement and errors when the payload does not match the requested type.
- `plot()` now draws atlas panels in the order the views are laid out, so
  `atlas_view_reorder()` is reflected in the output. Panels were previously
  ordered by the sequence in which views appeared in the underlying row table;
  for `brain_polygons` those rows nest by `label`, so the order depended on
  which views the first label happened to carry — neither following the atlas
  layout nor stable across atlases. Panels are now ordered by position.
- The exported API is now organised into three documented families
  (`@family`): **atlas accessors** (read-only getters such as `atlas_palette()`,
  `atlas_labels()`), **atlas setters** (`set_atlas_palette()`), and **atlas
  manipulations** (structural transforms such as `atlas_region_rename()`,
  `atlas_view_reorder()`). Accessors are pure getters — there is no
  `atlas_palette<-()` replacement form.

## ggseg.formats 0.0.4.9001

### Atlas data

- The bundled `dk()`, `aseg()`, and `tracula()` atlases now carry a `names`
  column holding the fully spelled-out region name, and their `region` column
  holds a cleaned, hemisphere-free short name derived from `label` (for example
  `region` `"bankssts"` alongside `names` `"banks of superior temporal sulcus"`).
  Code that filtered on the previously prettified `region` values should switch
  to `names`. The `aseg` atlas also drops duplicate rows left over from the
  previous label matching (47 to 29 rows).
- The bundled atlases were rebuilt with lighter geometry: `dk` polygons are
  simplified (roughly a quarter of the previous vertex count) and the `aseg`
  cortex silhouette is smoothed without inflating, shrinking `R/sysdata.rda`
  from 3.4 MB to 2.1 MB. Figures are visually unchanged.

### Bug fixes

- `plot()` now divides a view into panels by hemisphere where the atlas makes
  that division unambiguous, instead of always guessing panel boundaries from
  coordinate gaps. The old heuristic split only on gaps wider than 12% of the
  view's total span, so atlases whose hemispheres sat a little closer together
  collapsed into a single wide panel and drew both hemispheres at a third of
  their proper size. A view is only split this way when both hemispheres are
  present, their extents are disjoint, and every midline structure and
  contextual silhouette falls wholly inside one of them; anything spanning the
  divide keeps the view whole, so no region is clipped out of the figure.
  Views the hemisphere rule cannot resolve still fall back to gap splitting.
  Of the bundled atlases only `suit()` changes, gaining a second panel that
  renders the deep nuclei at a legible size (#18).

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
