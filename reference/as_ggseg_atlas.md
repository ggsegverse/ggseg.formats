# Bring an atlas up to the current format

Answers for every representation an atlas arrives in – the S7 object
this release builds, the plain tagged list an atlas package built before
3.0.0, a pre-2.0 `brain_atlas`, a `ggseg3d_atlas`, and an S7 atlas
stamped with an older schema – and returns the current one. It is a
no-op on an atlas that is already current, so the cost falls on the
objects that need it.

## Usage

``` r
as_ggseg_atlas(x, arg = rlang::caller_arg(x), call = rlang::caller_env())

as_brain_atlas(x)
```

## Arguments

- x:

  An atlas, in any representation.

- arg:

  The argument name to blame in an error. Defaults to the caller's.

- call:

  The environment to attribute the error to.

## Value

`x` as a current `ggseg_atlas`.

## Details

Package authors should call this on an atlas handed to them by a user,
so that the rest of their code has a single kind of object to reason
about. The two ways it can fail are separately catchable:
`ggseg.formats_not_atlas` for "that is not an atlas",
`ggseg.formats_invalid_atlas` for "that is an atlas and it is
malformed". Both name the caller's own argument, which is what `arg` and
`call` are for.

Upgrading beats asserting at a boundary:
[`assert_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/assert_ggseg_atlas.md)
returns its input unchanged, which leaves every later path to cope with
whatever it was given. That is how a legacy list atlas reached
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) in
`brain_join()` and
[`plot.default()`](https://rdrr.io/r/graphics/plot.default.html) from
[`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## See also

[`assert_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/assert_ggseg_atlas.md),
which checks without upgrading.

## Examples

``` r
atlas <- as_ggseg_atlas(dk())
is_ggseg_atlas(atlas)
#> [1] TRUE

# A no-op on an atlas that is already current.
identical(as_ggseg_atlas(dk()), dk())
#> [1] TRUE
```
