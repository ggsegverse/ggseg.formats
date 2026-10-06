# Get atlas meshes for 3D rendering

Returns meshes data joined with core region info and palette colours.
Used for subcortical and tract atlases.

## Usage

``` r
atlas_meshes(atlas)
```

## Arguments

- atlas:

  a ggseg_atlas object

## Value

data.frame with meshes ready for 3D rendering

## See also

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md),
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md),
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
meshes <- atlas_meshes(aseg())
head(meshes)
#> ── <ggseg_meshes> data: 6 × 7 ──────────────────────────────────────────────────
#>                    label vertices faces
#> 1 Left-Cerebellum-Cortex    10618 21228
#> 2          Left-Thalamus     1864  3724
#> 3           Left-Caudate     1512  3028
#> 4           Left-Putamen     1998  3992
#> 5          Left-Pallidum      723  1442
#> 6             Brain-Stem     4608  9212
```
