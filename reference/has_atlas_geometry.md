# Does an atlas carry this geometry?

The geometry accessors abort when the geometry they name is absent,
because a caller that asks for meshes and gets `NULL` usually goes on to
fail further away from the cause. That leaves no way to *ask*, though,
and both renderers want to: ggseg3d decides whether there is anything to
draw in 3D, and ggseg.extra warns before previewing a large atlas.
Without these the only way to ask was to reach into the payload, which
is the one thing the accessors exist to stop.

## Usage

``` r
has_atlas_geom(atlas)

has_atlas_vertices(atlas)

has_atlas_meshes(atlas)

has_atlas_centerlines(atlas)

has_atlas_3d(atlas)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

## Value

A logical scalar. `FALSE` for an object that is not an atlas, so these
are safe to use in control flow.

## See also

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_context()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_context.md),
[`atlas_core()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core.md),
[`atlas_data()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_data.md),
[`atlas_display()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_display.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_hemi()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_hemi.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
[`atlas_name()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_name.md),
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
[`atlas_plot_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_plot_palette.md),
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md),
[`atlas_provenance()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_provenance.md),
[`atlas_region_semantics()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_region_semantics.md),
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_schema_version()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_schema_version.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_undrawn()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_undrawn.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`atlas_views_empty()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views_empty.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
has_atlas_vertices(dk())
#> [1] TRUE
has_atlas_meshes(dk())
#> [1] FALSE
has_atlas_meshes(aseg())
#> [1] TRUE
has_atlas_3d(tracula())
#> [1] TRUE
```
