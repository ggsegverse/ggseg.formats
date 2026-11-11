# The labels an atlas draws but does not treat as regions

Anatomical backdrop – a cortical silhouette behind subcortical
structures, an unlabelled medial wall – is geometry without a `core`
row. It is drawn in grey, it is not in the legend, and it is not
something user data joins to.

## Usage

``` r
atlas_context(atlas)
```

## Arguments

- atlas:

  A `ggseg_atlas`.

## Value

Character vector of labels, empty when the atlas draws no backdrop.

## Details

Returns the labels rather than leaving every caller to compute the set
difference or, worse, match on a name. Build scripts had been writing
`labels = "^cortex"`, which silently matched nothing for as long as a
pipeline bug left the backdrop undrawn.

## See also

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
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
[`atlas_views_empty()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views_empty.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
atlas_context(aseg())
#> [1] "cortex"
```
