# Does this atlas's `region` aggregate across hemispheres?

Answers which of the two conventions described in
[core_contract](https://ggsegverse.github.io/ggseg.formats/reference/core_contract.md)
an atlas follows, so a consumer joining results across parcellations
does not have to work it out.

## Usage

``` r
atlas_region_semantics(atlas)
```

## Arguments

- atlas:

  A `ggseg_atlas`.

## Value

One of:

- `"shared"`:

  `region` names are shared between the hemispheres, so grouping by
  `region` aggregates a structure across sides.

- `"per-hemisphere"`:

  No name is shared, so `region` is 1:1 with `label` and grouping by it
  aggregates nothing.

- `"unilateral"`:

  The atlas has fewer than two lateral hemispheres, so the question does
  not arise.

## Details

Computed from `core` rather than stored, so it cannot disagree with the
data it describes: a stored flag would be one more thing to keep true
through every verb that edits an atlas.

## Examples

``` r
atlas_region_semantics(dk())
#> [1] "shared"
atlas_region_semantics(aseg())
#> [1] "shared"
```
