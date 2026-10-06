# SUIT Cerebellar Lobular Atlas

Returns the SUIT cerebellar parcellation (Diedrichsen et al., 2009): the
cerebellar cortex split into anatomical lobules plus the deep nuclei
(dentate, interposed, fastigial).

## Usage

``` r
suit()
```

## Value

A `ggseg_atlas` object with components:

- atlas:

  Character. Atlas name ("suit")

- type:

  Character. Atlas type ("cerebellar")

- palette:

  Named character vector of colours for each region

- data:

  A `ggseg_data_cerebellar` object containing:

  geom

  :   A `brain_polygons` table for 2D rendering

  vertices

  :   Vertex indices for surface lobules

  meshes

  :   Per-structure 3D meshes for the deep nuclei

## Details

Surface lobules carry vertex indices into the shared SUIT cerebellar
mesh (see
[`get_cerebellar_mesh()`](https://ggsegverse.github.io/ggseg.formats/reference/get_cerebellar_mesh.md));
deep nuclei carry individual 3D meshes. The 2D geometry is stored in the
sf-optional polygon (`geom`) representation, so the atlas renders with
ggseg without requiring sf installed.

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

## References

Diedrichsen J, Balsters JH, Flavell J, et al. (2009). A probabilistic MR
atlas of the human cerebellum. NeuroImage, 46(1):39-46.
[doi:10.1016/j.neuroimage.2009.01.045](https://doi.org/10.1016/j.neuroimage.2009.01.045)

## See also

[`dk()`](https://ggsegverse.github.io/ggseg.formats/reference/dk.md) for
cortical parcellation,
[`aseg()`](https://ggsegverse.github.io/ggseg.formats/reference/aseg.md)
for subcortical structures,
[`tracula()`](https://ggsegverse.github.io/ggseg.formats/reference/tracula.md)
for white-matter tracts,
[`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)
for the atlas class constructor

Other ggseg_atlases:
[`aseg()`](https://ggsegverse.github.io/ggseg.formats/reference/aseg.md),
[`dk()`](https://ggsegverse.github.io/ggseg.formats/reference/dk.md),
[`tracula()`](https://ggsegverse.github.io/ggseg.formats/reference/tracula.md)

## Examples

``` r
suit()
#> 
#> ── suit ggseg atlas ────────────────────────────────────────────────────────────
#> Type: cerebellar
#> Regions: 13
#> Hemispheres: left, right, vermis
#> Views: flatmap, nuclei
#> Palette: ✔
#> Rendering: ✔ ggseg
#> ✔ ggseg3d (meshes)
#> ────────────────────────────────────────────────────────────────────────────────
#>      hemi region        label        names
#> 1    left   I_IV    left_I_IV lobules I-IV
#> 2   right   I_IV   right_I_IV lobules I-IV
#> 3    left      V       left_V     lobule V
#> 4   right      V      right_V     lobule V
#> 5    left     VI      left_VI    lobule VI
#> 6  vermis     VI    vermis_VI    lobule VI
#> 7   right     VI     right_VI    lobule VI
#> 8    left  CrusI   left_CrusI       Crus I
#> 9  vermis  CrusI vermis_CrusI       Crus I
#> 10  right  CrusI  right_CrusI       Crus I
#> ... with 24 more rows
atlas_regions(suit())
#>  [1] "I_IV"       "I_IV"       "V"          "V"          "VI"        
#>  [6] "VI"         "VI"         "CrusI"      "CrusI"      "CrusI"     
#> [11] "CrusII"     "CrusII"     "CrusII"     "VIIb"       "VIIb"      
#> [16] "VIIb"       "VIIIa"      "VIIIa"      "VIIIa"      "VIIIb"     
#> [21] "VIIIb"      "VIIIb"      "IX"         "IX"         "IX"        
#> [26] "X"          "X"          "X"          "Dentate"    "Dentate"   
#> [31] "Interposed" "Interposed" "Fastigial"  "Fastigial" 
atlas_geometry_type(suit())
#> [1] "polygon"
```
