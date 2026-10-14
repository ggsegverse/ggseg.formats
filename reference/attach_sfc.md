# Attach an `sfc` column and class a data frame as `sf`, without sf

[`merge()`](https://rdrr.io/r/base/merge.html),
[`cbind()`](https://rdrr.io/r/base/cbind.html) and `[` dispatch to sf's
own methods only when the sf namespace is loaded. Without it each strips
a different part of the sf representation:
[`merge()`](https://rdrr.io/r/base/merge.html) loses the class, the
`sf_column` attribute and the column's own `sfc` class;
[`cbind()`](https://rdrr.io/r/base/cbind.html) loses the class and the
attribute; subsetting loses the column's class. Attribute-space work
therefore happens with the geometry detached and this is the one place
that puts it back.

## Usage

``` r
attach_sfc(x, geometry, sf_column = "geometry", after = NULL)
```

## Arguments

- x:

  a data.frame, without its geometry column.

- geometry:

  an `sfc`, in `x`'s row order.

- sf_column:

  name to give the geometry column.

- after:

  insert the column after this many other columns, so the result keeps
  the column order callers already see. `NULL` appends.

## Value

`x` with `geometry` attached, classed as `sf`.

## Details

`agr` is a named factor over the non-geometry columns with sf's three
levels and no values set, which is what `st_as_sf()` produces for a
frame carrying no attribute-geometry relationships.

## See also

[`reorder_sfc()`](https://ggsegverse.github.io/ggseg.formats/reference/reorder_sfc.md)
to permute the geometry alongside a reordered attribute table.

Other sf-optional helpers:
[`reorder_sfc()`](https://ggsegverse.github.io/ggseg.formats/reference/reorder_sfc.md)

## Examples

``` r
atlas <- dk()
sf_data <- atlas_sf(atlas)
geometry <- sf_data$geometry

# Attribute-space work with the geometry detached, then reattached.
attrs <- sf_data
attrs$geometry <- NULL
class(attrs) <- "data.frame"
attrs$keep <- attrs$label %in% atlas_labels(atlas)[1:5]

rebuilt <- attach_sfc(attrs, geometry)
class(rebuilt)
#> [1] "sf"         "data.frame"
inherits(rebuilt$geometry, "sfc")
#> [1] TRUE
```
