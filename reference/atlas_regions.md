# Extract the region column of an atlas

Extract the region column of an atlas

## Usage

``` r
atlas_regions(x)

brain_regions(x)
```

## Arguments

- x:

  brain atlas

## Value

The `region` column of `core`, unchanged: one element per `core` row, in
`core` row order, with repeats and `NA`s retained. It is therefore
row-aligned with
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md)
and
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md).
Use [`unique()`](https://rdrr.io/r/base/unique.html) for the distinct
set. A zero-length character vector when the atlas carries no `region`
column.

## See also

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md),
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
atlas_regions(dk())
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
#> [35] "insula"                   "bankssts"                
#> [37] "caudalanteriorcingulate"  "caudalmiddlefrontal"     
#> [39] "corpuscallosum"           "cuneus"                  
#> [41] "entorhinal"               "fusiform"                
#> [43] "inferiorparietal"         "inferiortemporal"        
#> [45] "isthmuscingulate"         "lateraloccipital"        
#> [47] "lateralorbitofrontal"     "lingual"                 
#> [49] "medialorbitofrontal"      "middletemporal"          
#> [51] "parahippocampal"          "paracentral"             
#> [53] "parsopercularis"          "parsorbitalis"           
#> [55] "parstriangularis"         "pericalcarine"           
#> [57] "postcentral"              "posteriorcingulate"      
#> [59] "precentral"               "precuneus"               
#> [61] "rostralanteriorcingulate" "rostralmiddlefrontal"    
#> [63] "superiorfrontal"          "superiorparietal"        
#> [65] "superiortemporal"         "supramarginal"           
#> [67] "frontalpole"              "temporalpole"            
#> [69] "transversetemporal"       "insula"                  
atlas_regions(aseg())
#>  [1] "cerebellum cortex" "thalamus"          "caudate"          
#>  [4] "putamen"           "pallidum"          "brain stem"       
#>  [7] "hippocampus"       "amygdala"          "accumbens area"   
#> [10] "ventraldc"         "vessel"            "choroid plexus"   
#> [13] "cerebellum cortex" "thalamus"          "caudate"          
#> [16] "putamen"           "pallidum"          "hippocampus"      
#> [19] "amygdala"          "accumbens area"    "ventraldc"        
#> [22] "vessel"            "choroid plexus"    "optic chiasm"     
#> [25] "cc posterior"      "cc mid posterior"  "cc central"       
#> [28] "cc mid anterior"   "cc anterior"      
```
