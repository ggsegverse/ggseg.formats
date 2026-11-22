# Does this object claim to be an atlas?

`TRUE` when `x` carries the `ggseg_atlas` or legacy `brain_atlas` class
tag, without the structural revalidation
[`is_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/is_ggseg_atlas.md)
performs. The two answer different questions, and the difference matters
at exactly one kind of boundary: code that has to *repair* an atlas
needs to recognise a broken one, which
[`is_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/is_ggseg_atlas.md)
reports as `FALSE`.

## Usage

``` r
is_atlas_class(x)
```

## Arguments

- x:

  an object

## Value

A logical scalar.

## Details

Use
[`is_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/is_ggseg_atlas.md)
to decide whether an atlas can be drawn or saved. Use this to decide
whether an object is an atlas at all – upgrading a published atlas,
migrating a legacy one, or reporting why one is rejected.

## See also

[`is_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/is_ggseg_atlas.md),
which also revalidates the structure, and
[`assert_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/assert_ggseg_atlas.md),
which aborts with the reason.

## Examples

``` r
is_atlas_class(dk())
#> [1] TRUE

# A structurally broken atlas still claims to be one, which is what lets
# the migration verbs take hold of it.
broken <- structure(list(atlas = "x"), class = c("ggseg_atlas", "list"))
is_atlas_class(broken)
#> [1] TRUE
is_ggseg_atlas(broken)
#> [1] FALSE
```
