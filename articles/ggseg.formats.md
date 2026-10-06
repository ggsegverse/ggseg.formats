# The ggseg_atlas object

``` r

library(ggseg.formats)
# Several examples below print or plot via the sf path. Since the
# sf-optional milestone, sf is a Suggests dependency, so load it here.
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE
```

Everything in the ggsegverse ecosystem starts from a single object: the
`ggseg_atlas`. Whether you are making a 2D cortical flatmap with ggseg
or spinning a 3D mesh in ggseg3d, the atlas is the container that holds
the geometry, the region metadata, and the colour palette together. This
vignette walks through the structure so you know exactly what you are
working with.

## What is a ggseg_atlas?

A `ggseg_atlas` is an S3 object that bundles five pieces of information
into one handle. Let’s print the bundled Desikan-Killiany atlas to see
what that looks like:

``` r

dk()
#> 
#> ── dk ggseg atlas ──────────────────────────────────────────────────────────────
#> Type: cortical
#> Regions: 35
#> Hemispheres: left, right
#> Views: inferior, lateral, medial, superior
#> Palette: ✔
#> Rendering: ✔ ggseg
#> ✔ ggseg3d (vertices)
#> ────────────────────────────────────────────────────────────────────────────────
#>    hemi                  region                      label
#> 1  left                bankssts                lh_bankssts
#> 2  left caudalanteriorcingulate lh_caudalanteriorcingulate
#> 3  left     caudalmiddlefrontal     lh_caudalmiddlefrontal
#> 4  left          corpuscallosum          lh_corpuscallosum
#> 5  left                  cuneus                  lh_cuneus
#> 6  left              entorhinal              lh_entorhinal
#> 7  left                fusiform                lh_fusiform
#> 8  left        inferiorparietal        lh_inferiorparietal
#> 9  left        inferiortemporal        lh_inferiortemporal
#> 10 left        isthmuscingulate        lh_isthmuscingulate
#>                                names         lobe
#> 1  banks of superior temporal sulcus     temporal
#> 2          caudal anterior cingulate    cingulate
#> 3              caudal middle frontal      frontal
#> 4                    corpus callosum white matter
#> 5                             cuneus    occipital
#> 6                         entorhinal     temporal
#> 7                           fusiform     temporal
#> 8                  inferior parietal     parietal
#> 9                  inferior temporal     temporal
#> 10                 isthmus cingulate    cingulate
#> ... with 60 more rows
```

The print method gives you a quick overview: the atlas name, type, how
many regions it has, which hemispheres are present, what views the 2D
geometry provides, and whether palette and rendering data are available.
Below the summary you see the core table, the single source of truth for
region identity.

## Anatomy of an atlas

The five slots are accessed with `$`:

``` r

dk()$atlas
#> [1] "dk"
dk()$type
#> [1] "cortical"
```

`$atlas` is a short name (used to look up atlases by string) and `$type`
is one of `"cortical"`, `"subcortical"`, or `"tract"`.

The `$palette` is a named character vector mapping labels to hex
colours:

``` r

head(dk()$palette)
#>                lh_bankssts lh_caudalanteriorcingulate 
#>                  "#196428"                  "#7D64A0" 
#>     lh_caudalmiddlefrontal          lh_corpuscallosum 
#>                  "#641900"                  "#784632" 
#>                  lh_cuneus              lh_entorhinal 
#>                  "#DC1464"                  "#DC140A"
```

`$core` is a data frame with one row per region. It always has `region`
and `label` columns, and will often include `hemi` and additional
metadata like `lobe` or `structure`:

``` r

head(dk()$core)
#>   hemi                  region                      label
#> 1 left                bankssts                lh_bankssts
#> 2 left caudalanteriorcingulate lh_caudalanteriorcingulate
#> 3 left     caudalmiddlefrontal     lh_caudalmiddlefrontal
#> 4 left          corpuscallosum          lh_corpuscallosum
#> 5 left                  cuneus                  lh_cuneus
#> 6 left              entorhinal              lh_entorhinal
#>                               names         lobe
#> 1 banks of superior temporal sulcus     temporal
#> 2         caudal anterior cingulate    cingulate
#> 3             caudal middle frontal      frontal
#> 4                   corpus callosum white matter
#> 5                            cuneus    occipital
#> 6                        entorhinal     temporal
```

Finally, `$data` is a `ggseg_atlas_data` object that holds the actual
geometry. Its contents depend on the atlas type.

``` r

class(dk()$data)
#> [1] "ggseg_data_cortical" "ggseg_atlas_data"
```

## Three atlas types

ggseg.formats ships three atlases that illustrate the three types.

**Cortical** atlases like `dk` parcellate the cortical surface. Their
data object is a `ggseg_data_cortical` containing sf polygons for 2D
rendering and vertex indices for 3D:

``` r

dk()$type
#> [1] "cortical"
names(dk()$data)
#> [1] "geom"     "vertices"
```

**Subcortical** atlases like `aseg` represent deep brain structures.
Their data is a `ggseg_data_subcortical` with sf polygons and individual
3D meshes:

``` r

aseg()$type
#> [1] "subcortical"
names(aseg()$data)
#> [1] "geom"   "meshes"
```

**Tract** atlases like `tracula` represent white matter bundles. Their
data is a `ggseg_data_tract` with sf polygons and centerlines that
generate tube meshes for 3D:

``` r

tracula()$type
#> [1] "tract"
names(tracula()$data)
#> [1] "geom"        "centerlines"
```

In every case the sf component drives 2D plotting and the type-specific
component (vertices, meshes, or centerlines) drives 3D.

## Core: the region table

The `$core` data frame is the single source of truth for what regions an
atlas contains. Every manipulation function updates core first and then
propagates changes to geometry and palette.

The required columns are `region` (a short, hemisphere-free key),
`label` (a unique identifier that links core to geometry and palette)
and `names` (the curated long-form display name). Most atlases also
carry `hemi`:

``` r

str(dk()$core)
#> Classes 'tbl_df', 'tbl' and 'data.frame':    70 obs. of  5 variables:
#>  $ hemi  : chr  "left" "left" "left" "left" ...
#>  $ region: chr  "bankssts" "caudalanteriorcingulate" "caudalmiddlefrontal" "corpuscallosum" ...
#>  $ label : chr  "lh_bankssts" "lh_caudalanteriorcingulate" "lh_caudalmiddlefrontal" "lh_corpuscallosum" ...
#>  $ names : chr  "banks of superior temporal sulcus" "caudal anterior cingulate" "caudal middle frontal" "corpus callosum" ...
#>  $ lobe  : chr  "temporal" "cingulate" "frontal" "white matter" ...
```

Some atlases include additional metadata columns. The `dk` atlas, for
instance, has `lobe`:

``` r

unique(dk()$core$lobe)
#> [1] "temporal"     "cingulate"    "frontal"      "white matter" "occipital"   
#> [6] "parietal"     "insula"
```

You can add your own metadata with
[`atlas_core_add()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_manipulation.md)
(covered in the manipulation vignette).

## Querying an atlas

A set of accessor functions lets you pull information out without
reaching into slots directly.

Each of these returns one element per `core` row, in `core` row order,
so they are row-aligned with each other: `atlas_labels(a)[i]`,
`atlas_regions(a)[i]` and `atlas_names(a)[i]` all describe the same row.
Wrap a call in [`unique()`](https://rdrr.io/r/base/unique.html) when you
want the distinct set instead.

[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md)
returns the region keys:

``` r

unique(atlas_regions(dk()))
#>  [1] "bankssts"                 "caudalanteriorcingulate" 
#>  [3] "caudalmiddlefrontal"      "corpuscallosum"          
#>  [5] "cuneus"                   "entorhinal"              
#>  [7] "fusiform"                 "inferiorparietal"        
#>  [9] "inferiortemporal"         "isthmuscingulate"        
#> [11] "lateraloccipital"         "lateralorbitofrontal"    
#> [13] "lingual"                  "medialorbitofrontal"     
#> [15] "middletemporal"           "parahippocampal"         
#> [17] "paracentral"              "parsopercularis"         
#> [19] "parsorbitalis"            "parstriangularis"        
#> [21] "pericalcarine"            "postcentral"             
#> [23] "posteriorcingulate"       "precentral"              
#> [25] "precuneus"                "rostralanteriorcingulate"
#> [27] "rostralmiddlefrontal"     "superiorfrontal"         
#> [29] "superiorparietal"         "superiortemporal"        
#> [31] "supramarginal"            "frontalpole"             
#> [33] "temporalpole"             "transversetemporal"      
#> [35] "insula"
```

[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md)
returns the labels (the identifiers used to join geometry):

``` r

head(atlas_labels(dk()))
#> [1] "lh_bankssts"                "lh_caudalanteriorcingulate"
#> [3] "lh_caudalmiddlefrontal"     "lh_corpuscallosum"         
#> [5] "lh_cuneus"                  "lh_entorhinal"
```

[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md)
returns the curated long-form display names — what you want for a figure
legend:

``` r

head(atlas_names(aseg()))
#> [1] "cerebellum cortex" "thalamus"          "caudate"          
#> [4] "putamen"           "pallidum"          "brain stem"
```

`region` held long-form names itself until version 0.1.0.
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)
translates those old values to the current keys, which is what you need
to fix a table or script written against an earlier release. It reads a
recorded table of what each bundled atlas shipped at 0.0.4, so it is not
the same thing as `names`:

``` r

head(legacy_region_map(aseg()))
#>         Brain Stem        cc anterior         cc central    cc mid anterior 
#>       "brain stem"      "cc anterior"       "cc central"  "cc mid anterior" 
#>   cc mid posterior       cc posterior 
#> "cc mid posterior"     "cc posterior"
```

[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md)
returns the available 2D views:

``` r

atlas_views(dk())
#> [1] "inferior" "lateral"  "medial"   "superior"
atlas_views(aseg())
#> [1] "axial_3"   "axial_4"   "axial_5"   "axial_6"   "coronal_1" "coronal_2"
#> [7] "sagittal"
atlas_views(tracula())
#> [1] "coronal"        "inferior_axial" "mid_axial"      "sagittal"      
#> [5] "superior_axial"
```

[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md)
returns the type string:

``` r

atlas_type(dk())
#> [1] "cortical"
atlas_type(aseg())
#> [1] "subcortical"
atlas_type(tracula())
#> [1] "tract"
```

[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md)
retrieves the colour palette from an atlas object:

``` r

head(atlas_palette(dk()))
#>                lh_bankssts lh_caudalanteriorcingulate 
#>                  "#196428"                  "#7D64A0" 
#>     lh_caudalmiddlefrontal          lh_corpuscallosum 
#>                  "#641900"                  "#784632" 
#>                  lh_cuneus              lh_entorhinal 
#>                  "#DC1464"                  "#DC140A"
```

## Extracting render-ready data

When you need the actual data frames that ggseg and ggseg3d consume, use
the `atlas_*()` extractors. These join core metadata and palette colours
onto the raw geometry so you get a single, ready-to-use table.

[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md)
returns an sf data frame for 2D rendering:

``` r

sf_data <- atlas_sf(dk())
sf_data
#> ── <ggseg_sf> data: 185 × 8 ────────────────────────────────────────────────────
#> Views: inferior, lateral, medial, superior
#> Simple feature collection with 185 features and 7 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 0.899055 ymin: 0.0853615 xmax: 1938.834 ymax: 146.1192
#> CRS:           NA
#> First 10 features:
#>             label     view hemi     region      names    lobe
#> 180    lh_unknown inferior <NA>       <NA>       <NA>    <NA>
#> 181    lh_unknown  lateral <NA>       <NA>       <NA>    <NA>
#> 182    lh_unknown   medial <NA>       <NA>       <NA>    <NA>
#> 183    rh_unknown inferior <NA>       <NA>       <NA>    <NA>
#> 184    rh_unknown  lateral <NA>       <NA>       <NA>    <NA>
#> 185    rh_unknown   medial <NA>       <NA>       <NA>    <NA>
#> 1   lh_precentral inferior left precentral precentral frontal
#> 2   lh_precentral  lateral left precentral precentral frontal
#> 3   lh_precentral   medial left precentral precentral frontal
#> 4   lh_precentral superior left precentral precentral frontal
#>                           geometry  colour
#> 180 MULTIPOLYGON (((59.87309 38...    <NA>
#> 181 MULTIPOLYGON (((309.1881 20...    <NA>
#> 182 MULTIPOLYGON (((561.9354 46...    <NA>
#> 183 MULTIPOLYGON (((1056.938 47...    <NA>
#> 184 MULTIPOLYGON (((1376.635 14...    <NA>
#> 185 MULTIPOLYGON (((1539.551 20...    <NA>
#> 1   MULTIPOLYGON (((66.45332 10... #3C14DC
#> 2   MULTIPOLYGON (((310.8458 85... #3C14DC
#> 3   MULTIPOLYGON (((578.4216 14... #3C14DC
#> 4   MULTIPOLYGON (((804.4479 56... #3C14DC
```

[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md)
returns the vertex data for cortical 3D rendering:

``` r

vert_data <- atlas_vertices(dk())
vert_data
#> ── <ggseg_vertices> data: 70 × 7 ───────────────────────────────────────────────
#> Vertices per region: 18 –759
#>                         label    vertices hemi                  region
#> 1                 lh_bankssts <int [126]> left                bankssts
#> 2  lh_caudalanteriorcingulate  <int [67]> left caudalanteriorcingulate
#> 3      lh_caudalmiddlefrontal <int [232]> left     caudalmiddlefrontal
#> 4           lh_corpuscallosum <int [198]> left          corpuscallosum
#> 5                   lh_cuneus <int [102]> left                  cuneus
#> 6               lh_entorhinal  <int [48]> left              entorhinal
#> 7                 lh_fusiform <int [308]> left                fusiform
#> 8         lh_inferiorparietal <int [484]> left        inferiorparietal
#> 9         lh_inferiortemporal <int [271]> left        inferiortemporal
#> 10        lh_isthmuscingulate <int [123]> left        isthmuscingulate
#>                                names         lobe  colour
#> 1  banks of superior temporal sulcus     temporal #196428
#> 2          caudal anterior cingulate    cingulate #7D64A0
#> 3              caudal middle frontal      frontal #641900
#> 4                    corpus callosum white matter #784632
#> 5                             cuneus    occipital #DC1464
#> 6                         entorhinal     temporal #DC140A
#> 7                           fusiform     temporal #B4DC8C
#> 8                  inferior parietal     parietal #DC3CDC
#> 9                  inferior temporal     temporal #B42878
#> 10                 isthmus cingulate    cingulate #8C148C
#> ... with 60 more rows
```

[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md)
returns mesh data for subcortical or tract 3D rendering:

``` r

mesh_data <- atlas_meshes(aseg())
mesh_data
#> ── <ggseg_meshes> data: 29 × 7 ─────────────────────────────────────────────────
#>                     label vertices faces
#> 1  Left-Cerebellum-Cortex    10618 21228
#> 2           Left-Thalamus     1864  3724
#> 3            Left-Caudate     1512  3028
#> 4            Left-Putamen     1998  3992
#> 5           Left-Pallidum      723  1442
#> 6              Brain-Stem     4608  9212
#> 7        Left-Hippocampus     1892  3780
#> 8           Left-Amygdala      710  1416
#> 9     Left-Accumbens-area      432   860
#> 10         Left-VentralDC     1683  3366
#> ... with 19 more rows
```

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) is a
convenience method that produces a merged sf data frame similar to
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md)
but with atlas-level columns (`atlas`, `type`) attached:

``` r

df <- as.data.frame(dk())
names(df)
#>  [1] "label"    "view"     "hemi"     "region"   "names"    "lobe"    
#>  [7] "geometry" "atlas"    "type"     "colour"
```

## Checking and converting

[`is_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/is_ggseg_atlas.md)
tests whether an object has the right class:

``` r

is_ggseg_atlas(dk())
#> [1] TRUE
is_ggseg_atlas(mtcars)
#> [1] FALSE
```

[`as_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_ggseg_atlas.md)
coerces lists with the right structure into a proper `ggseg_atlas`:

``` r

atlas_list <- as.list(dk())
recovered <- as_ggseg_atlas(atlas_list)
is_ggseg_atlas(recovered)
#> [1] TRUE
```

If you have an atlas object from an older version of ggseg that stored
sf data directly in `$data` instead of using the new `ggseg_atlas_data`
wrapper,
[`convert_legacy_brain_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/convert_legacy_brain_atlas.md)
will migrate it to the unified format.
