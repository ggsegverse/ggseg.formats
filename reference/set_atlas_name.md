# Set the short name of an atlas

Replaces the name an atlas is published and cited under. The counterpart
to
[`atlas_name()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_name.md),
and the setter that was missing from the family: a pipeline that builds
an atlas under a working name and renames the finished object had no way
to do it short of assigning the property.

## Usage

``` r
set_atlas_name(atlas, value)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

- value:

  A single, non-missing character string.

## Value

The `ggseg_atlas` with its name replaced.

## See also

[`atlas_name()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_name.md)
to read it.

Other atlas setters:
[`set_atlas_core()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_core.md),
[`set_atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_geom.md),
[`set_atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_palette.md),
[`set_atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_type.md)

## Examples

``` r
atlas_name(set_atlas_name(aseg(), "aseg_subcortical"))
#> [1] "aseg_subcortical"
```
