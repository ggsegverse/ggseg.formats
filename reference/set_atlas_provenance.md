# Record how an atlas was built

Attaches a build record to an atlas. Intended for the pipelines in
ggseg.extra, which know the arguments a build was given; it is exported
so a third party constructing an atlas by hand can record the same thing
rather than leaving it unanswerable.

## Usage

``` r
set_atlas_provenance(atlas, value)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

- value:

  A named list, or `NULL` to drop the record. Must contain `pipeline`, a
  single string naming what built the atlas and its version, and
  `created`, a single string or `Date` for when. Further fields are
  yours.

## Value

`atlas`, with `value` as its provenance.

## See also

[`atlas_provenance()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_provenance.md)
to read one back.

## Examples

``` r
atlas <- set_atlas_provenance(
  dk(),
  list(pipeline = "hand-built 1.0", created = "2026-10-29")
)
atlas_provenance(atlas)$pipeline
#> [1] "hand-built 1.0"
```
