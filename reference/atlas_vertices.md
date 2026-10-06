# Get atlas vertices for 3D rendering

Returns vertices data joined with core region info and palette colours.
Used for cortical atlases with vertex-based rendering.

## Usage

``` r
atlas_vertices(atlas)
```

## Arguments

- atlas:

  a ggseg_atlas object

## Value

data.frame with vertices ready for 3D rendering

## See also

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md),
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md),
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
verts <- atlas_vertices(dk())
head(verts)
#> ── <ggseg_vertices> data: 6 × 7 ────────────────────────────────────────────────
#> Vertices per region: 48 –232
#>                        label    vertices hemi                  region
#> 1                lh_bankssts <int [126]> left                bankssts
#> 2 lh_caudalanteriorcingulate  <int [67]> left caudalanteriorcingulate
#> 3     lh_caudalmiddlefrontal <int [232]> left     caudalmiddlefrontal
#> 4          lh_corpuscallosum <int [198]> left          corpuscallosum
#> 5                  lh_cuneus <int [102]> left                  cuneus
#> 6              lh_entorhinal  <int [48]> left              entorhinal
#>                               names         lobe  colour
#> 1 banks of superior temporal sulcus     temporal #196428
#> 2         caudal anterior cingulate    cingulate #7D64A0
#> 3             caudal middle frontal      frontal #641900
#> 4                   corpus callosum white matter #784632
#> 5                            cuneus    occipital #DC1464
#> 6                        entorhinal     temporal #DC140A
```
