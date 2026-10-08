# Customising brain atlases

``` r

library(ggseg.formats)
# The atlas-manipulation helpers shown here operate on sf-backed atlas
# geometry. Since the sf-optional milestone, sf is a Suggests dependency,
# so load it explicitly here.
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE
```

Say you are preparing a figure that focuses on the subcortical
structures visible in a single sagittal slice. You want to drop the
views you don’t need, remove small polygon fragments that clutter the
image, turn some regions into non-legend context, and add a metadata
column so you can facet by structure type. Every one of those steps is a
single function call, and they all pipe together.

## The manipulation toolkit

ggseg.formats provides three groups of manipulation functions. **Region
functions** (`atlas_region_*`) control which regions are active in the
atlas. **View functions** (`atlas_view_*`) control the 2D sf
geometry—which views are present and how they are arranged. **Core
functions** (`atlas_core_*`) enrich the region metadata. All of them
accept a `ggseg_atlas` as the first argument, return a new
`ggseg_atlas`, and play nicely with the pipe.

## Keeping and removing regions

[`atlas_region_remove()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
strips a region entirely—from core, palette, sf geometry, and 3D data.
The `pattern` argument is passed to
[`grepl()`](https://rdrr.io/r/base/grep.html) with `ignore.case = TRUE`,
so partial matches work:

``` r

no_cc <- atlas_region_remove(dk(), "corpus callosum")
#> Warning in atlas_region_remove(dk(), "corpus callosum"): No regions matched "corpus callosum".
#> ℹ Nothing was removed.
#> ! It matches the long-form region "corpus callosum", which this atlas used
#>   before ggseg.formats 0.1.0, where region is now "corpuscallosum".
#> ℹ Use `legacy_region_map()` for the full mapping.
"corpus callosum" %in% atlas_regions(no_cc)
#> [1] FALSE
```

[`atlas_region_keep()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
is the inverse: it keeps only the regions that match and turns
everything else into context geometry (sf is preserved for surface
continuity, but non-matching regions leave core and palette):

``` r

frontal <- atlas_region_keep(dk(), "frontal")
unique(atlas_regions(frontal))
#> [1] "caudalmiddlefrontal"  "lateralorbitofrontal" "medialorbitofrontal" 
#> [4] "rostralmiddlefrontal" "superiorfrontal"      "frontalpole"
```

Both functions match the pattern against `label` by default: the
identifier that is unique within an atlas and spelled the same way
wherever the atlas is used. That is what makes a hemisphere prefix
something you can select on:

``` r

lh_only <- atlas_region_keep(dk(), "^lh_")
head(atlas_labels(lh_only))
#> [1] "lh_bankssts"                "lh_caudalanteriorcingulate"
#> [3] "lh_caudalmiddlefrontal"     "lh_corpuscallosum"         
#> [5] "lh_cuneus"                  "lh_entorhinal"
```

Pass `match_on = "region"` to match the hemisphere-free region key
instead:

``` r

both_sides <- atlas_region_keep(dk(), "^precuneus$", match_on = "region")
atlas_labels(both_sides)
#> [1] "lh_precuneus" "rh_precuneus"
```

## Context regions

Sometimes you want a region’s polygon to stay visible (rendered in grey)
but not appear in the legend or carry data. This is what
[`atlas_region_contextual()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
does. It removes the region from core, palette, and 3D data but leaves
the sf geometry in place:

``` r

ctx <- atlas_region_contextual(aseg(), "ventricle")
#> Warning in atlas_region_contextual(aseg(), "ventricle"): No regions matched "ventricle".
#> ℹ No region was made contextual.
"lateral ventricle" %in% atlas_regions(ctx)
#> [1] FALSE
```

Compare that to
[`atlas_region_remove()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md),
which would delete the ventricle polygons entirely, leaving gaps in the
2D slices.

## Renaming regions

[`atlas_region_rename()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
changes the `region` column without touching `label` (so geometry links
stay intact). Like the other verbs it picks its rows by `label`, and it
edits the region those rows already have. A string is substituted for
the pattern wherever the region contains it:

``` r

renamed <- atlas_region_rename(dk(), "bankssts", "STS banks")
"STS banks" %in% atlas_regions(renamed)
#> [1] TRUE
```

A function receives the regions of the matching rows and returns the new
ones. That is the way to set a region outright for a label, whatever it
was called before:

``` r

outright <- atlas_region_rename(
  dk(),
  "^[lr]h_bankssts$",
  \(region) "STS banks"
)
"STS banks" %in% atlas_regions(outright)
#> [1] TRUE
```

Pass `match_on = "region"` to pick the rows by their region text
instead:

``` r

upper <- atlas_region_rename(dk(), ".*", toupper, match_on = "region")
head(unique(atlas_regions(upper)))
#> [1] "BANKSSTS"                "CAUDALANTERIORCINGULATE"
#> [3] "CAUDALMIDDLEFRONTAL"     "CORPUSCALLOSUM"         
#> [5] "CUNEUS"                  "ENTORHINAL"
```

## Managing views

[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md)
tells you what 2D views an atlas has:

``` r

atlas_views(aseg())
#> [1] "axial_3"   "axial_4"   "axial_5"   "axial_6"   "coronal_1" "coronal_2"
#> [7] "sagittal"
```

[`atlas_view_keep()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
and
[`atlas_view_remove()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
filter views by pattern. If you only want the sagittal slice:

``` r

sag <- atlas_view_keep(aseg(), "sagittal")
atlas_views(sag)
#> [1] "sagittal"
```

Or remove several views at once by passing a vector:

``` r

fewer <- atlas_view_remove(aseg(), c("axial_3", "coronal_2"))
atlas_views(fewer)
#> [1] "axial_4"   "axial_5"   "axial_6"   "coronal_1" "sagittal"
```

## Cleaning up geometry

After filtering regions you may have small polygon fragments left
over—tiny slivers where a region just barely crossed a slice plane.
[`atlas_view_remove_small()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
removes region polygons below a minimum area threshold. Context polygons
(those not in core) are never removed:

``` r

cleaned <- atlas_view_remove_small(aseg(), min_area = 50)
#> ℹ Removed 14 geometries below area 50
```

You can scope the removal to specific views:

``` r

cleaned_sag <- atlas_view_remove_small(
  aseg(),
  min_area = 50,
  views = "sagittal"
)
#> ℹ Removed 4 geometries below area 50
```

[`atlas_view_remove_region()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
removes a specific region’s sf geometry without touching core, palette,
or 3D data. This is useful when a region’s 2D projection is misleading
but you still want it in 3D:

``` r

no_stem_sf <- atlas_view_remove_region(
  aseg(),
  "brain stem",
  match_on = "region"
)
```

## Reordering and gathering

When you remove views, the remaining geometry keeps its original
coordinates, which can leave awkward gaps.
[`atlas_view_gather()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
repositions views side-by-side with a configurable gap:

``` r

trimmed <- aseg() |>
  atlas_view_keep(c("sagittal", "coronal_3", "axial_3")) |>
  atlas_view_gather()
atlas_views(trimmed)
#> [1] "axial_3"  "sagittal"
```

[`atlas_view_reorder()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
lets you choose the left-to-right order and repositions at the same
time. Views not mentioned in `order` are appended at the end:

``` r

reordered <- aseg() |>
  atlas_view_keep(c("sagittal", "coronal_3", "axial_3")) |>
  atlas_view_reorder(c("axial_3", "sagittal", "coronal_3"))
atlas_views(reordered)
#> [1] "axial_3"  "sagittal"
```

## Adding metadata

[`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
left-joins a data frame onto the core table. This is useful for
attaching grouping variables, statistical results, or any other
per-region information. Here we add a custom network column to a handful
of regions:

``` r

network_info <- data.frame(
  region = c(
    "superior frontal",
    "precuneus",
    "inferior parietal",
    "posterior cingulate"
  ),
  network = "default mode"
)
enriched <- atlas_core_add(dk(), network_info)
enriched$core[!is.na(enriched$core$network), c("region", "network")]
#>       region      network
#> 25 precuneus default mode
#> 60 precuneus default mode
```

The `by` argument defaults to `"region"` but you can join on any shared
column.

## A full pipeline

Here is a realistic pipeline that prepares the `aseg` atlas for a
compact two-view figure of deep grey matter structures:

``` r

publication_aseg <- aseg() |>
  atlas_view_keep(c("sagittal", "coronal_3")) |>
  atlas_region_contextual("ventricle|choroid|white|cc") |>
  atlas_view_remove_small(min_area = 30) |>
  atlas_view_gather(gap = 0.1)
#> ℹ Removed 3 geometries below area 30

publication_aseg
#> 
#> ── aseg ggseg atlas ────────────────────────────────────────────────────────────
#> Type: subcortical
#> Regions: 11
#> Hemispheres: left, NA, right
#> Views: sagittal
#> Palette: ✔
#> Rendering: ✔ ggseg
#> ✔ ggseg3d (meshes)
#> ────────────────────────────────────────────────────────────────────────────────
#>    hemi            region                  label                names
#> 1  left cerebellum cortex Left-Cerebellum-Cortex    cerebellum cortex
#> 2  left          thalamus          Left-Thalamus             thalamus
#> 3  left           caudate           Left-Caudate              caudate
#> 4  left           putamen           Left-Putamen              putamen
#> 5  left          pallidum          Left-Pallidum             pallidum
#> 6  <NA>        brain stem             Brain-Stem           brain stem
#> 7  left       hippocampus       Left-Hippocampus          hippocampus
#> 8  left          amygdala          Left-Amygdala             amygdala
#> 9  left         ventraldc         Left-VentralDC ventral diencephalon
#> 10 left            vessel            Left-vessel               vessel
#>        structure
#> 1     cerebellum
#> 2  basal ganglia
#> 3  basal ganglia
#> 4  basal ganglia
#> 5  basal ganglia
#> 6      brainstem
#> 7         limbic
#> 8         limbic
#> 9   diencephalon
#> 10         other
#> ... with 10 more rows
```

Each function returns a valid `ggseg_atlas`, so you can inspect
intermediate results, branch the pipeline, or hand the final object
straight to ggseg for plotting.
