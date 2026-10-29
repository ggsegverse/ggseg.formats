# Extract the hemisphere column of an atlas

`hemi` records which side of the brain a row sits on, as one of
`"left"`, `"right"` or `"midline"`, or `NA` where a side does not apply.
It is a closed vocabulary, enforced at construction, because it is what
consumers filter and facet on.

## Usage

``` r
atlas_hemi(x)
```

## Arguments

- x:

  brain atlas

## Value

The `hemi` column of `core`, unchanged: one element per `core` row, in
`core` row order, with repeats and `NA`s retained. A zero-length
character vector when the atlas carries no `hemi` column.

## See also

[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_display()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_display.md)

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_display()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_display.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md),
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_undrawn()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_undrawn.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
unique(atlas_hemi(dk()))
#> [1] "left"  "right"
unique(atlas_hemi(suit()))
#> [1] "left"    "right"   "midline"
```
