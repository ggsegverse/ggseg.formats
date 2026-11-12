# Change which regions are drawn inside a view

Verbs that prune depictions, each by a different criterion:

## Usage

``` r
atlas_prune_region(
  atlas,
  pattern,
  match_on = c("label", "region"),
  views = NULL,
  match = c("exact", "pattern")
)

atlas_prune_small(
  atlas,
  min_area,
  views = NULL,
  scope = c("region", "piece"),
  labels = NULL,
  exclude = NULL,
  match = c("exact", "pattern")
)

atlas_prune_weak(atlas, threshold = 0.5, weights = NULL)

atlas_view_select(atlas, threshold = 0.5, weights = NULL)

atlas_view_remove_region(
  atlas,
  pattern,
  match_on = c("label", "region"),
  views = NULL,
  match = c("exact", "pattern")
)

atlas_view_remove_small(
  atlas,
  min_area,
  views = NULL,
  scope = c("region", "piece"),
  labels = NULL,
  exclude = NULL,
  match = c("exact", "pattern")
)
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

- views:

  Views to scope the pruning to, or `NULL` (the default) for every view.
  Matched whole and case-insensitively against the atlas's own views, so
  a name has to be one
  [`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md)
  reports. Give them as a character vector, or in one string separated
  by `"|"`; the two are equivalent. Names that match no view are warned
  about and otherwise ignored.

- match:

  How `views` is read. `"exact"`, the default, takes each name as a
  whole view name. `"pattern"` takes `views` as a regular expression
  instead, matched as a substring — `"axial"` then reaches `axial_1` and
  `axial_2` as well. Prefer `"exact"`: a name that happens to sit inside
  another view's name silently scopes to both views under `"pattern"`.

- min_area:

  For `atlas_prune_small()`: minimum area to keep. What it applies to
  depends on `scope`; with the default `scope = "region"` context
  geometries are never removed.

- scope:

  Whether `min_area` applies to a label's whole geometry in a view
  (`"region"`, the default) or to each disconnected piece (`"piece"`).

- labels, exclude:

  For `atlas_prune_small()`: optional regex scoping which labels are
  considered. `labels` restricts removal to matching labels, `exclude`
  spares them. Only one may be given. Useful with `scope = "piece"`,
  where a thin structure such as a cortical ribbon has legitimately
  small pieces that should not be treated as specks.

- threshold:

  For `atlas_prune_weak()`: minimum share, between 0 and 1, of a
  region's best-view area that a view must hold to keep drawing it.
  Higher values are more aggressive.

- weights:

  For `atlas_prune_weak()`: optional named numeric vector of per-view
  multipliers applied before comparing areas. Overrides the automatic
  hemisphere-coverage weighting for the views named.

## Value

Modified `ggseg_atlas` object

## Details

- `atlas_prune_region()`: by name

- `atlas_prune_small()`: by absolute area

- `atlas_prune_weak()`: by area as a share of the region's best view

None of these adds a view, and none removes a region from `core`: the
region stays and is still legended, while its depiction in some view
goes. A view can still disappear as a consequence — `atlas_prune_weak()`
drops a view that keeps no region, and the other two drop a view whose
last remaining geometry they removed.

`atlas_prune_small()` and `atlas_prune_weak()` are the same operation
asked two ways, an absolute area against a share of the region's largest
appearance, with one difference that decides between them:
`atlas_prune_weak()` keeps every region in at least one view, while
`atlas_prune_small()` with the default `scope = "region"` can take a
region's geometry out of every view, leaving it legended but drawn
nowhere — and the higher the threshold, the more regions that happens
to. Check
[`atlas_undrawn()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_undrawn.md)
after raising `min_area`.

For views as objects, see
[view_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md);
to remove a region from the atlas altogether,
[region_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/region_manipulation.md).

## Functions

- `atlas_prune_small()`: Remove geometry below a minimum area threshold.
  With `scope = "region"` (the default) a label's whole geometry in a
  view is removed when its combined area is too small, and context
  geometries (labels not in core) are never removed. With
  `scope = "piece"` individual disconnected pieces are removed while the
  rest of the region stays – use this to clear stray specks left by
  volumetric projection. A region's largest piece anywhere in the atlas
  is always kept, so no region disappears – a speck in one view goes
  when the same region is drawn properly in another. Context is cleaned
  too. Optionally scope to specific views. Views are re-packed via
  [`atlas_view_gather()`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md)
  in case any view shrank.

- `atlas_prune_weak()`: Keep each region only in the views that show it
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

  What it costs. The shares are spread rather than clustered, so no
  threshold separates slivers from substance: on the bundled
  [`aseg()`](https://ggsegverse.github.io/ggseg.formats/reference/aseg.md)
  the median depiction outside a region's best view still holds 56% of
  it. Raising `threshold` buys a less crowded figure by dropping
  depictions that are anatomically real, and
  [`atlas_undrawn()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_undrawn.md)
  will not report the loss, because every region is kept somewhere. Look
  at the views.

- `atlas_view_select()`: Deprecated. Use `atlas_prune_weak()`: the old
  name read as the verb for choosing which views an atlas keeps, which
  is
  [`atlas_view_keep()`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md),
  and not for choosing which views draw a region.

- `atlas_view_remove_region()`: Deprecated. Use `atlas_prune_region()`:
  the old name read as a verb on views, when it removes no view — the
  region stays in `core` and only its depiction in the named views goes.
  For removing views themselves see
  [`atlas_view_remove()`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md).

- `atlas_view_remove_small()`: Deprecated. Use `atlas_prune_small()`:
  the old name read as a verb on views, when it removes no view. Note
  the near-namesake in ggseg.extra, `atlas_view_remove_sparse()`, which
  really does drop views; the two were a letter apart in intent and are
  not any more.

## See also

[atlas_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
for the other groups

Other atlas manipulations:
[`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core_add.md),
[`atlas_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
[`atlas_relabel()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_relabel.md),
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md),
[`region_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/region_manipulation.md),
[`view_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md)

## Examples

``` r
dk() |> atlas_prune_small(min_area = 10)
#> ℹ Removed 10 geometries below area 10
#> 
#> ── dk ggseg atlas ──────────────────────────────────────────────────────────────
#> Type: cortical
#> Regions: 35
#> Hemispheres: left, right
#> Views: inferior, lateral, medial, superior
#> Palette: ✔
#> Rendering: ✔ ggseg
#> ✔ ggseg3d (vertices)
#> ────────────────────────────────────────────────────────────────────────────────
#>    hemi                  region                      label
#> 1  left                bankssts                lh_bankssts
#> 2  left caudalanteriorcingulate lh_caudalanteriorcingulate
#> 3  left     caudalmiddlefrontal     lh_caudalmiddlefrontal
#> 4  left          corpuscallosum          lh_corpuscallosum
#> 5  left                  cuneus                  lh_cuneus
#> 6  left              entorhinal              lh_entorhinal
#> 7  left                fusiform                lh_fusiform
#> 8  left        inferiorparietal        lh_inferiorparietal
#> 9  left        inferiortemporal        lh_inferiortemporal
#> 10 left        isthmuscingulate        lh_isthmuscingulate
#>                              display         lobe
#> 1  banks of superior temporal sulcus     temporal
#> 2          caudal anterior cingulate    cingulate
#> 3              caudal middle frontal      frontal
#> 4                    corpus callosum white matter
#> 5                             cuneus    occipital
#> 6                         entorhinal     temporal
#> 7                           fusiform     temporal
#> 8                  inferior parietal     parietal
#> 9                  inferior temporal     temporal
#> 10                 isthmus cingulate    cingulate
#> ... with 60 more rows
```
