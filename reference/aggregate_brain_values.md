# Collapse several data rows per atlas region into one

Groups `data` by the columns that identify an atlas region and reduces
every other column to a single value: numeric columns with `fun`,
non-numeric columns to their first value. This is what lets a plotting
function accept long data with several rows per region (e.g. one row per
subject) and draw a single summarised value per region, rather than
letting the last row win. `ggseg::geom_brain()` and `ggseg3d::ggseg3d()`
both aggregate with it.

## Usage

``` r
aggregate_brain_values(
  data,
  keys,
  fun = mean,
  ignore = character(),
  warn_collapse = TRUE
)
```

## Arguments

- data:

  A data frame of values to plot, carrying the `keys` columns.

- keys:

  Character vector of columns identifying an atlas region, e.g.
  `c("label", "hemi")`. These are kept, never aggregated.

- fun:

  Aggregating function for numeric columns. It must reduce a vector to a
  single value; `mean` (the default), `median` and `max` all do.

- ignore:

  Columns to leave out of the result entirely: the atlas metadata
  columns the caller joins on anyway, plus the plotting system's own
  bookkeeping columns (for ggplot2: `group`, `PANEL`, `flipped_aes`).

- warn_collapse:

  Whether to warn with
  [`warn_collapsed_rows()`](https://ggsegverse.github.io/ggseg.formats/reference/warn_collapsed_rows.md)
  when rows actually collapse. Pass `FALSE` when the rows are the
  atlas's own identity rows rather than user data.

## Value

One row per unique key combination, in order of first appearance, with
the `keys` columns and the aggregated columns.

## See also

[`warn_collapsed_rows()`](https://ggsegverse.github.io/ggseg.formats/reference/warn_collapsed_rows.md)

## Examples

``` r
thickness <- data.frame(
  label = c("lh_precentral", "lh_precentral", "lh_insula"),
  hemi = "left",
  subject = c("s01", "s02", "s01"),
  thickness = c(0.1, 0.9, 0.5)
)

aggregate_brain_values(thickness, c("label", "hemi"))
#> Warning: ! Several `data` rows map to the same atlas region; combining them with `fun`.
#> ℹ Before ggseg 3.0.0 these rows overplotted, so the last one won. Pass `fun =
#>   dplyr::last` to keep that behaviour.
#> ℹ Non-numeric columns take the first value regardless of `fun`.
#> This warning is displayed once per session.
#>           label hemi subject thickness
#> 1 lh_precentral left     s01       0.5
#> 2     lh_insula left     s01       0.5

aggregate_brain_values(thickness, c("label", "hemi"), fun = max)
#>           label hemi subject thickness
#> 1 lh_precentral left     s01       0.9
#> 2     lh_insula left     s01       0.5

# Drop a column instead of aggregating it
aggregate_brain_values(thickness, c("label", "hemi"), ignore = "subject")
#>           label hemi thickness
#> 1 lh_precentral left       0.5
#> 2     lh_insula left       0.5
```
