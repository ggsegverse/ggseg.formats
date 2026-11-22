# Set the 2D geometry of an atlas

Replaces the single `geom` slot of the atlas payload, which holds either
an sf data frame or a `brain_polygons` data frame. The counterpart to
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md):
the geometry pipelines in ggseg.extra rewrite geometry constantly –
smoothing, eroding, reshaping – and had to reach into the payload to put
the result back.

## Usage

``` r
set_atlas_geom(atlas, value)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

- value:

  An sf data frame or a `brain_polygons` data frame, keyed by `label`.

## Value

The `ggseg_atlas` with its 2D geometry replaced.

## Details

Writing geometry does not rewrite `core`. A verb that drops regions as
well as geometry has to update both, and because the validator spans
properties that has to land in one step – see
[`set_atlas_core()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_core.md).

## See also

[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md)
to read it.

Other atlas setters:
[`set_atlas_core()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_core.md),
[`set_atlas_name()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_name.md),
[`set_atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_palette.md),
[`set_atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_type.md)

## Examples

``` r
a <- dk()
identical(atlas_geom(set_atlas_geom(a, atlas_geom(a))), atlas_geom(a))
#> [1] TRUE
```
