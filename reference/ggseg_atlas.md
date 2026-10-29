# Constructor for ggseg atlas

Creates an object of class 'ggseg_atlas' for plotting brain
parcellations using ggseg (2D) and ggseg3d (3D).

## Usage

``` r
ggseg_atlas(atlas, type, core, data, palette = NULL)

brain_atlas(atlas, type, core, data, palette = NULL)
```

## Arguments

- atlas:

  atlas short name, length one

- type:

  atlas type: "cortical", "subcortical", "tract", or "cerebellar"

- core:

  data.frame with required columns hemi, region, label. `label` is the
  key the palette and every geometry slot are joined on, so it must be
  unique: a duplicated `label` is an error. May contain additional
  columns for grouping or metadata (e.g., lobe, network, Brodmann area).

- data:

  a ggseg_atlas_data object created by
  [`ggseg_data_cortical()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_cortical.md),
  [`ggseg_data_subcortical()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_subcortical.md),
  [`ggseg_data_tract()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_tract.md),
  or
  [`ggseg_data_cerebellar()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_cerebellar.md).
  Must match the specified type.

- palette:

  named character vector of colours keyed by label

## Value

an object of class 'ggseg_atlas'

## The type vocabulary is closed

`type` accepts exactly four values, and the constructor rejects any
other. This is deliberate rather than a limitation waiting to be lifted.
Between them, cortical, subcortical, tract and cerebellar cover the
major ways a brain is drawn on a 2D surface, and 3D is covered by
meshes.

A type is not merely a label: it implies a geometry form, a view
vocabulary and a rendering contract that both `ggseg` and `ggseg3d` must
implement. An atlas carrying a type no renderer knows how to draw is one
that cannot be plotted, so the vocabulary is governed rather than open.
The ecosystem is open to adding a type, but adding one is a discussion
to raise with the maintainers first, not something a contributing
package can do on its own. Atlases *of the existing types* need no such
discussion: that path is open, documented, and is how every distributed
atlas package was built.

## Examples

``` r
core <- data.frame(
  hemi = c("left", "left"),
  region = c("region1", "region2"),
  label = c("lh_region1", "lh_region2")
)
vertices <- data.frame(
  label = c("lh_region1", "lh_region2"),
  vertices = I(list(c(1L, 2L, 3L), c(4L, 5L, 6L)))
)
atlas <- ggseg_atlas(
  atlas = "test",
  type = "cortical",
  core = core,
  data = ggseg_data_cortical(vertices = vertices)
)
#> ℹ `core` has no display column.
#> ℹ display holds the long-form display name and is part of the `core` schema;
#>   add it when rebuilding "test".
#> ℹ See `atlas_display()`.
#> This message is displayed once per session.
```
