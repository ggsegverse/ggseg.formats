# Select an atlas's backdrop, or its regions, in a geometry verb

The geometry verbs take `labels` and `exclude` as patterns, and a
backdrop has to be addressed separately from the parcels: what makes a
cortical silhouette read as a brain is its sulci, which are fine detail,
so it wants gentler simplification and a smoothing method that does not
fill them.

## Usage

``` r
context()

regions()
```

## Value

A function of an atlas returning a pattern, which `labels` and `exclude`
accept.

## Details

Build scripts had been writing the pattern by hand, as `"^cortex"`. That
is a guess about what the pipeline named the backdrop, and it was wrong
twice over: the name varies across the library – `cortex_`, `cortex`,
`lh_unknown`, `lh_Background+FreeSurfer_Defined_Medial_Wall` – and a
pattern matching nothing is silent, so those steps did nothing at all
for as long as a pipeline bug left the backdrop undrawn.

These ask the atlas instead. The lookup table decides what is backdrop
when the atlas is built; this is how that decision is read back.

## See also

[`atlas_context()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_context.md)

## Examples

``` r
# gentler on the backdrop than on the parcels
if (FALSE) { # \dontrun{
atlas |>
  atlas_simplify(keep = 0.5, labels = context()) |>
  atlas_simplify(keep = 0.25, exclude = context())
} # }
```
