# Set the palette of an atlas

Replaces the colour palette of a brain atlas, validating that `value` is
a named character vector and warning if it does not cover every atlas
label. This is the setter counterpart to the
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md)
accessor; it returns the modified atlas, so it composes with the pipe.

## Usage

``` r
set_atlas_palette(atlas, value)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

- value:

  Named character vector of colours keyed by atlas `label`, or `NULL` to
  clear the palette.

## Value

The `ggseg_atlas` with its palette replaced.

## See also

[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md)
to read the palette.

Other atlas setters:
[`set_atlas_core()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_core.md),
[`set_atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_geom.md),
[`set_atlas_name()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_name.md),
[`set_atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_type.md)

## Examples

``` r
a <- aseg()
labs <- atlas_labels(a)
a <- set_atlas_palette(a, setNames(grDevices::rainbow(length(labs)), labs))
```
