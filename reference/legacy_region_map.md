# Map pre-0.1.0 region names to current region keys

Before version 0.1.0 the `region` column of the bundled atlases held a
long-form display name. From 0.1.0 it holds a short, hemisphere-free key
derived from `label`, and the long-form name lives in `names`. Joins and
filters written against the old values therefore match nothing and fail
silently: `merge(all.x = TRUE)` and the ggseg fill scale both yield
`NA`, which draws as a blank parcel rather than raising an error.

## Usage

``` r
legacy_region_map(atlas)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

## Value

A named character vector whose names are the pre-0.1.0 `region` values
and whose values are the current `region` keys. Zero-length for an atlas
this package ships no legacy table for, which is every atlas except the
bundled four.

## Details

This returns the translation between the two, so old code can be updated
mechanically:

    map <- legacy_region_map(dk())
    my_data$region <- unname(map[my_data$region])

The mapping comes from a table of exactly what each bundled atlas
shipped at 0.0.4, not from the atlas's current `names` column – `names`
is the curated display name and several 0.0.4 `region` values were
mechanically derived (`"ventraldc"`, `"cc posterior"`), so the two are
deliberately not the same. Where two old names shared one `label`, as
`"Thalamus"` and `"Thalamus Proper"` did in `aseg`, both still translate
even though the alias row itself is gone from `core`.

## See also

[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md)
for the curated display names,
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md)
for the current keys.

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md),
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md),
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md)

## Examples

``` r
head(legacy_region_map(aseg()))
#>         Brain Stem        cc anterior         cc central    cc mid anterior 
#>       "brain stem"      "cc anterior"       "cc central"  "cc mid anterior" 
#>   cc mid posterior       cc posterior 
#> "cc mid posterior"     "cc posterior" 
legacy_region_map(tracula())[["SLF I"]]
#> [1] "slf1"
legacy_region_map(aseg())[["Thalamus Proper"]]
#> [1] "thalamus"
```
