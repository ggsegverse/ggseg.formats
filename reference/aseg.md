# FreeSurfer Automatic Subcortical Segmentation Atlas

Returns the FreeSurfer automatic subcortical segmentation (aseg) atlas
containing deep brain structures including the thalamus, caudate,
putamen, pallidum, hippocampus, amygdala, accumbens, and ventricles.

## Usage

``` r
aseg()
```

## Value

A `ggseg_atlas` object with components:

- atlas:

  Character. Atlas name ("aseg")

- type:

  Character. Atlas type ("subcortical")

- palette:

  Named character vector of colours for each region

- data:

  A `ggseg_data_subcortical` object containing:

  meshes

  :   Data frame with `label` and `mesh` columns

  sf

  :   Simple features data frame for 2D rendering

## Details

This atlas is derived from FreeSurfer's `aseg.mgz` volumetric
segmentation. It works with both ggseg (2D slice views) and ggseg3d (3D
mesh visualizations) from a single object.

## Core columns

`core` carries one row per atlas region with the columns `hemi`,
`region`, `label` and `names`, plus the atlas's own grouping column.
`label` is the stable atlas identifier and the key the palette and the
geometry are keyed on; `region` is a short, hemisphere-free key derived
from it; `names` is the curated long-form display name, spelled out to
read well in a figure legend.

`region` held the long-form name until version 0.1.0. `names` is not a
record of those old values – use
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)
to translate them.

## Structures

The atlas contains bilateral structures:

- Thalamus

- Caudate

- Putamen

- Pallidum (globus pallidus)

- Hippocampus

- Amygdala

- Accumbens (nucleus accumbens)

- Ventral diencephalon

Plus midline and ventricular structures:

- Lateral ventricles

- Third ventricle

- Fourth ventricle

- Brain stem

- Cerebellar cortex

- Cerebellar white matter

## References

Fischl B, Salat DH, Busa E, et al. (2002). Whole brain segmentation:
automated labeling of neuroanatomical structures in the human brain.
Neuron, 33(3):341-355.
[doi:10.1016/S0896-6273(02)00569-X](https://doi.org/10.1016/S0896-6273%2802%2900569-X)

## See also

[`dk()`](https://ggsegverse.github.io/ggseg.formats/reference/dk.md) for
cortical parcellation,
[`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)
for the atlas class constructor

Other ggseg_atlases:
[`dk()`](https://ggsegverse.github.io/ggseg.formats/reference/dk.md),
[`suit()`](https://ggsegverse.github.io/ggseg.formats/reference/suit.md),
[`tracula()`](https://ggsegverse.github.io/ggseg.formats/reference/tracula.md)

## Examples

``` r
aseg()
#> 
#> ── aseg ggseg atlas ────────────────────────────────────────────────────────────
#> Type: subcortical
#> Regions: 18
#> Hemispheres: left, NA, right
#> Views: axial_3, axial_4, axial_5, axial_6, coronal_1, coronal_2, sagittal
#> Palette: ✔
#> Rendering: ✔ ggseg
#> ✔ ggseg3d (meshes)
#> ────────────────────────────────────────────────────────────────────────────────
#>    hemi            region                  label                names
#> 1  left cerebellum cortex Left-Cerebellum-Cortex    cerebellum cortex
#> 2  left          thalamus          Left-Thalamus             thalamus
#> 3  left           caudate           Left-Caudate              caudate
#> 4  left           putamen           Left-Putamen              putamen
#> 5  left          pallidum          Left-Pallidum             pallidum
#> 6  <NA>        brain stem             Brain-Stem           brain stem
#> 7  left       hippocampus       Left-Hippocampus          hippocampus
#> 8  left          amygdala          Left-Amygdala             amygdala
#> 9  left    accumbens area    Left-Accumbens-area            accumbens
#> 10 left         ventraldc         Left-VentralDC ventral diencephalon
#>        structure
#> 1     cerebellum
#> 2  basal ganglia
#> 3  basal ganglia
#> 4  basal ganglia
#> 5  basal ganglia
#> 6      brainstem
#> 7         limbic
#> 8         limbic
#> 9  basal ganglia
#> 10  diencephalon
#> ... with 19 more rows
plot(aseg())

atlas_regions(aseg())
#>  [1] "cerebellum cortex" "thalamus"          "caudate"          
#>  [4] "putamen"           "pallidum"          "brain stem"       
#>  [7] "hippocampus"       "amygdala"          "accumbens area"   
#> [10] "ventraldc"         "vessel"            "choroid plexus"   
#> [13] "cerebellum cortex" "thalamus"          "caudate"          
#> [16] "putamen"           "pallidum"          "hippocampus"      
#> [19] "amygdala"          "accumbens area"    "ventraldc"        
#> [22] "vessel"            "choroid plexus"    "optic chiasm"     
#> [25] "cc posterior"      "cc mid posterior"  "cc central"       
#> [28] "cc mid anterior"   "cc anterior"      
```
