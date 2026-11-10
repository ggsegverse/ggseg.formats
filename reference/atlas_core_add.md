# Join additional metadata columns to an atlas's core

Adds columns to `core`, never rows: `data` must hold unique values of
`by`. Use it to carry a classification — a lobe, a network, a study's
own grouping — alongside the atlas's own metadata.

## Usage

``` r
atlas_core_add(atlas, data, by = "region")
```

## Arguments

- atlas:

  A `ggseg_atlas` object

- data:

  A data.frame with metadata to join.

- by:

  Column(s) to join by. Default `"region"`.

## Value

Modified `ggseg_atlas` object

## See also

[atlas_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
for the other groups

Other atlas manipulations:
[`atlas_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
[`atlas_relabel()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_relabel.md),
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md),
[`drawing_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md),
[`region_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/region_manipulation.md),
[`view_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md)

## Examples

``` r
lobes <- data.frame(region = atlas_regions(dk())[1:2], network = c("a", "b"))
atlas_core_add(dk(), lobes)
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
#>                              display         lobe network
#> 1  banks of superior temporal sulcus     temporal       a
#> 2          caudal anterior cingulate    cingulate       b
#> 3              caudal middle frontal      frontal    <NA>
#> 4                    corpus callosum white matter    <NA>
#> 5                             cuneus    occipital    <NA>
#> 6                         entorhinal     temporal    <NA>
#> 7                           fusiform     temporal    <NA>
#> 8                  inferior parietal     parietal    <NA>
#> 9                  inferior temporal     temporal    <NA>
#> 10                 isthmus cingulate    cingulate    <NA>
#> ... with 60 more rows
```
