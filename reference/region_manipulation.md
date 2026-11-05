# Change which regions an atlas has

Verbs that modify the regions `core` declares, and the geometry that
does or does not belong to them:

## Usage

``` r
atlas_region_remove(atlas, pattern, match_on = c("label", "region"))

atlas_region_contextual(
  atlas,
  pattern,
  match_on = c("label", "region"),
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
  match_on = c("label", "region")
)

atlas_region_keep(atlas, pattern, match_on = c("label", "region"))
```

## Arguments

- atlas:

  A `ggseg_atlas` object

- pattern:

  Character pattern to match. Uses `grepl(..., ignore.case = TRUE)`.

- match_on:

  Column of `core` to match against: `"label"`, the default, or
  `"region"`. `label` is the identifier that is unique within an atlas
  and stable across them, so every verb that selects rows by name or
  pattern reads it unless told otherwise.

- ignore.case:

  For `atlas_region_contextual()`: passed to
  [`grepl()`](https://rdrr.io/r/base/grep.html). Defaults to `TRUE` for
  backwards compatibility, but note that a context pattern like
  `"Thalamus"` then also matches focus labels such as `"hypothalamus"`;
  set `FALSE` (and/or anchor the pattern) when that matters.

- x, y:

  For `atlas_region_op()`: patterns selecting the two operands, or a
  selector such as
  [`context()`](https://ggsegverse.github.io/ggseg.formats/reference/selectors.md)
  or
  [`regions()`](https://ggsegverse.github.io/ggseg.formats/reference/selectors.md).

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

## Value

Modified `ggseg_atlas` object

## Details

- `atlas_region_remove()`: completely remove regions

- `atlas_region_keep()`: keep only matching regions

- `atlas_region_rename()`: rename regions in core

- `atlas_region_contextual()`: keep geometry but remove from
  core/palette

- `atlas_context_remove()`: drop all contextual geometry

- `atlas_region_op()`: combine two regions' geometry with a boolean op
  (difference / intersection / union / symdifference)

To drop a region's drawing in some views while keeping the region
itself, see
[drawing_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md).

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
  via
  [`atlas_view_gather()`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md)
  so the plot focuses tightly on the labelled regions.

- `atlas_region_rename()`: Rename regions matching a pattern. Only ever
  writes to the `region` column, never to `label`. `match_on` chooses
  the rows: those whose `label` (the default) or `region` matches
  `pattern`. The edit is always made to the region text those rows
  already have. A string `replacement` is substituted for `pattern`
  wherever the region contains it, so
  `atlas_region_rename(atlas, "Left-", "")` strips the prefix from
  regions that still carry it. A function `replacement` receives the
  regions of the matching rows and returns the new ones, which is how to
  set a region outright for a label:
  `atlas_region_rename(atlas, "^Brain-Stem$", \(region) "brainstem")`. A
  string that changes nothing, because the pattern is in the labels but
  not in their regions, is reported with a warning.

- `atlas_region_keep()`: Keep only matching regions. Non-matching
  regions are removed from core, palette, and 3D data but sf geometry is
  preserved for surface continuity.

## See also

[atlas_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
for the other groups

Other atlas manipulations:
[`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core_add.md),
[`atlas_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md),
[`drawing_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md),
[`relabel_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/relabel_atlas.md),
[`view_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md)

## Examples

``` r
# Regions are named by the atlas, so take them from it rather than
# spelling them out here, where they would go stale unnoticed.
first_region <- atlas_regions(dk())[1]
dk() |> atlas_region_remove(first_region, match_on = "region")
#> 
#> ── dk ggseg atlas ──────────────────────────────────────────────────────────────
#> Type: cortical
#> Regions: 34
#> Hemispheres: left, right
#> Views: inferior, lateral, medial, superior
#> Palette: ✔
#> Rendering: ✔ ggseg
#> ✔ ggseg3d (vertices)
#> ────────────────────────────────────────────────────────────────────────────────
#>    hemi                  region                      label
#> 1  left caudalanteriorcingulate lh_caudalanteriorcingulate
#> 2  left     caudalmiddlefrontal     lh_caudalmiddlefrontal
#> 3  left          corpuscallosum          lh_corpuscallosum
#> 4  left                  cuneus                  lh_cuneus
#> 5  left              entorhinal              lh_entorhinal
#> 6  left                fusiform                lh_fusiform
#> 7  left        inferiorparietal        lh_inferiorparietal
#> 8  left        inferiortemporal        lh_inferiortemporal
#> 9  left        isthmuscingulate        lh_isthmuscingulate
#> 10 left        lateraloccipital        lh_lateraloccipital
#>                      display         lobe
#> 1  caudal anterior cingulate    cingulate
#> 2      caudal middle frontal      frontal
#> 3            corpus callosum white matter
#> 4                     cuneus    occipital
#> 5                 entorhinal     temporal
#> 6                   fusiform     temporal
#> 7          inferior parietal     parietal
#> 8          inferior temporal     temporal
#> 9          isthmus cingulate    cingulate
#> 10         lateral occipital    occipital
#> ... with 58 more rows
```
