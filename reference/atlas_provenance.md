# How an atlas was built

Returns the build record an atlas carries, or `NULL` for an atlas built
before provenance existed or by a pipeline that did not record one.

## Usage

``` r
atlas_provenance(atlas)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

## Value

A named list, or `NULL`. When present it carries at least `pipeline`
(what built the atlas, including its version) and `created` (when). Any
further fields are the producing pipeline's own, commonly the source
parcellation and the arguments the build was given.

## Details

Provenance answers a question the rest of the class cannot: not what the
atlas contains, but how it came to contain it. Two atlases produced by
the same pipeline can differ in view count, polygon simplification or
palette source because they were built with different arguments, and
without a record the only way to find out is to locate the build script
that produced them – which lives in a different repository and may have
changed since.

## See also

[`set_atlas_provenance()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_provenance.md)
to attach one.

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
[`atlas_region_semantics()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_region_semantics.md),
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_undrawn()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_undrawn.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`atlas_views_empty()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views_empty.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
atlas_provenance(dk())
#> NULL
```
