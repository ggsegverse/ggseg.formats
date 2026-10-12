# Create tract atlas data

Creates a data object for white matter tract atlases. Stores centerlines
compactly; tube meshes are generated at render time for efficiency.

## Usage

``` r
ggseg_data_tract(geom = NULL, centerlines = NULL, meshes = NULL, ...)

brain_data_tract(sf = NULL, centerlines = NULL, meshes = NULL, ...)
```

## Arguments

- geom:

  2D geometry for rendering, stored in the single `geom` slot: either an
  sf data.frame (columns `label`, `view`, `geometry`) or a
  `brain_polygons` data.frame (see
  [`sf_to_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/sf_to_polygons.md)).
  The class of `geom` determines the rendering path used downstream.

- centerlines:

  data.frame with columns:

  - label: tract identifier (character)

  - points: list-column of n x 3 matrices (centerline coordinates)

  - tangents: list-column of n x 3 matrices (for orientation coloring)

- meshes:

  **\[deprecated\]** Use `centerlines` instead. If supplied, it is
  converted to the centerlines format.

- ...:

  Captures a deprecated `sf` argument (converted to polygons) and
  absorbs legacy fields (e.g. tube_radius, tube_segments) from old
  cached atlas objects.

- sf:

  Deprecated. Pass 2D geometry via `geom` instead.

## Value

An object of class c("ggseg_data_tract", "ggseg_atlas_data")

## Examples

``` r
centerlines_df <- data.frame(
  label = "cst_left",
  points = I(list(matrix(rnorm(150), ncol = 3))),
  tangents = I(list(matrix(rnorm(150), ncol = 3)))
)
data <- ggseg_data_tract(centerlines = centerlines_df)
```
