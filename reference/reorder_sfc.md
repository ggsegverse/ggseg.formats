# Reorder an `sfc` without sf

Subsetting drops the `sfc` class without sf loaded. A permutation does
not change the geometry set, so `bbox`, `crs`, `precision` and `n_empty`
stay valid and the attributes are reattached unchanged.

## Usage

``` r
reorder_sfc(geometry, i)
```

## Arguments

- geometry:

  an `sfc`.

- i:

  row positions, in the order wanted.

## Value

`geometry` in the order given by `i`, still an `sfc`.

## Details

`i` must be a permutation or a repetition of row positions, not a
subset: a selection that drops geometries leaves `bbox` and `n_empty`
describing rows that are no longer present.

## See also

[`attach_sfc()`](https://ggsegverse.github.io/ggseg.formats/reference/attach_sfc.md)
to put the result back on a data frame.

Other sf-optional helpers:
[`attach_sfc()`](https://ggsegverse.github.io/ggseg.formats/reference/attach_sfc.md)

## Examples

``` r
geometry <- atlas_sf(dk())$geometry
reversed <- reorder_sfc(geometry, rev(seq_along(geometry)))
inherits(reversed, "sfc")
#> [1] TRUE
```
