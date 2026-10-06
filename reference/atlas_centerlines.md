# Get atlas tract centerlines

Returns the centerline of each tract, joined with core region info and
palette colours. Tract atlases represent each pathway as a curve through
the bundle rather than as a surface, and render it by sweeping a tube
along that curve, so the centerline — not a mesh — is the geometry that
defines them.

## Usage

``` r
atlas_centerlines(atlas)
```

## Arguments

- atlas:

  a ggseg_atlas object

## Value

data.frame with one row per tract, a `points` list-column of n x 3
coordinate matrices and a matching `tangents` list-column

## See also

Other atlas accessors:
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
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
centerlines <- atlas_centerlines(tracula())
nrow(centerlines)
#> [1] 42
dim(centerlines$points[[1]])
#> [1] 100   3
```
