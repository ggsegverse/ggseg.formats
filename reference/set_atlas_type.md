# Set the type of an atlas

Replaces the type of a brain atlas. The type is held in three coupled
places: the `type` field, the leading `<type>_atlas` class, and the
`ggseg_data_<type>` class of the data payload. This setter reconstructs
the atlas through
[`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)
so all three stay in agreement – assigning the `type` field directly
leaves the subclass stale and
[`is_tract_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/is_ggseg_atlas.md)
and friends disagreeing with
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md).

## Usage

``` r
set_atlas_type(atlas, value)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

- value:

  Atlas type; one of `"cortical"`, `"subcortical"`, `"tract"` or
  `"cerebellar"`.

## Value

The `ggseg_atlas` with its type, subclass and payload class in
agreement.

## Details

Because type and payload are coupled, the new type must match the data
the atlas already carries: a `"tract"` atlas needs
[`ggseg_data_tract()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_tract.md)
(centerlines), a `"subcortical"` atlas needs
[`ggseg_data_subcortical()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_subcortical.md)
(meshes). Retyping an atlas whose payload does not match is an error –
rebuild the payload with the matching `ggseg_data_*()` constructor
first.

## See also

[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md)
to read the type.

Other atlas setters:
[`set_atlas_core()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_core.md),
[`set_atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_geom.md),
[`set_atlas_name()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_name.md),
[`set_atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_palette.md)

## Examples

``` r
a <- aseg()
a <- set_atlas_type(a, "subcortical")
atlas_type(a)
#> [1] "subcortical"
```
