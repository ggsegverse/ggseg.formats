# Extract the label column of an atlas

Extract the label column of an atlas

## Usage

``` r
atlas_labels(x)

brain_labels(x)
```

## Arguments

- x:

  brain atlas

## Value

The `label` column of `core`, unchanged: one element per `core` row, in
`core` row order, with repeats and `NA`s retained. It is therefore
row-aligned with
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md)
and
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md).
Use [`unique()`](https://rdrr.io/r/base/unique.html) for the distinct
set. A zero-length character vector when the atlas carries no `label`
column.

## See also

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
[`atlas_names()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_names.md),
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md),
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
atlas_labels(dk())
#>  [1] "lh_bankssts"                 "lh_caudalanteriorcingulate" 
#>  [3] "lh_caudalmiddlefrontal"      "lh_corpuscallosum"          
#>  [5] "lh_cuneus"                   "lh_entorhinal"              
#>  [7] "lh_fusiform"                 "lh_inferiorparietal"        
#>  [9] "lh_inferiortemporal"         "lh_isthmuscingulate"        
#> [11] "lh_lateraloccipital"         "lh_lateralorbitofrontal"    
#> [13] "lh_lingual"                  "lh_medialorbitofrontal"     
#> [15] "lh_middletemporal"           "lh_parahippocampal"         
#> [17] "lh_paracentral"              "lh_parsopercularis"         
#> [19] "lh_parsorbitalis"            "lh_parstriangularis"        
#> [21] "lh_pericalcarine"            "lh_postcentral"             
#> [23] "lh_posteriorcingulate"       "lh_precentral"              
#> [25] "lh_precuneus"                "lh_rostralanteriorcingulate"
#> [27] "lh_rostralmiddlefrontal"     "lh_superiorfrontal"         
#> [29] "lh_superiorparietal"         "lh_superiortemporal"        
#> [31] "lh_supramarginal"            "lh_frontalpole"             
#> [33] "lh_temporalpole"             "lh_transversetemporal"      
#> [35] "lh_insula"                   "rh_bankssts"                
#> [37] "rh_caudalanteriorcingulate"  "rh_caudalmiddlefrontal"     
#> [39] "rh_corpuscallosum"           "rh_cuneus"                  
#> [41] "rh_entorhinal"               "rh_fusiform"                
#> [43] "rh_inferiorparietal"         "rh_inferiortemporal"        
#> [45] "rh_isthmuscingulate"         "rh_lateraloccipital"        
#> [47] "rh_lateralorbitofrontal"     "rh_lingual"                 
#> [49] "rh_medialorbitofrontal"      "rh_middletemporal"          
#> [51] "rh_parahippocampal"          "rh_paracentral"             
#> [53] "rh_parsopercularis"          "rh_parsorbitalis"           
#> [55] "rh_parstriangularis"         "rh_pericalcarine"           
#> [57] "rh_postcentral"              "rh_posteriorcingulate"      
#> [59] "rh_precentral"               "rh_precuneus"               
#> [61] "rh_rostralanteriorcingulate" "rh_rostralmiddlefrontal"    
#> [63] "rh_superiorfrontal"          "rh_superiorparietal"        
#> [65] "rh_superiortemporal"         "rh_supramarginal"           
#> [67] "rh_frontalpole"              "rh_temporalpole"            
#> [69] "rh_transversetemporal"       "rh_insula"                  
atlas_labels(aseg())
#>  [1] "Left-Cerebellum-Cortex"  "Left-Thalamus"          
#>  [3] "Left-Caudate"            "Left-Putamen"           
#>  [5] "Left-Pallidum"           "Brain-Stem"             
#>  [7] "Left-Hippocampus"        "Left-Amygdala"          
#>  [9] "Left-Accumbens-area"     "Left-VentralDC"         
#> [11] "Left-vessel"             "Left-choroid-plexus"    
#> [13] "Right-Cerebellum-Cortex" "Right-Thalamus"         
#> [15] "Right-Caudate"           "Right-Putamen"          
#> [17] "Right-Pallidum"          "Right-Hippocampus"      
#> [19] "Right-Amygdala"          "Right-Accumbens-area"   
#> [21] "Right-VentralDC"         "Right-vessel"           
#> [23] "Right-choroid-plexus"    "Optic-Chiasm"           
#> [25] "CC_Posterior"            "CC_Mid_Posterior"       
#> [27] "CC_Central"              "CC_Mid_Anterior"        
#> [29] "CC_Anterior"            
```
