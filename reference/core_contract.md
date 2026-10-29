# What an atlas's three name columns mean

Every `ggseg_atlas` keys its `core` on three columns, and they are not
interchangeable.

## The two conventions for `region`

A parcellation that names its structures anatomically gives both
hemispheres the same name, so `region` aggregates them and `hemi`
disambiguates: grouping by `region` gives one row per structure.

A parcellation that numbers its parcels does not. `region_0001` and
`region_0002` are two different parcels, not one structure seen twice,
and no hemisphere-free name exists to recover – the source never gave
one. There `region` is 1:1 with `label` and grouping by it aggregates
nothing.

Both are correct for their source. What was missing was a way to ask
which you have, short of testing whether any name is shared across
hemispheres.
[`atlas_region_semantics()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_region_semantics.md)
is that question.

## See also

[`atlas_region_semantics()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_region_semantics.md),
[`atlas_display()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_display.md),
[`atlas_context()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_context.md)
