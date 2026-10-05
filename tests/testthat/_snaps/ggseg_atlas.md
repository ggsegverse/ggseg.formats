# ggseg_atlas class / print method works

    Code
      print(dk())
    Message
      
      -- dk ggseg atlas --------------------------------------------------------------
      Type: cortical
      Regions: 35
      Hemispheres: left, right
      Views: inferior, lateral, medial, superior
      Palette: v
      Rendering: v ggseg
      v ggseg3d (vertices)
      --------------------------------------------------------------------------------
    Output
         hemi                  region                      label
      1  left                bankssts                lh_bankssts
      2  left caudalanteriorcingulate lh_caudalanteriorcingulate
      3  left     caudalmiddlefrontal     lh_caudalmiddlefrontal
      4  left          corpuscallosum          lh_corpuscallosum
      5  left                  cuneus                  lh_cuneus
      6  left              entorhinal              lh_entorhinal
      7  left                fusiform                lh_fusiform
      8  left        inferiorparietal        lh_inferiorparietal
      9  left        inferiortemporal        lh_inferiortemporal
      10 left        isthmuscingulate        lh_isthmuscingulate
                                     names         lobe
      1  banks of superior temporal sulcus     temporal
      2          caudal anterior cingulate    cingulate
      3              caudal middle frontal      frontal
      4                    corpus callosum white matter
      5                             cuneus    occipital
      6                         entorhinal     temporal
      7                           fusiform     temporal
      8                  inferior parietal     parietal
      9                  inferior temporal     temporal
      10                 isthmus cingulate    cingulate
    Message
      ... with 60 more rows

# ggseg_atlas class / print caps core rows at n

    Code
      print(dk(), n = 3)
    Message
      
      -- dk ggseg atlas --------------------------------------------------------------
      Type: cortical
      Regions: 35
      Hemispheres: left, right
      Views: inferior, lateral, medial, superior
      Palette: v
      Rendering: v ggseg
      v ggseg3d (vertices)
      --------------------------------------------------------------------------------
    Output
        hemi                  region                      label
      1 left                bankssts                lh_bankssts
      2 left caudalanteriorcingulate lh_caudalanteriorcingulate
      3 left     caudalmiddlefrontal     lh_caudalmiddlefrontal
                                    names      lobe
      1 banks of superior temporal sulcus  temporal
      2         caudal anterior cingulate cingulate
      3             caudal middle frontal   frontal
    Message
      ... with 67 more rows

---

    Code
      print(dk(), n = 6)
    Message
      
      -- dk ggseg atlas --------------------------------------------------------------
      Type: cortical
      Regions: 35
      Hemispheres: left, right
      Views: inferior, lateral, medial, superior
      Palette: v
      Rendering: v ggseg
      v ggseg3d (vertices)
      --------------------------------------------------------------------------------
    Output
        hemi                  region                      label
      1 left                bankssts                lh_bankssts
      2 left caudalanteriorcingulate lh_caudalanteriorcingulate
      3 left     caudalmiddlefrontal     lh_caudalmiddlefrontal
      4 left          corpuscallosum          lh_corpuscallosum
      5 left                  cuneus                  lh_cuneus
      6 left              entorhinal              lh_entorhinal
                                    names         lobe
      1 banks of superior temporal sulcus     temporal
      2         caudal anterior cingulate    cingulate
      3             caudal middle frontal      frontal
      4                   corpus callosum white matter
      5                            cuneus    occipital
      6                        entorhinal     temporal
    Message
      ... with 64 more rows

# print.ggseg_atlas rendering branches / prints a tract atlas (centerlines)

    Code
      print(tracula())
    Message
      
      -- tracula ggseg atlas ---------------------------------------------------------
      Type: tract
      Regions: 26
      Hemispheres: midline, left, right
      Views: coronal, inferior_axial, mid_axial, sagittal, superior_axial
      Palette: v
      Rendering: v ggseg
      v ggseg3d (centerlines)
      --------------------------------------------------------------------------------
    Output
            hemi      region                label label_short
      1  midline       acomm       acomm.bbr.prep       acomm
      2  midline    cc bodyc    cc.bodyc.bbr.prep    cc.bodyc
      3  midline    cc bodyp    cc.bodyp.bbr.prep    cc.bodyp
      4  midline   cc bodypf   cc.bodypf.bbr.prep   cc.bodypf
      5  midline   cc bodypm   cc.bodypm.bbr.prep   cc.bodypm
      6  midline    cc bodyt    cc.bodyt.bbr.prep    cc.bodyt
      7  midline     cc genu     cc.genu.bbr.prep     cc.genu
      8  midline  cc rostrum  cc.rostrum.bbr.prep  cc.rostrum
      9  midline cc splenium cc.splenium.bbr.prep cc.splenium
      10    left          af       lh.af.bbr.prep       lh.af
                                   names           group
      1              anterior commissure      commissure
      2     corpus callosum body central corpus callosum
      3    corpus callosum body parietal corpus callosum
      4  corpus callosum body prefrontal corpus callosum
      5    corpus callosum body premotor corpus callosum
      6    corpus callosum body temporal corpus callosum
      7             corpus callosum genu corpus callosum
      8          corpus callosum rostrum corpus callosum
      9         corpus callosum splenium corpus callosum
      10              arcuate fasciculus     association
    Message
      ... with 32 more rows

# print.ggseg_atlas rendering branches / prints a subcortical atlas (meshes)

    Code
      print(aseg())
    Message
      
      -- aseg ggseg atlas ------------------------------------------------------------
      Type: subcortical
      Regions: 18
      Hemispheres: left, NA, right
      Views: axial_3, axial_4, axial_5, axial_6, coronal_1, coronal_2, sagittal
      Palette: v
      Rendering: v ggseg
      v ggseg3d (meshes)
      --------------------------------------------------------------------------------
    Output
         hemi            region                  label                names
      1  left cerebellum cortex Left-Cerebellum-Cortex    cerebellum cortex
      2  left          thalamus          Left-Thalamus             thalamus
      3  left           caudate           Left-Caudate              caudate
      4  left           putamen           Left-Putamen              putamen
      5  left          pallidum          Left-Pallidum             pallidum
      6  <NA>        brain stem             Brain-Stem           brain stem
      7  left       hippocampus       Left-Hippocampus          hippocampus
      8  left          amygdala          Left-Amygdala             amygdala
      9  left    accumbens area    Left-Accumbens-area            accumbens
      10 left         ventraldc         Left-VentralDC ventral diencephalon
             structure
      1     cerebellum
      2  basal ganglia
      3  basal ganglia
      4  basal ganglia
      5  basal ganglia
      6      brainstem
      7         limbic
      8         limbic
      9  basal ganglia
      10  diencephalon
    Message
      ... with 19 more rows

# print.ggseg_atlas rendering branches / prints a cortical atlas (vertices)

    Code
      print(dk())
    Message
      
      -- dk ggseg atlas --------------------------------------------------------------
      Type: cortical
      Regions: 35
      Hemispheres: left, right
      Views: inferior, lateral, medial, superior
      Palette: v
      Rendering: v ggseg
      v ggseg3d (vertices)
      --------------------------------------------------------------------------------
    Output
         hemi                  region                      label
      1  left                bankssts                lh_bankssts
      2  left caudalanteriorcingulate lh_caudalanteriorcingulate
      3  left     caudalmiddlefrontal     lh_caudalmiddlefrontal
      4  left          corpuscallosum          lh_corpuscallosum
      5  left                  cuneus                  lh_cuneus
      6  left              entorhinal              lh_entorhinal
      7  left                fusiform                lh_fusiform
      8  left        inferiorparietal        lh_inferiorparietal
      9  left        inferiortemporal        lh_inferiortemporal
      10 left        isthmuscingulate        lh_isthmuscingulate
                                     names         lobe
      1  banks of superior temporal sulcus     temporal
      2          caudal anterior cingulate    cingulate
      3              caudal middle frontal      frontal
      4                    corpus callosum white matter
      5                             cuneus    occipital
      6                         entorhinal     temporal
      7                           fusiform     temporal
      8                  inferior parietal     parietal
      9                  inferior temporal     temporal
      10                 isthmus cingulate    cingulate
    Message
      ... with 60 more rows

# print.ggseg_atlas rendering branches / prints an atlas with no 3D geometry as none

    Code
      print(atlas)
    Message
      
      -- test ggseg atlas ------------------------------------------------------------
      Type: cerebellar
      Regions: 1
      Hemispheres: left
      Views: lateral
      Palette: x
      Rendering: v ggseg
      x ggseg3d (none)
      --------------------------------------------------------------------------------
    Output
        hemi  region      label   names
      1 left frontal lh_frontal frontal

# print.ggseg_atlas rendering branches / prints a polygon atlas summary with views

    Code
      print(poly_atlas)
    Message
      
      -- dk ggseg atlas --------------------------------------------------------------
      Type: cortical
      Regions: 35
      Hemispheres: left, right
      Views: inferior, lateral, medial, superior
      Palette: v
      Rendering: v ggseg
      v ggseg3d (vertices)
      --------------------------------------------------------------------------------
    Output
         hemi                  region                      label
      1  left                bankssts                lh_bankssts
      2  left caudalanteriorcingulate lh_caudalanteriorcingulate
      3  left     caudalmiddlefrontal     lh_caudalmiddlefrontal
      4  left          corpuscallosum          lh_corpuscallosum
      5  left                  cuneus                  lh_cuneus
      6  left              entorhinal              lh_entorhinal
      7  left                fusiform                lh_fusiform
      8  left        inferiorparietal        lh_inferiorparietal
      9  left        inferiortemporal        lh_inferiortemporal
      10 left        isthmuscingulate        lh_isthmuscingulate
                                     names         lobe
      1  banks of superior temporal sulcus     temporal
      2          caudal anterior cingulate    cingulate
      3              caudal middle frontal      frontal
      4                    corpus callosum white matter
      5                             cuneus    occipital
      6                         entorhinal     temporal
      7                           fusiform     temporal
      8                  inferior parietal     parietal
      9                  inferior temporal     temporal
      10                 isthmus cingulate    cingulate
    Message
      ... with 60 more rows

