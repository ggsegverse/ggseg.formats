# Migrating atlases and code

``` r

library(ggseg.formats)
```

This vignette covers the two migrations ggseg.formats has asked of its
users: re-keying `region` in your own data tables, and rewriting an
atlas package’s geometry into the sf-optional format.

## Migrating code to the 0.1.0 region keys

Before 0.1.0 the `region` column of the bundled atlases held a long-form
display name (`"banks of superior temporal sulcus"`). From 0.1.0 it
holds a short, hemisphere-free key derived from `label` (`"bankssts"`),
and the long-form name lives in the new `names` column. `label` never
changed and remains the stable join key.

Nothing errors when this bites. `merge(all.x = TRUE)` and the ggseg fill
scale both yield `NA` for an unmatched region, which draws as a blank
parcel — so the only symptom is a figure with holes in it.

[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)
translates a table of old values mechanically:

``` r

map <- legacy_region_map(dk())
my_data$region <- unname(map[my_data$region])
```

Every pre-0.1.0 `region` value of all four bundled atlases translates:
`dk` 35/35, `aseg` 19/19, `tracula` 26/26 and `suit` 13/13, whose keys
never changed, so its map is the identity. `aseg`’s `"Thalamus Proper"`
translates too, to `"thalamus"`, even though the alias row it lived on
is gone from `core`. For any other atlas the map is zero-length, because
only the bundled four were re-keyed.

### Do not use `names` for this

`names` is the curated display name, spelled to read well in a legend,
and for several regions it deliberately differs from what 0.0.4 shipped
as `region`: `aseg` has `names` `"ventral diencephalon"` where 0.0.4 had
`region` `"ventraldc"`, and `"corpus callosum posterior"` where 0.0.4
had `"cc posterior"`.
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)
reads a recorded table of the 0.0.4 values instead, so it stays correct
however `names` is later improved.

If a pattern you pass to
[`atlas_region_remove()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
[`atlas_region_keep()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
or
[`atlas_region_contextual()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
matches nothing, they now warn and, where the pattern looks like a
pre-0.1.0 name, say which key to use instead.

### The accessors return rows, not a set

[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md)
and
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md)
used to return a sorted set of unique, non-`NA` values, so the three
disagreed on length for the same atlas and could not be zipped. Each now
returns its `core` column unchanged: one element per `core` row, in row
order, repeats and `NA`s retained. So `atlas_labels(a)[i]`,
`atlas_regions(a)[i]` and `atlas_names(a)[i]` describe the same row.

In practice
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md)
and
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md)
now repeat values, once per hemisphere or view row, and none of the
three is sorted any more. Code that indexed the old output by position,
or relied on it being a set, wants
[`unique()`](https://rdrr.io/r/base/unique.html) — and `sort(unique(x))`
reproduces the old value exactly.
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md)
is unchanged: views are a separate axis, not a `core` column.

### Adding `names` to your own atlas

`names` is part of the `core` schema from 0.1.0, but it arrived after
about twenty atlas packages had been published without it, so it cannot
be required. The policy is asymmetric:

- a `names` column that is not a character vector is an error, because a
  half-filled column is worse than none;
- a missing `names` column is reported once per atlas per session, as a
  message, by
  [`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)
  only.

Only the atlas author can add the column, so only the atlas author hears
about it. Constructing or rebuilding an atlas is where that message
appears. Plotting one, reading it through
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md)
or
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
and class-checking it with
[`is_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/is_ggseg_atlas.md)
are all silent —
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md)
simply returns `character(0)` when the column is absent.

To add it, give `core` one long-form display name per row, in `core` row
order, before calling
[`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md).
Spell it to read well in a legend; it is not the pre-0.1.0 `region` key,
which
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)
records separately.

## Migrating an atlas package to sf-optional

Since the **sf-optional** milestone (ggseg 2.2), a `ggseg_atlas` stores
its 2D geometry in a single `geom` slot that can hold either an `sf`
table or the sf-optional `brain_polygons` representation. The polygon
form renders identically through the `geom_polygon`-based path in ggseg,
but carries no dependency on the sf class machinery — so atlases keep
working on wasm builds and air-gapped installs where sf (and its
GDAL/GEOS/PROJ system libraries) cannot be installed.

This vignette is for maintainers of downstream atlas packages
(`ggsegFreeSurfer`, `ggsegSchaefer`, `ggsegGlasser`, …). Your package
ships `brain_atlas`/`ggseg_atlas` objects as `.rda` files under `data/`.
Migrating means rewriting those files once so the geometry is stored as
polygons, then dropping sf from your `DESCRIPTION`.

### The recipe

From the root of your atlas package, run:

``` r

# 1. rewrite every atlas in data/ into the polygon format
ggseg.formats::migrate_atlas_files("data")

# 2. drop sf from DESCRIPTION (it is no longer needed at install or run time)
usethis::use_package("sf", type = "Suggests")

# 3. rebuild the package data documentation and reinstall
devtools::document()
```

That is the whole migration. Commit the rewritten `data/*.rda`, push,
and release.

### What `migrate_atlas_files()` does

It walks the directory, loads each `.rda`, finds every atlas object
inside, converts its `geom` to `brain_polygons`, drops any legacy
`sf`/`polygons` slots, and saves the file back with `xz` compression.
Files with nothing to migrate are left untouched, and it reports what it
changed:

``` r

ggseg.formats::migrate_atlas_files("data")
#> ✔ Migrated `dk.rda`.
#> ✔ Migrated `aseg.rda`.
#> ℹ Skipped `palette.rda` (nothing to migrate).
```

The conversion reads sf coordinates, so **sf must be installed on the
machine you run the migration from**. This is a one-time maintainer
step; the published package no longer needs sf.

It is idempotent — running it twice is a no-op on already-migrated
files, so it is safe to wire into a `data-raw/` build script.

#### Keeping sf instead

If your atlas package genuinely needs sf geometry (for example it
exposes geometric operations), pass `keep_sf = TRUE` to normalise
everything into the single `geom` slot as sf rather than polygons:

``` r

ggseg.formats::migrate_atlas_files("data", keep_sf = TRUE)
```

### Verifying the result

After migrating, the geometry is sf-optional and round-trips losslessly.
You can rehydrate sf on demand with
[`as_sf_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_sf_atlas.md),
and go back with
[`as_polygon_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_polygon_atlas.md):

``` r

poly <- as_polygon_atlas(dk())
is_atlas_polygon(poly)
#> [1] TRUE

atlas_labels(poly) |>
  head()
#> [1] "lh_bankssts"                "lh_caudalanteriorcingulate"
#> [3] "lh_caudalmiddlefrontal"     "lh_corpuscallosum"         
#> [5] "lh_cuneus"                  "lh_entorhinal"
```

A migrated atlas plots through ggseg with no sf installed. If a
lite-only install meets an atlas that is *still* sf-backed,
[`as_polygon_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_polygon_atlas.md)
converts it on the fly when sf is available, and otherwise aborts with a
message naming
[`migrate_atlas_files()`](https://ggsegverse.github.io/ggseg.formats/reference/migrate_atlas_files.md)
— the signal that the atlas package itself needs the one-time migration
above.
