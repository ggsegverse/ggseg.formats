# Map a legacy `hemi` spelling onto the vocabulary

`hemi` is a closed vocabulary – `"left"`, `"right"`, `"midline"` or `NA`
– and two spellings predate it. `"middle"` was an earlier name for the
midline, and `"vermis"` is a cerebellar structure rather than a side, so
both map onto `"midline"`. The finer distinction belongs in a column of
its own.

## Usage

``` r
migrate_atlas_hemi(atlas)
```

## Arguments

- atlas:

  A `ggseg_atlas`, or a list shaped like one that no longer validates.

## Value

`atlas`, with `hemi` in the vocabulary.

## Details

An atlas carrying one cannot be constructed, so it cannot be passed
through any verb that validates – including
[`migrate_atlas_display()`](https://ggsegverse.github.io/ggseg.formats/reference/migrate_atlas_display.md).
This repairs `core` directly for that reason.

## Examples

``` r
atlas <- dk()
atlas$core$hemi[1] <- "middle"
unique(migrate_atlas_hemi(atlas)$core$hemi)
#> [1] "midline" "left"    "right"  
```
