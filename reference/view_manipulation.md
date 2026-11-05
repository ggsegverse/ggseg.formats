# Change which views an atlas has, and where they sit

Verbs that act on views as objects:

## Usage

``` r
atlas_view_remove(atlas, views)

atlas_view_keep(atlas, views)

atlas_view_gather(atlas, gap = 0.15)

atlas_view_reorder(atlas, order, gap = 0.15)
```

## Arguments

- atlas:

  A `ggseg_atlas` object

- views:

  Character vector of view names or patterns. Multiple values are
  collapsed with `"|"` for matching.

- gap:

  Proportional gap between views (default 0.15 = 15% of max width).

- order:

  For `atlas_view_reorder()`: character vector of desired view order.
  Unspecified views appended at end.

## Value

Modified `ggseg_atlas` object

## Details

- `atlas_view_remove()`: remove entire views

- `atlas_view_keep()`: keep only matching views

- `atlas_view_reorder()`: change view order

- `atlas_view_gather()`: reposition views to close gaps

None of these changes what is drawn inside a view. For that — dropping a
region's depiction in some views while the region itself stays — see
[drawing_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md).

## Functions

- `atlas_view_keep()`: Keep only views matching pattern. Remaining views
  are re-packed via `atlas_view_gather()` so the layout stays tight, as
  `atlas_view_remove()` does.

- `atlas_view_gather()`: Reposition remaining views to close gaps after
  view removal.

- `atlas_view_reorder()`: Reorder views and reposition. Views not in
  `order` are appended at end.

## See also

[atlas_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
for the other groups

Other atlas manipulations:
[`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core_add.md),
[`atlas_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md),
[`drawing_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md),
[`region_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/region_manipulation.md),
[`relabel_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/relabel_atlas.md)

## Examples

``` r
# Views are named by the atlas, so ask it rather than naming one here.
dk() |> atlas_view_keep(atlas_views(dk())[1])
#> 
#> ── dk ggseg atlas ──────────────────────────────────────────────────────────────
#> Type: cortical
#> Regions: 35
#> Hemispheres: left, right
#> Views: inferior
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
