# Re-key an atlas's labels

`label` is an atlas's join key: `core`, the palette's names and every
geometry payload (`geom`, `vertices`, `meshes`, `centerlines`) are keyed
on it. Rewriting it in one of those places and not the others silently
decouples geometry from metadata, which is how a renamed region ends up
drawn in the wrong colour or not at all, so this rewrites all of them
together.

## Usage

``` r
relabel_atlas(atlas, mapping)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

- mapping:

  Named character vector: names are the atlas's current labels, values
  the replacements.

## Value

The `ggseg_atlas` with `mapping` applied to `core$label`, the palette's
names and every payload slot that carries a `label` column.

## Details

Labels absent from `mapping` are left alone, so contextual geometry such
as the `cortex_` silhouette survives a partial re-key untouched.

This is the supported way to correct an atlas's identifiers – the
operation
[`tracula()`](https://ggsegverse.github.io/ggseg.formats/reference/tracula.md)
itself needed when its `.bbr.prep` suffix was restored. Use
[`atlas_region_rename()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
instead to change the display names in `region`, which is not a join
key.

## See also

[`atlas_region_rename()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
to rename regions rather than re-key labels.

Other atlas manipulations:
[`atlas_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md)

## Examples

``` r
a <- relabel_atlas(aseg(), c("Left-Thalamus" = "lh_thalamus"))
head(atlas_labels(a))
#> [1] "Left-Cerebellum-Cortex" "lh_thalamus"            "Left-Caudate"          
#> [4] "Left-Putamen"           "Left-Pallidum"          "Brain-Stem"            
```
