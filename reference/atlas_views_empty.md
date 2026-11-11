# The views an atlas has that draw no region

A view holding nothing but context is a panel of grey: it takes up room
in the layout, carries a title, and shows no region of the atlas. It is
the mirror of
[`atlas_undrawn()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_undrawn.md)
– that reports regions no view draws, this reports views that draw no
region – and the same silence applies, since the atlas validates and
plots without complaint.

## Usage

``` r
atlas_views_empty(atlas)
```

## Arguments

- atlas:

  A `ggseg_atlas`.

## Value

The view names drawing no `core` region, as a character vector; empty
when every view draws at least one, and when the atlas carries no 2D
geometry at all.

## Details

Usually it is a consequence of your own editing rather than of the
build: remove the ventricles from an `aseg`, or prune small depictions,
and a view whose only content was those regions is left empty.

This reports rather than removes, so the decision stays with you, and it
measures the atlas you hand it. To act on the answer use
`ggseg.extra::atlas_view_remove_empty()`, which takes the atlas once and
so always measures the atlas it is about to change — naming the atlas
twice to feed this into
[`atlas_view_remove()`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md)
reads as a pipe but is not one, and in a longer pipeline the name in
hand is the atlas *before* the editing that emptied the view.
`ggseg.extra::atlas_view_remove_sparse()` is the build-time counterpart,
for views a pipeline left *thin* against a threshold rather than empty.

## See also

[`atlas_undrawn()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_undrawn.md),
its mirror, and `ggseg.extra::atlas_view_remove_empty()` to act on the
result.

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_context()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_context.md),
[`atlas_display()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_display.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_hemi()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_hemi.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
[`atlas_plot_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_plot_palette.md),
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md),
[`atlas_provenance()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_provenance.md),
[`atlas_region_semantics()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_region_semantics.md),
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_undrawn()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_undrawn.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
atlas_views_empty(aseg())
#> character(0)
```
