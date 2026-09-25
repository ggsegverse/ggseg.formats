# Manipulate brain atlas regions and views

Functions for modifying brain atlas objects. These cover three areas:

## Usage

``` r
atlas_region_remove(atlas, pattern, match_on = c("region", "label"))

atlas_region_contextual(
  atlas,
  pattern,
  match_on = c("region", "label"),
  ignore.case = TRUE
)

atlas_region_op(
  atlas,
  x,
  y,
  action = c("difference", "intersection", "union", "symdifference"),
  into = NULL,
  match_on = c("label", "region"),
  colour = NULL
)

atlas_context_remove(atlas)

atlas_region_rename(
  atlas,
  pattern,
  replacement,
  match_on = c("region", "label")
)

atlas_region_keep(atlas, pattern, match_on = c("region", "label"))

atlas_core_add(atlas, data, by = "region")

atlas_view_remove(atlas, views)

atlas_view_keep(atlas, views)

atlas_view_remove_region(
  atlas,
  pattern,
  match_on = c("label", "region"),
  views = NULL
)

atlas_view_remove_small(
  atlas,
  min_area,
  views = NULL,
  scope = c("region", "piece"),
  labels = NULL,
  exclude = NULL
)

atlas_view_select(atlas, threshold = 0.5, weights = NULL)

atlas_view_gather(atlas, gap = 0.15)

atlas_view_reorder(atlas, order, gap = 0.15)
```

## Arguments

- atlas:

  A `ggseg_atlas` object

- pattern:

  Character pattern to match. Uses `grepl(..., ignore.case = TRUE)`.

- match_on:

  Column to match against: `"region"` or `"label"`.

- ignore.case:

  For `atlas_region_contextual()`: passed to
  [`grepl()`](https://rdrr.io/r/base/grep.html). Defaults to `TRUE` for
  backwards compatibility, but note that a context pattern like
  `"Thalamus"` then also matches focus labels such as `"hypothalamus"`;
  set `FALSE` (and/or anchor the pattern) when that matters.

- x, y:

  For `atlas_region_op()`: patterns selecting the two operands.

- action:

  For `atlas_region_op()`: the boolean operation to apply.

- into:

  For `atlas_region_op()`: label for the result region.

- colour:

  For `atlas_region_op()`: optional fill for `into`. When supplied,
  `into` is registered in core and palette; when `NULL`, the result is
  contextual geometry only.

- replacement:

  For `atlas_region_rename()`: replacement string or function.

- data:

  For `atlas_core_add()`: data.frame with metadata to join.

- by:

  For `atlas_core_add()`: column(s) to join by. Default `"region"`.

- views:

  For view functions: character vector of view names or patterns.
  Multiple values collapsed with `"|"` for matching.

- min_area:

  For `atlas_view_remove_small()`: minimum area to keep. What it applies
  to depends on `scope`; with the default `scope = "region"` context
  geometries are never removed.

- scope:

  Whether `min_area` applies to a label's whole geometry in a view
  (`"region"`, the default) or to each disconnected piece (`"piece"`).

- labels, exclude:

  For `atlas_view_remove_small()`: optional regex scoping which labels
  are considered. `labels` restricts removal to matching labels,
  `exclude` spares them. Only one may be given. Useful with
  `scope = "piece"`, where a thin structure such as a cortical ribbon
  has legitimately small pieces that should not be treated as specks.

- threshold:

  For `atlas_view_select()`: minimum share, between 0 and 1, of a
  region's best-view area that a view must hold to keep drawing it.
  Higher values are more aggressive.

- weights:

  For `atlas_view_select()`: optional named numeric vector of per-view
  multipliers applied before comparing areas. Overrides the automatic
  hemisphere-coverage weighting for the views named.

- gap:

  Proportional gap between views (default 0.15 = 15% of max width).

- order:

  For `atlas_view_reorder()`: character vector of desired view order.
  Unspecified views appended at end.

## Value

Modified `ggseg_atlas` object

## Details

**Region manipulation** modifies which regions are active in the atlas:

- `atlas_region_remove()`: completely remove regions

- `atlas_region_contextual()`: keep geometry but remove from
  core/palette

- `atlas_context_remove()`: drop all contextual sf geometry

- `atlas_region_rename()`: rename regions in core

- `atlas_region_keep()`: keep only matching regions

- `atlas_region_op()`: combine two regions' geometry with a boolean op
  (difference / intersection / union / symdifference)

**View manipulation** modifies the 2D sf geometry data:

- `atlas_view_remove()`: remove entire views

- `atlas_view_keep()`: keep only matching views

- `atlas_view_remove_region()`: remove specific region geometry from sf

- `atlas_view_remove_small()`: remove small regions, or stray specks

- `atlas_view_select()`: keep each region only in the views that show it
  well

- `atlas_view_gather()`: reposition views to close gaps

- `atlas_view_reorder()`: change view order

**Core manipulation** modifies atlas metadata:

- `atlas_core_add()`: join additional metadata columns

## Functions

- `atlas_region_contextual()`: Keep geometry for visual context but
  remove from core, palette, and 3D data. Context geometries render grey
  and don't appear in legends. Contextual rows are moved behind the
  remaining core regions so focus regions draw on top where they overlap
  in projection. Operates on whichever 2D representation the atlas
  carries (`sf` and/or `polygons`), keeping both in sync, and needs no
  `sf` for a polygon atlas.

- `atlas_region_op()`: Combine two sets of region geometry with a vector
  boolean operation (per view), writing the result to a new region
  `into`. `x` and `y` are patterns matched against `match_on`; within
  each view their matching geometries are unioned, then combined via
  `action`: `"difference"` (x minus y, e.g. punching white matter out of
  a cortex silhouette), `"intersection"`, `"union"`, or
  `"symdifference"`. Inputs are left in place; any existing `into`
  geometry is replaced. With a `colour`, `into` becomes a legended core
  region; otherwise it stays contextual (grey) and is drawn behind the
  core regions. Boolean ops need a geometry engine, so this is the one
  manipulation helper that always requires `sf` installed; a
  polygon-only atlas is rehydrated for the operation and the result is
  returned in polygon form.

- `atlas_context_remove()`: Drop all contextual sf geometry — every sf
  row whose `label` is not present in `core`. Covers labels marked via
  `atlas_region_contextual()` plus pipeline-generated outlines
  (`cortex_`, `Background`, `unknown`). Remaining views are re-packed
  via `atlas_view_gather()` so the plot focuses tightly on the labelled
  regions.

- `atlas_region_rename()`: Rename regions matching a pattern. Only ever
  writes to the `region` column, never to `label`. `match_on` chooses
  which column the pattern is matched and substituted against: the
  default `"region"` rewrites the display names in place, while
  `"label"` derives them from the source identifiers, so
  `atlas_region_rename(atlas, "^ctx-lh-", "", match_on = "label")` turns
  label `ctx-lh-superiorfrontal` into region `superiorfrontal`. If
  `replacement` is a function, it receives the matched values of that
  column and returns the new region names.

- `atlas_region_keep()`: Keep only matching regions. Non-matching
  regions are removed from core, palette, and 3D data but sf geometry is
  preserved for surface continuity.

- `atlas_core_add()`: Join additional metadata columns to atlas core.

- `atlas_view_remove()`: Remove views matching pattern from sf data.
  Remaining views are re-packed via `atlas_view_gather()` so the layout
  stays tight.

- `atlas_view_keep()`: Keep only views matching pattern.

- `atlas_view_remove_region()`: Remove specific region geometry from sf
  data only. Core, palette, and 3D data are unchanged. Views are
  re-packed via `atlas_view_gather()` in case any view shrank.

- `atlas_view_remove_small()`: Remove geometry below a minimum area
  threshold. With `scope = "region"` (the default) a label's whole
  geometry in a view is removed when its combined area is too small, and
  context geometries (labels not in core) are never removed. With
  `scope = "piece"` individual disconnected pieces are removed while the
  rest of the region stays – use this to clear stray specks left by
  volumetric projection. A region's largest piece in a view is always
  kept, so no region disappears, and context is cleaned too. Optionally
  scope to specific views. Views are re-packed via `atlas_view_gather()`
  in case any view shrank.

- `atlas_view_select()`: Keep each region only in the views that show it
  well.

  A slice or projection slab catches a structure in cross-section as
  readily as along its length, so most regions leave a sliver in most
  views. That leaves every panel cluttered and every region drawn
  several times over. A region is kept only where it is substantially
  represented: in any view holding at least `threshold` of the area it
  reaches in its best view.

  Regions are compared as a whole, across all the labels that share a
  `region` in `core`, so bilateral structures stay together – assigning
  left and right independently splits pairs across panels, which reads
  as an error rather than a choice. Every region is guaranteed to
  survive in at least one view, and context geometry (labels absent from
  `core`, such as a cortical outline) is never touched.

  Single-hemisphere views are the awkward case: a sagittal panel cuts
  one hemisphere while axial and coronal panels show both, so on raw
  area it loses every comparison and empties out. Such views are
  detected from the hemispheres actually present in each view and their
  areas scaled to match, so they compete fairly. Pass `weights` to
  override.

- `atlas_view_gather()`: Reposition remaining views to close gaps after
  view removal.

- `atlas_view_reorder()`: Reorder views and reposition. Views not in
  `order` are appended at end.

## See also

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

Other atlas manipulations:
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

## Examples

``` r
dk() |>
  atlas_region_remove("bankssts") |>
  atlas_region_keep("frontal", match_on = "region")
#> 
#> ── dk ggseg atlas ──────────────────────────────────────────────────────────────
#> Type: cortical
#> Regions: 6
#> Hemispheres: left, right
#> Views: inferior, lateral, medial, superior
#> Palette: ✔
#> Rendering: ✔ ggseg
#> ✔ ggseg3d (vertices)
#> ────────────────────────────────────────────────────────────────────────────────
#>     hemi               region                   label                  names
#> 1   left  caudalmiddlefrontal  lh_caudalmiddlefrontal  caudal middle frontal
#> 2   left lateralorbitofrontal lh_lateralorbitofrontal  lateral orbitofrontal
#> 3   left  medialorbitofrontal  lh_medialorbitofrontal   medial orbitofrontal
#> 4   left rostralmiddlefrontal lh_rostralmiddlefrontal rostral middle frontal
#> 5   left      superiorfrontal      lh_superiorfrontal       superior frontal
#> 6   left          frontalpole          lh_frontalpole           frontal pole
#> 7  right  caudalmiddlefrontal  rh_caudalmiddlefrontal  caudal middle frontal
#> 8  right lateralorbitofrontal rh_lateralorbitofrontal  lateral orbitofrontal
#> 9  right  medialorbitofrontal  rh_medialorbitofrontal   medial orbitofrontal
#> 10 right rostralmiddlefrontal rh_rostralmiddlefrontal rostral middle frontal
#>       lobe
#> 1  frontal
#> 2  frontal
#> 3  frontal
#> 4  frontal
#> 5  frontal
#> 6  frontal
#> 7  frontal
#> 8  frontal
#> 9  frontal
#> 10 frontal
#> ... with 2 more rows
```
