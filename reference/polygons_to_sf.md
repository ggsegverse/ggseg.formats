# Convert sf-optional polygons to an sf data frame

Inverse of
[`sf_to_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/sf_to_polygons.md).
Uses
[`sfheaders::sf_multipolygon()`](https://dcooley.github.io/sfheaders/reference/sf_multipolygon.html)
to build MULTIPOLYGON geometries — sfheaders is pure Rcpp and has no
GDAL/GEOS/PROJ system dependencies, so the conversion itself does not
require a full sf installation. The returned object is an sf-class data
frame, which downstream users would manipulate using sf.

## Usage

``` r
polygons_to_sf(polygons)
```

## Arguments

- polygons:

  A `brain_polygons` data.frame produced by
  [`sf_to_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/sf_to_polygons.md)
  or constructed directly: one row per `label`, with a `geometry`
  list-column of data.frames containing `view`, `x`, `y`, `group`,
  `subgroup`.

## Value

An sf-class data frame with columns `label`, `view`, any extra nested
columns, and `geometry` (one row per label×view, geometry is
MULTIPOLYGON).

Internal conversion primitive. For the atlas-level public API use
[`as_sf_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_sf_atlas.md)
/
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md).

## Details

Nested columns beyond `x`, `y`, `group` and `subgroup` become attribute
columns of the result. An sf row covers a whole label×view feature, so
such a column takes its first value within that feature; a column that
varies inside one feature loses the variation.
