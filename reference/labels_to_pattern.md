# Match labels literally where a verb takes a pattern

The region verbs take a regular expression, but a label is not one:
`lh_V5-MT+_L` (Brainnetome) reads its `+` as a quantifier and matches
nothing, the FreeSurfer medial wall is spelled
`Background+FreeSurfer_Defined_Medial_Wall`, and a label holding a
bracket does not compile at all. This escapes each label and anchors the
result.

## Usage

``` r
labels_to_pattern(labels)
```

## Arguments

- labels:

  Character vector of labels to match literally.

## Value

A single anchored pattern string. An empty `labels` gives a pattern that
matches nothing.

## Details

An empty `labels` has to match nothing, where `"^(|)$"` would match
everything. `"$x"` is a character after the end of the string, which
nothing satisfies, and unlike a negative lookahead it is valid in the
default engine.

## See also

[drawing_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md),
[region_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/region_manipulation.md)

Other atlas manipulations:
[`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core_add.md),
[`atlas_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
[`atlas_relabel()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_relabel.md),
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md),
[`drawing_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md),
[`region_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/region_manipulation.md),
[`view_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md)

## Examples

``` r
labels_to_pattern(c("lh_bankssts", "rh_bankssts"))
#> [1] "^(lh_bankssts|rh_bankssts)$"

dk() |> atlas_prune_region(labels_to_pattern("lh_bankssts"))
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
