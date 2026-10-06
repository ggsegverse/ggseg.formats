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

  data.frame with required columns hemi, region, label (one row per
  unique region). May contain additional columns for grouping or
  metadata (e.g., lobe, network, Brodmann area).

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
#> ℹ `core` has no names column.
#> ℹ names holds the long-form display name and is part of the `core` schema; add
#>   it when rebuilding "test".
#> ℹ See `atlas_names()`.
#> This message is displayed once per session.
```
