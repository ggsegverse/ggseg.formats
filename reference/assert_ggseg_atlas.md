# Require a valid ggseg atlas, reporting why it is not

The companion to
[`is_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/is_ggseg_atlas.md)
for code that cannot continue without a valid atlas. The predicate
answers a yes/no question and so has nothing to say about *why* an
object failed; callers that turned that `FALSE` into an error could only
report the class, which is the one thing that was usually fine.
`assert_ggseg_atlas()` separates the two failure kinds:

## Usage

``` r
assert_ggseg_atlas(x, arg = rlang::caller_arg(x), call = rlang::caller_env())
```

## Arguments

- x:

  an object

- arg:

  argument name to report, for use inside another function

- call:

  environment the error is attributed to

## Value

`x`, invisibly, when it is a valid atlas. Aborts otherwise.

## Details

- A wrong class is reported as a wrong class.

- A `ggseg_atlas` whose parts do not satisfy the schema aborts with the
  [`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)
  constructor's own diagnostic, chained as the parent error, so the
  reader sees the missing column, the duplicated label or the mismatched
  data class instead of a message about the class tag.

Prefer this wherever a bad atlas would otherwise propagate; keep
[`is_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/is_ggseg_atlas.md)
for control flow, where signalling is wrong.

## Examples

``` r
atlas <- assert_ggseg_atlas(dk())

broken <- dk()
broken$core$label <- NULL
try(assert_ggseg_atlas(broken))
#> Error in eval(expr, envir) : 
#>   `broken` is a <ggseg_atlas> with an invalid structure.
#> Caused by error in `validate_ggseg_atlas_inputs()`:
#> ! `core` must contain columns: label.
```
