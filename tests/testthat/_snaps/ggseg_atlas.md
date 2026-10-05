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
            hemi      region                label label_short               names
      1  midline       acomm       acomm.bbr.prep       acomm anterior commissure
      2  midline    cc bodyc    cc.bodyc.bbr.prep    cc.bodyc     CC body central
      3  midline    cc bodyp    cc.bodyp.bbr.prep    cc.bodyp    CC body parietal
      4  midline   cc bodypf   cc.bodypf.bbr.prep   cc.bodypf  CC body prefrontal
      5  midline   cc bodypm   cc.bodypm.bbr.prep   cc.bodypm    CC body premotor
      6  midline    cc bodyt    cc.bodyt.bbr.prep    cc.bodyt    CC body temporal
      7  midline     cc genu     cc.genu.bbr.prep     cc.genu             CC genu
      8  midline  cc rostrum  cc.rostrum.bbr.prep  cc.rostrum          CC rostrum
      9  midline cc splenium cc.splenium.bbr.prep cc.splenium         CC splenium
      10    left          af       lh.af.bbr.prep       lh.af  arcuate fasciculus
                   group
      1       commissure
      2  corpus callosum
      3  corpus callosum
      4  corpus callosum
      5  corpus callosum
      6  corpus callosum
      7  corpus callosum
      8  corpus callosum
      9  corpus callosum
      10     association
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
         hemi            region                  label          names     structure
      1  left cerebellum cortex Left-Cerebellum-Cortex     Cerebellum    cerebellum
      2  left          thalamus          Left-Thalamus       Thalamus basal ganglia
      3  left           caudate           Left-Caudate        Caudate basal ganglia
      4  left           putamen           Left-Putamen        Putamen basal ganglia
      5  left          pallidum          Left-Pallidum       Pallidum basal ganglia
      6  <NA>        brain stem             Brain-Stem     Brain Stem     brainstem
      7  left       hippocampus       Left-Hippocampus    Hippocampus        limbic
      8  left          amygdala          Left-Amygdala       Amygdala        limbic
      9  left    accumbens area    Left-Accumbens-area accumbens area basal ganglia
      10 left         ventraldc         Left-VentralDC      ventraldc  diencephalon
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

