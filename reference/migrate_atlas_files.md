# Migrate atlas `.rda` files to the sf-optional polygon format

Walks a directory of `.rda` files, finds every `ggseg_atlas` object
inside them, and rewrites their 2D geometry into the single `geom` slot.
By default the geometry is stored as `brain_polygons` (sf-optional); any
legacy `sf` / `polygons` slots are dropped. Pass `keep_sf = TRUE` to
store the geometry as sf instead.

## Usage

``` r
migrate_atlas_files(
  path = "data",
  keep_sf = FALSE,
  quiet = FALSE,
  force = FALSE
)
```

## Arguments

- path:

  Directory containing `.rda` files to migrate. Defaults to `"data"`,
  the conventional location in R packages.

- keep_sf:

  If `TRUE`, the geometry is stored in `geom` as sf. Default `FALSE` —
  the geometry is stored as `brain_polygons` (sf-optional).

- quiet:

  If `TRUE`, suppress per-file status messages.

- force:

  If `TRUE`, migrate even when the conversion cannot carry every
  geometry column across. The default `FALSE` aborts instead, naming the
  columns and the file, because the files are rewritten in place.

## Value

Invisibly, a character vector of paths to the files that were rewritten.

## Details

Intended for downstream atlas-package maintainers across the ggsegverse
ecosystem: run once against your `data/` directory, then drop `sf` from
DESCRIPTION Imports.

## Examples

``` r
# In an atlas package you would call this on the package's own data/
# directory. Here it runs against a throwaway copy, since it rewrites the
# files it is pointed at. Producing an sf atlas to migrate needs sf.
dir <- file.path(tempdir(), "data")
dir.create(dir, showWarnings = FALSE)
dk_atlas <- as_sf_atlas(dk())
save(dk_atlas, file = file.path(dir, "dk_atlas.rda"))

migrate_atlas_files(dir, quiet = TRUE)

load(file.path(dir, "dk_atlas.rda"))
is_atlas_polygon(dk_atlas) # TRUE
#> [1] TRUE
unlink(dir, recursive = TRUE)
```
