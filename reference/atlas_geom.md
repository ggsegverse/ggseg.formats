# Get the raw 2D geometry of an atlas

Returns the single 2D geometry object stored in `atlas$data$geom`, which
is either an sf-class data frame or a `brain_polygons` data.frame. Its
class determines which rendering path is used downstream.

## Usage

``` r
atlas_geom(atlas)
```

## Arguments

- atlas:

  a ggseg_atlas object

## Value

an sf or `brain_polygons` object, or `NULL` if the atlas has no 2D
geometry

## Details

For backward compatibility with released atlases built before the
unified `geom` slot, this falls back to the legacy `sf` slot. Reverse
dependencies should call this accessor (or
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md)
/
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md))
rather than reaching into `atlas$data` directly.

## See also

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
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
g <- atlas_geom(dk())
atlas_geometry_type(dk())
#> [1] "polygon"
```
