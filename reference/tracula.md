# TRACULA White Matter Tract Atlas

Returns the TRACULA (TRActs Constrained by UnderLying Anatomy) white
matter bundle atlas in MNI space.

## Usage

``` r
tracula()
```

## Value

A `ggseg_atlas` object with components:

- atlas:

  Character. Atlas name ("tracula")

- type:

  Character. Atlas type ("tract")

- palette:

  Named character vector of colours for each tract

- data:

  A `ggseg_data_tract` object containing:

  centerlines

  :   List of centerline matrices per tract

  sf

  :   Simple features data frame for 2D rendering

## Details

This atlas contains major white matter tracts reconstructed from
diffusion MRI using FreeSurfer's TRACULA training data. It works with
both ggseg (2D slice projections) and ggseg3d (3D tube mesh
visualizations).

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

## Tract labels

`label` is the name FreeSurfer's TRACULA writes its per-pathway outputs
under, including the trailing `.bbr.prep` (for example
`lh.af.bbr.prep`), so a table of TRACULA output joins to the atlas as it
comes. `label_short` is the same identifier with the suffix stripped –
the name `FreeSurferColorLUT.txt` gives the pathway at ids 5100-5399.

## References

Yendiki A, Panneck P, Srinivasan P, et al. (2011). Automated
probabilistic reconstruction of white-matter pathways in health and
disease using an atlas of the underlying anatomy. Frontiers in
Neuroinformatics, 5:23.
[doi:10.3389/fninf.2011.00023](https://doi.org/10.3389/fninf.2011.00023)

## See also

[`dk()`](https://ggsegverse.github.io/ggseg.formats/reference/dk.md) for
cortical parcellation,
[`aseg()`](https://ggsegverse.github.io/ggseg.formats/reference/aseg.md)
for subcortical structures,
[`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)
for the atlas class constructor

Other ggseg_atlases:
[`aseg()`](https://ggsegverse.github.io/ggseg.formats/reference/aseg.md),
[`dk()`](https://ggsegverse.github.io/ggseg.formats/reference/dk.md),
[`suit()`](https://ggsegverse.github.io/ggseg.formats/reference/suit.md)

## Examples

``` r
tracula()
#> 
#> ── tracula ggseg atlas ─────────────────────────────────────────────────────────
#> Type: tract
#> Regions: 26
#> Hemispheres: midline, left, right
#> Views: coronal, inferior_axial, mid_axial, sagittal, superior_axial
#> Palette: ✔
#> Rendering: ✔ ggseg
#> ✔ ggseg3d (centerlines)
#> ────────────────────────────────────────────────────────────────────────────────
#>       hemi      region                label label_short
#> 1  midline       acomm       acomm.bbr.prep       acomm
#> 2  midline    cc bodyc    cc.bodyc.bbr.prep    cc.bodyc
#> 3  midline    cc bodyp    cc.bodyp.bbr.prep    cc.bodyp
#> 4  midline   cc bodypf   cc.bodypf.bbr.prep   cc.bodypf
#> 5  midline   cc bodypm   cc.bodypm.bbr.prep   cc.bodypm
#> 6  midline    cc bodyt    cc.bodyt.bbr.prep    cc.bodyt
#> 7  midline     cc genu     cc.genu.bbr.prep     cc.genu
#> 8  midline  cc rostrum  cc.rostrum.bbr.prep  cc.rostrum
#> 9  midline cc splenium cc.splenium.bbr.prep cc.splenium
#> 10    left          af       lh.af.bbr.prep       lh.af
#>                              names           group
#> 1              anterior commissure      commissure
#> 2     corpus callosum body central corpus callosum
#> 3    corpus callosum body parietal corpus callosum
#> 4  corpus callosum body prefrontal corpus callosum
#> 5    corpus callosum body premotor corpus callosum
#> 6    corpus callosum body temporal corpus callosum
#> 7             corpus callosum genu corpus callosum
#> 8          corpus callosum rostrum corpus callosum
#> 9         corpus callosum splenium corpus callosum
#> 10              arcuate fasciculus     association
#> ... with 32 more rows
plot(tracula())

atlas_regions(tracula())
#>  [1] "acomm"       "cc bodyc"    "cc bodyp"    "cc bodypf"   "cc bodypm"  
#>  [6] "cc bodyt"    "cc genu"     "cc rostrum"  "cc splenium" "af"         
#> [11] "ar"          "atr"         "cbd"         "cbv"         "cst"        
#> [16] "emc"         "fat"         "fx"          "ilf"         "mlf"        
#> [21] "or"          "slf1"        "slf2"        "slf3"        "uf"         
#> [26] "mcp"         "af"          "ar"          "atr"         "cbd"        
#> [31] "cbv"         "cst"         "emc"         "fat"         "fx"         
#> [36] "ilf"         "mlf"         "or"          "slf1"        "slf2"       
#> [41] "slf3"        "uf"         
```
