# Manipulate brain atlas regions, views and drawings

Four groups of pipe-friendly verbs, each acting on a different thing.
Which group a verb belongs to is the first thing to know about it,
because two of the groups read alike and do not behave alike.

## Details

- [region_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/region_manipulation.md):
  which regions the atlas has.

- [view_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md):
  which views exist, and where they sit.

- [drawing_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md):
  which regions are drawn inside a view. These add no views and remove
  nothing from `core`: the region stays, its depiction in some view goes
  — though a view left drawing nothing goes with it.

- [`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core_add.md):
  metadata columns on `core`.

All of them return a new `ggseg_atlas`.

## See also

[region_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/region_manipulation.md),
[view_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md),
[drawing_manipulation](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md),
[`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core_add.md)

Other atlas manipulations:
[`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core_add.md),
[`atlas_relabel()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_relabel.md),
[`atlas_structure_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_structure_reorder.md),
[`drawing_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/drawing_manipulation.md),
[`region_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/region_manipulation.md),
[`view_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/view_manipulation.md)
