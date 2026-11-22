# Get the core table of an atlas

Returns the `core` data frame: one row per region, carrying `label` (the
key the palette and every geometry slot join on), `region`, `hemi`, and
whatever grouping or metadata columns the atlas curates (`display`,
`lobe`, `network`, `structure`).

## Usage

``` r
atlas_core(atlas)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

## Value

A data frame with one row per region.

## See also

[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md)
and
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md)
for single columns of it,
[`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core_add.md)
to add columns to it.

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_context()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_context.md),
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
[`has_atlas_geometry`](https://ggsegverse.github.io/ggseg.formats/reference/has_atlas_geometry.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
head(atlas_core(dk()))
#> # A tibble: 6 × 5
#>   hemi  region                  label                      display         lobe 
#>   <chr> <chr>                   <chr>                      <chr>           <chr>
#> 1 left  bankssts                lh_bankssts                banks of super… temp…
#> 2 left  caudalanteriorcingulate lh_caudalanteriorcingulate caudal anterio… cing…
#> 3 left  caudalmiddlefrontal     lh_caudalmiddlefrontal     caudal middle … fron…
#> 4 left  corpuscallosum          lh_corpuscallosum          corpus callosum whit…
#> 5 left  cuneus                  lh_cuneus                  cuneus          occi…
#> 6 left  entorhinal              lh_entorhinal              entorhinal      temp…
nrow(atlas_core(aseg()))
#> [1] 29
```
