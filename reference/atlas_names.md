# Extract the long-form region name column of an atlas

The `names` column of `core` holds the long-form display name of each
region, as against the short, hemisphere-free key in `region` and the
atlas identifier in `label`. For the atlases bundled here it is also the
`region` value shipped before the 0.1.0 re-keying, which is what makes
that re-keying recoverable; see
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md).

## Usage

``` r
atlas_names(x)
```

## Arguments

- x:

  brain atlas

## Value

The `names` column of `core`, unchanged: one element per `core` row, in
`core` row order, with repeats and `NA`s retained. It is therefore
row-aligned with
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md)
and
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md).
Use [`unique()`](https://rdrr.io/r/base/unique.html) for the distinct
set. A zero-length character vector when the atlas carries no `names`
column.

## See also

[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
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
atlas_names(dk())
#>  [1] "banks of superior temporal sulcus" "caudal anterior cingulate"        
#>  [3] "caudal middle frontal"             "corpus callosum"                  
#>  [5] "cuneus"                            "entorhinal"                       
#>  [7] "fusiform"                          "inferior parietal"                
#>  [9] "inferior temporal"                 "isthmus cingulate"                
#> [11] "lateral occipital"                 "lateral orbitofrontal"            
#> [13] "lingual"                           "medial orbitofrontal"             
#> [15] "middle temporal"                   "parahippocampal"                  
#> [17] "paracentral"                       "pars opercularis"                 
#> [19] "pars orbitalis"                    "pars triangularis"                
#> [21] "pericalcarine"                     "postcentral"                      
#> [23] "posterior cingulate"               "precentral"                       
#> [25] "precuneus"                         "rostral anterior cingulate"       
#> [27] "rostral middle frontal"            "superior frontal"                 
#> [29] "superior parietal"                 "superior temporal"                
#> [31] "supramarginal"                     "frontal pole"                     
#> [33] "temporal pole"                     "transverse temporal"              
#> [35] "insula"                            "banks of superior temporal sulcus"
#> [37] "caudal anterior cingulate"         "caudal middle frontal"            
#> [39] "corpus callosum"                   "cuneus"                           
#> [41] "entorhinal"                        "fusiform"                         
#> [43] "inferior parietal"                 "inferior temporal"                
#> [45] "isthmus cingulate"                 "lateral occipital"                
#> [47] "lateral orbitofrontal"             "lingual"                          
#> [49] "medial orbitofrontal"              "middle temporal"                  
#> [51] "parahippocampal"                   "paracentral"                      
#> [53] "pars opercularis"                  "pars orbitalis"                   
#> [55] "pars triangularis"                 "pericalcarine"                    
#> [57] "postcentral"                       "posterior cingulate"              
#> [59] "precentral"                        "precuneus"                        
#> [61] "rostral anterior cingulate"        "rostral middle frontal"           
#> [63] "superior frontal"                  "superior parietal"                
#> [65] "superior temporal"                 "supramarginal"                    
#> [67] "frontal pole"                      "temporal pole"                    
#> [69] "transverse temporal"               "insula"                           
atlas_names(aseg())
#>  [1] "cerebellum cortex"             "thalamus"                     
#>  [3] "caudate"                       "putamen"                      
#>  [5] "pallidum"                      "brain stem"                   
#>  [7] "hippocampus"                   "amygdala"                     
#>  [9] "accumbens"                     "ventral diencephalon"         
#> [11] "vessel"                        "choroid plexus"               
#> [13] "cerebellum cortex"             "thalamus"                     
#> [15] "caudate"                       "putamen"                      
#> [17] "pallidum"                      "hippocampus"                  
#> [19] "amygdala"                      "accumbens"                    
#> [21] "ventral diencephalon"          "vessel"                       
#> [23] "choroid plexus"                "optic chiasm"                 
#> [25] "corpus callosum posterior"     "corpus callosum mid-posterior"
#> [27] "corpus callosum central"       "corpus callosum mid-anterior" 
#> [29] "corpus callosum anterior"     
```
