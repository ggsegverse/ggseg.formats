# Warn once per session when values are collapsed per region

Before ggseg 3.0.0 several `data` rows for the same region drew on top
of each other, so the last row won; they are now reduced with `fun`
([`aggregate_brain_values()`](https://ggsegverse.github.io/ggseg.formats/reference/aggregate_brain_values.md),
mean by default). That is a silent numeric change for anyone plotting a
cohort they have not summarised themselves, so say so the first time it
happens in a session. The warning has class `"ggseg_collapsed_rows"`, so
it can be muffled or caught on its own.

## Usage

``` r
warn_collapsed_rows(data, keys, value_cols)
```

## Arguments

- data:

  A data frame of values to plot.

- keys:

  Character vector of columns identifying an atlas region.

- value_cols:

  The columns that would be aggregated.

## Value

`invisible(NULL)`, called for its warning side effect.

## See also

[`aggregate_brain_values()`](https://ggsegverse.github.io/ggseg.formats/reference/aggregate_brain_values.md)

## Examples

``` r
thickness <- data.frame(
  label = c("lh_precentral", "lh_precentral"),
  thickness = c(0.1, 0.9)
)

# Warns: two rows map to one region
warn_collapsed_rows(thickness, "label", "thickness")
```
