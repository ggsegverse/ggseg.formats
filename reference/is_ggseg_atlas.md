# Check ggseg atlas class

These functions check both the class tag and structural validity by
passing the object through
[`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md).
An object that carries the right class but fails validation returns
`FALSE`.

## Usage

``` r
is_ggseg_atlas(x)

is_cortical_atlas(x)

is_subcortical_atlas(x)

is_tract_atlas(x)

is_cerebellar_atlas(x)

is_wm_atlas(x)

is_brain_atlas(x)
```

## Arguments

- x:

  an object

## Value

logical

## See also

[`assert_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/assert_ggseg_atlas.md),
which aborts with the reason instead of reducing it to `FALSE`.

## Examples

``` r
is_ggseg_atlas(dk())
#> [1] TRUE
is_cortical_atlas(dk())
#> [1] TRUE
is_subcortical_atlas(aseg())
#> [1] TRUE
is_tract_atlas(tracula())
#> [1] TRUE
```
