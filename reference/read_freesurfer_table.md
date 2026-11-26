# Read in stats table from FreeSurfer

FreeSurfer has functions to create tables from raw stats files. If you
have data already merged using the `aparcstats2table` or
`asegstats2table` from FreeSurfer, this function will read in the data
and prepare it for ggseg.

## Usage

``` r
read_freesurfer_table(path, measure = NULL, ...)
```

## Arguments

- path:

  path to the table file

- measure:

  which measure is the table of

- ...:

  additional arguments to `read.table`. `check.names` is not among them:
  the reader needs it `FALSE`, because mangling `Left-Thalamus` to
  `Left.Thalamus` cannot be undone when a tract label like
  `lh.af.bbr.prep` has dots of its own.

## Value

data.frame with stats information for subjects from FreeSurfer

## Examples

``` r
if (FALSE) {
file_path <- "all_subj_aseg.txt"
read_freesurfer_table(file_path)
}
```
