# Does this atlas's `region` aggregate across hemispheres?

Answers which of the two conventions described in
[core_contract](https://ggsegverse.github.io/ggseg.formats/reference/core_contract.md)
an atlas follows, so a consumer joining results across parcellations
does not have to work it out.

## Usage

``` r
atlas_region_semantics(atlas)
```

## Arguments

- atlas:

  A `ggseg_atlas`.

## Value

One of:

- `"shared"`:

  `region` names are shared between the hemispheres, so grouping by
  `region` aggregates a structure across sides.

- `"per-hemisphere"`:

  No name is shared, so `region` is 1:1 with `label` and grouping by it
  aggregates nothing.

- `"unilateral"`:

  The atlas has fewer than two lateral hemispheres, so the question does
  not arise.

## Details

Computed from `core` rather than stored, so it cannot disagree with the
data it describes: a stored flag would be one more thing to keep true
through every verb that edits an atlas.

## See also

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
atlas_region_semantics(dk())
#> [1] "shared"
atlas_region_semantics(aseg())
#> [1] "shared"
```
