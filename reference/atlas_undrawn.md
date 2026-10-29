# The regions an atlas names but never draws

A region in `core` with no geometry in any view is invisible: it joins,
it carries a colour, and nothing appears. It is the failure mode of
choosing which slabs to keep, and it is silent – the atlas validates,
plots without complaint, and simply omits the region.

## Usage

``` r
atlas_undrawn(atlas)
```

## Arguments

- atlas:

  A `ggseg_atlas`.

## Value

The `core` labels with no geometry in any view, as a character vector;
empty when every region is drawn somewhere.

## Details

Build scripts narrow a pipeline's slabs to the few that read well. That
choice is a measurement of the geometry underneath it, so it goes stale
when the geometry changes. Asserting on this after the narrowing turns a
silent omission into a failed build.

## See also

[`atlas_view_keep()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
and
[`atlas_view_remove()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
which narrow the views this checks.

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_display()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_display.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_hemi()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_hemi.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
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
atlas_undrawn(aseg())
#> character(0)
```
