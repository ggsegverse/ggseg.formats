# The columns user data joins an atlas on

The key vocabulary a plotting function matches `data` against an atlas
with. `label` comes first: it is the canonical matching key described in
[core_contract](https://ggsegverse.github.io/ggseg.formats/reference/core_contract.md),
unique per atlas row, hemisphere-qualified, and what a palette is keyed
by. Every key the data carries is used, so data keyed on `region` still
joins.

## Usage

``` r
brain_join_keys()
```

## Value

Character vector of the join-key column names.

## Details

Only these columns are keys. An incidental shared column – a `lobe`
classification, say – would otherwise become a join key and silently
drop most of the matches, which is the defect ggseg \#217 fixed. The
vocabulary is stated here, once, because `ggseg` and `ggseg3d` must
agree on it.

## See also

[core_contract](https://ggsegverse.github.io/ggseg.formats/reference/core_contract.md),
[`aggregate_brain_values()`](https://ggsegverse.github.io/ggseg.formats/reference/aggregate_brain_values.md)

## Examples

``` r
brain_join_keys()
#> [1] "label"  "region" "hemi"  

intersect(brain_join_keys(), names(atlas_core(dk())))
#> [1] "label"  "region" "hemi"  
```
