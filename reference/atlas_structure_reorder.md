# Reorder the structures of an atlas

Moves structures within an atlas's geometry, the way
[`dplyr::relocate()`](https://dplyr.tidyverse.org/reference/relocate.html)
moves columns. Geometry rows are drawn in the order they appear, so this
is what decides which structure is painted over which where two overlap.

Overlap is common in subcortical atlases: a slab is a thick slice of the
volume flattened into one panel, so structures that never touch in the
brain can still overlap on the page.

## Usage

``` r
atlas_structure_reorder(
  atlas,
  structures,
  .before = NULL,
  .after = NULL,
  match_on = c("label", "region")
)
```

## Arguments

- atlas:

  A `ggseg_atlas` object.

- structures:

  Structures to move, as a character vector matched against `match_on`.
  They are moved together, keeping the order given here.

- .before, .after:

  One structure to move `structures` next to. Give at most one of the
  two.

- match_on:

  Column of `core` that `structures`, `.before` and `.after` name;
  `"label"` (the default) or `"region"`.

## Value

The `ggseg_atlas`, with its geometry rows in the new order.

## Details

**Later rows are drawn on top.** With neither `.before` nor `.after`,
the structures move to the front, matching
[`dplyr::relocate()`](https://dplyr.tidyverse.org/reference/relocate.html),
which means they are drawn *first*, and so end up *behind* everything
else. To bring a structure to the front visually, move it after the last
one.

The order is a property of the structure, not of a single view: an atlas
holds one geometry row per structure with its views nested inside, so a
structure keeps the same depth in every view it appears in.

## See also

[`atlas_view_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
which moves whole views around the canvas rather than structures within
them.

Other atlas manipulations:
[`atlas_manipulation`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)

## Examples

``` r
a <- aseg()

# Draw the thalamus on top of everything else
last <- utils::tail(atlas_labels(a), 1)
a <- atlas_structure_reorder(a, "Left-Thalamus", .after = last)

# Or tuck it behind its neighbours
a <- atlas_structure_reorder(a, "Left-Thalamus", .before = "Left-Putamen")
```
