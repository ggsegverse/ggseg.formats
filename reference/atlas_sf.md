# Get atlas data for 2D rendering

Returns sf data joined with core region info and palette colours. This
is the interception point used by ggseg for plotting: it always returns
sf geometry, converting from the polygon representation when needed.

## Usage

``` r
atlas_sf(atlas)
```

## Arguments

- atlas:

  a ggseg_atlas object

## Value

sf data.frame ready for plotting

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
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
sf_data <- atlas_sf(dk())
head(sf_data)
#> Simple feature collection with 6 features and 7 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 56.9868 ymin: 6.453514 xmax: 1625.641 ymax: 79.38795
#> CRS:           NA
#>          label     view hemi region names lobe                       geometry
#> 180 lh_unknown inferior <NA>   <NA>  <NA> <NA> MULTIPOLYGON (((59.87309 38...
#> 181 lh_unknown  lateral <NA>   <NA>  <NA> <NA> MULTIPOLYGON (((309.1881 20...
#> 182 lh_unknown   medial <NA>   <NA>  <NA> <NA> MULTIPOLYGON (((561.9354 46...
#> 183 rh_unknown inferior <NA>   <NA>  <NA> <NA> MULTIPOLYGON (((1056.938 47...
#> 184 rh_unknown  lateral <NA>   <NA>  <NA> <NA> MULTIPOLYGON (((1376.635 14...
#> 185 rh_unknown   medial <NA>   <NA>  <NA> <NA> MULTIPOLYGON (((1539.551 20...
#>     colour
#> 180   <NA>
#> 181   <NA>
#> 182   <NA>
#> 183   <NA>
#> 184   <NA>
#> 185   <NA>
```
