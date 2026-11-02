# How an atlas was built

Returns the build record an atlas carries, or `NULL` for an atlas built
before provenance existed or by a pipeline that did not record one.

## Usage

``` r
atlas_provenance(atlas)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

## Value

A named list, or `NULL`. When present it carries at least `pipeline`
(what built the atlas, including its version) and `created` (when). Any
further fields are the producing pipeline's own, commonly the source
parcellation and the arguments the build was given.

## Details

Provenance answers a question the rest of the class cannot: not what the
atlas contains, but how it came to contain it. Two atlases produced by
the same pipeline can differ in view count, polygon simplification or
palette source because they were built with different arguments, and
without a record the only way to find out is to locate the build script
that produced them – which lives in a different repository and may have
changed since.

## See also

[`set_atlas_provenance()`](https://ggsegverse.github.io/ggseg.formats/reference/set_atlas_provenance.md)
to attach one.

## Examples

``` r
atlas_provenance(dk())
#> NULL
```
