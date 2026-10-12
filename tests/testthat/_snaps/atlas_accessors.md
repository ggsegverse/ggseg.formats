# atlas_sf / prints without error and keeps its classes

    Code
      print(sf_data)
    Message
      -- <ggseg_sf> data: 2 × 3 ------------------------------------------------------
      Views: lateral, medial
    Output
      Simple feature collection with 2 features and 2 fields
      Geometry type: POLYGON
      Dimension:     XY
      Bounding box:  xmin: 0 ymin: 0 xmax: 3 ymax: 1
      CRS:           NA
        label    view                       geometry
      1  lh_a lateral POLYGON ((0 0, 1 0, 1 1, 0 0))
      2  lh_b  medial POLYGON ((2 0, 3 0, 3 1, 2 0))

# atlas_vertices / prints without error and keeps its classes

    Code
      print(result)
    Message
      -- <ggseg_vertices> data: 70 × 7 -----------------------------------------------
      Vertices per region: 18 –759
    Output
                              label    vertices hemi                  region
      1                 lh_bankssts <int [126]> left                bankssts
      2  lh_caudalanteriorcingulate  <int [67]> left caudalanteriorcingulate
      3      lh_caudalmiddlefrontal <int [232]> left     caudalmiddlefrontal
      4           lh_corpuscallosum <int [198]> left          corpuscallosum
      5                   lh_cuneus <int [102]> left                  cuneus
      6               lh_entorhinal  <int [48]> left              entorhinal
      7                 lh_fusiform <int [308]> left                fusiform
      8         lh_inferiorparietal <int [484]> left        inferiorparietal
      9         lh_inferiortemporal <int [271]> left        inferiortemporal
      10        lh_isthmuscingulate <int [123]> left        isthmuscingulate
                                   display         lobe  colour
      1  banks of superior temporal sulcus     temporal #196428
      2          caudal anterior cingulate    cingulate #7D64A0
      3              caudal middle frontal      frontal #641900
      4                    corpus callosum white matter #784632
      5                             cuneus    occipital #DC1464
      6                         entorhinal     temporal #DC140A
      7                           fusiform     temporal #B4DC8C
      8                  inferior parietal     parietal #DC3CDC
      9                  inferior temporal     temporal #B42878
      10                 isthmus cingulate    cingulate #8C148C
    Message
      ... with 60 more rows

# atlas_meshes / prints without error and keeps its classes

    Code
      print(result)
    Message
      -- <ggseg_meshes> data: 29 × 7 -------------------------------------------------
    Output
                          label vertices faces
      1  Left-Cerebellum-Cortex    10618 21228
      2           Left-Thalamus     1864  3724
      3            Left-Caudate     1512  3028
      4            Left-Putamen     1998  3992
      5           Left-Pallidum      723  1442
      6              Brain-Stem     4608  9212
      7        Left-Hippocampus     1892  3780
      8           Left-Amygdala      710  1416
      9     Left-Accumbens-area      432   860
      10         Left-VentralDC     1683  3366
    Message
      ... with 19 more rows

