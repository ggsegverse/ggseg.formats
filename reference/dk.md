# Desikan-Killiany Cortical Atlas

Returns the Desikan-Killiany cortical parcellation atlas with 34 regions
per hemisphere (68 total) on the cortical surface.

## Usage

``` r
dk()
```

## Value

A `ggseg_atlas` object with components:

- atlas:

  Character. Atlas name ("dk")

- type:

  Character. Atlas type ("cortical")

- palette:

  Named character vector of colours for each region

- data:

  A `ggseg_data_cortical` object containing:

  vertices

  :   Data frame with `label` and `vertices` columns

  sf

  :   Simple features data frame for 2D rendering

## Details

This atlas is based on the FreeSurfer `aparc` annotation and is one of
the most widely used cortical parcellations in neuroimaging research.

The atlas works with both ggseg (2D polygon plots) and ggseg3d (3D mesh
visualizations) from a single object.

## Core columns

`core` carries one row per atlas region with the columns `hemi`,
`region`, `label` and `names`, plus the atlas's own grouping column.
`label` is the stable atlas identifier and the key the palette and the
geometry are keyed on; `region` is a short, hemisphere-free key derived
from it; `names` is the curated long-form display name, spelled out to
read well in a figure legend.

`region` held the long-form name until version 0.1.0. `names` is not a
record of those old values – use
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)
to translate them.

## Regions

The atlas contains 34 regions per hemisphere including: banks of
superior temporal sulcus, caudal anterior cingulate, caudal middle
frontal, cuneus, entorhinal, fusiform, inferior parietal, inferior
temporal, isthmus cingulate, lateral occipital, lateral orbitofrontal,
lingual, medial orbitofrontal, middle temporal, parahippocampal,
paracentral, pars opercularis, pars orbitalis, pars triangularis,
pericalcarine, postcentral, posterior cingulate, precentral, precuneus,
rostral anterior cingulate, rostral middle frontal, superior frontal,
superior parietal, superior temporal, supramarginal, frontal pole,
temporal pole, transverse temporal, and insula.

## References

Desikan RS, Segonne F, Fischl B, et al. (2006). An automated labeling
system for subdividing the human cerebral cortex on MRI scans into gyral
based regions of interest. NeuroImage, 31(3):968-980.
[doi:10.1016/j.neuroimage.2006.01.021](https://doi.org/10.1016/j.neuroimage.2006.01.021)

Fischl B, van der Kouwe A, Destrieux C, et al. (2004). Automatically
parcellating the human cerebral cortex. Cerebral Cortex, 14(1):11-22.
[doi:10.1093/cercor/bhg087](https://doi.org/10.1093/cercor/bhg087)

## See also

[`aseg()`](https://ggsegverse.github.io/ggseg.formats/reference/aseg.md)
for subcortical structures,
[`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md)
for the atlas class constructor

Other ggseg_atlases:
[`aseg()`](https://ggsegverse.github.io/ggseg.formats/reference/aseg.md),
[`suit()`](https://ggsegverse.github.io/ggseg.formats/reference/suit.md),
[`tracula()`](https://ggsegverse.github.io/ggseg.formats/reference/tracula.md)

## Examples

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
plot(dk())

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
```
