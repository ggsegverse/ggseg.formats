# Set the core table of an atlas, and the palette that is keyed on it

`core` and `palette` are keyed on the same labels, so a verb that drops
or renames regions changes both. The validator spans properties and runs
on every assignment, which means the two cannot be assigned one after
the other: the first assignment is checked against the stale value of
the other and fails. This lands them together.

## Usage

``` r
set_atlas_core(atlas, value, palette = "keep")
```

## Arguments

- atlas:

  a `ggseg_atlas` object

- value:

  A data frame with one row per region, carrying at least `region` and
  `label`.

- palette:

  A named character vector of colours keyed by the new `label`s, `NULL`
  to clear it, or `"keep"` (the default) to carry the existing palette
  across, dropping entries for labels that have gone.

## Value

The `ggseg_atlas` with its core table, and palette, replaced.

## Details

It also keeps S7 an implementation detail of this package. Without it,
every atlas-editing package needs `Imports: S7` and has to know that
`S7::props()<-` is the way to make a paired edit.

## See also

[`atlas_core()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core.md)
to read it.

Other atlas setters:
[`set_atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_geom.md),
[`set_atlas_name()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_name.md),
[`set_atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_palette.md),
[`set_atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_type.md)

## Examples

``` r
a <- dk()
keep <- head(atlas_core(a), 10)
nrow(atlas_core(set_atlas_core(a, keep)))
#> [1] 10
```
