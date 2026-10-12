# Convert a ggseg atlas to the sf-optional polygon representation

Sets the single `geom` slot to the `brain_polygons` representation,
converting from sf if needed. The result renders identically via the
`geom_polygon`-based path in ggseg, but no longer depends on the sf
class machinery in `$data` — useful for wasm builds and air-gapped
installs.

## Usage

``` r
as_polygon_atlas(atlas)
```

## Arguments

- atlas:

  A `ggseg_atlas` (or legacy `brain_atlas`) object.

## Value

A `ggseg_atlas` whose `$data$geom` is a `brain_polygons` object.

## Details

A single representation is kept (no redundant sf alongside polygons). To
rehydrate sf for geometric operations later, use
[`as_sf_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_sf_atlas.md).
Extra geometry columns are carried over; only columns named `x`, `y`,
`group` or `subgroup` cannot be, since the nested coordinate table
reserves those names, and they are dropped with a warning.

This doubles as the backward-compatible path for sf-optional installs: a
lite-only ggseg that meets a still-sf-backed atlas converts it on the
fly when sf is installed. When sf is not installed the geometry cannot
be read, so the call aborts with a pointer to
[`migrate_atlas_files()`](https://ggsegverse.github.io/ggseg.formats/reference/migrate_atlas_files.md)
— which the atlas maintainer runs once (on a machine with sf) to ship
the package in the polygon format.

## Examples

``` r
poly <- as_polygon_atlas(dk())
is_atlas_polygon(poly) # TRUE
#> [1] TRUE
```
