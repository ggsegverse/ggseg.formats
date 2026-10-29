# Give an atlas built before `display` existed its display names

`display` holds the source's own name for a region, and an atlas built
before the column existed looks as though that name is lost. It is not:
`label` is the source name with a hemisphere affix on it, so the display
name is recoverable exactly. Verified against every atlas that already
carries the column – 1996 rows, no disagreement.

## Usage

``` r
migrate_atlas_display(atlas, overwrite = FALSE)
```

## Arguments

- atlas:

  A `ggseg_atlas`.

- overwrite:

  Replace an existing `display` column. Off by default, because an atlas
  that carries one got it from its source, and the source's own name
  beats one derived from a key.

## Value

`atlas`, with `display` in `core`.

## Details

Atlases that already carry `display` are returned unchanged, so this is
safe to run over a whole library.

## Examples

``` r
atlas <- dk()
atlas$core$display <- NULL
atlas_display(migrate_atlas_display(atlas))[1:3]
#> [1] "bankssts"                "caudalanteriorcingulate"
#> [3] "caudalmiddlefrontal"    
```
