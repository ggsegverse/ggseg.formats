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

## Examples

``` r
atlas_context(aseg())
#> [1] "cortex"  "cortex_"
```
