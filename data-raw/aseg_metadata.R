# ASEG (Automatic Subcortical Segmentation) metadata
#
# One row per raw FreeSurfer aseg label. `label` is the untouched atlas
# identifier; `hemi` and `region` are derived mechanically from it (hemisphere
# stripped into `hemi`, the remainder lowercased with separators spaced);
# `structure` groups regions.
#
# `display` holds the curated long-form display name: fully spelled out, chosen
# to read well as a figure label or legend entry. It is deliberately NOT the
# `region` value the CRAN 0.0.4 release shipped -- several of those were
# mechanically derived and read poorly. Migration from the old keys goes
# through data-raw/legacy_regions.R and `legacy_region_map()` instead.
#
# Based on: # nolint start: line_length_linter.
# https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/AnatomicalROI/FreeSurferColorLUT
# nolint end

aseg_metadata <- data.frame(
  label = c(
    # Cortical (used as context, not primary regions)
    "Left-Cerebral-Cortex",
    "Right-Cerebral-Cortex",
    # White matter
    "Left-Cerebral-White-Matter",
    "Right-Cerebral-White-Matter",
    # Lateral ventricles
    "Left-Lateral-Ventricle",
    "Right-Lateral-Ventricle",
    "Left-Inf-Lat-Vent",
    "Right-Inf-Lat-Vent",
    # Third and fourth ventricles
    "3rd-Ventricle",
    "4th-Ventricle",
    # CSF
    "CSF",
    # Deep gray matter
    "Left-Thalamus",
    "Right-Thalamus",
    "Left-Caudate",
    "Right-Caudate",
    "Left-Putamen",
    "Right-Putamen",
    "Left-Pallidum",
    "Right-Pallidum",
    # Hippocampal formation
    "Left-Hippocampus",
    "Right-Hippocampus",
    "Left-Amygdala",
    "Right-Amygdala",
    # Accumbens
    "Left-Accumbens-area",
    "Right-Accumbens-area",
    # Ventral diencephalon
    "Left-VentralDC",
    "Right-VentralDC",
    # Vessels and choroid plexus
    "Left-vessel",
    "Right-vessel",
    "Left-choroid-plexus",
    "Right-choroid-plexus",
    # Brainstem
    "Brain-Stem",
    # Cerebellum
    "Left-Cerebellum-Cortex",
    "Right-Cerebellum-Cortex",
    "Left-Cerebellum-White-Matter",
    "Right-Cerebellum-White-Matter",
    # Other
    "Left-Thalamus-Proper",
    "Right-Thalamus-Proper",
    "WM-hypointensities",
    "non-WM-hypointensities",
    "Optic-Chiasm",
    "CC_Posterior",
    "CC_Mid_Posterior",
    "CC_Central",
    "CC_Mid_Anterior",
    "CC_Anterior"
  ),
  display = c(
    "cerebral cortex",
    "cerebral cortex",
    "cerebral white matter",
    "cerebral white matter",
    "lateral ventricle",
    "lateral ventricle",
    "inferior lateral ventricle",
    "inferior lateral ventricle",
    "third ventricle",
    "fourth ventricle",
    "cerebrospinal fluid",
    "thalamus",
    "thalamus",
    "caudate",
    "caudate",
    "putamen",
    "putamen",
    "pallidum",
    "pallidum",
    "hippocampus",
    "hippocampus",
    "amygdala",
    "amygdala",
    "accumbens",
    "accumbens",
    "ventral diencephalon",
    "ventral diencephalon",
    "vessel",
    "vessel",
    "choroid plexus",
    "choroid plexus",
    "brain stem",
    "cerebellum cortex",
    "cerebellum cortex",
    "cerebellum white matter",
    "cerebellum white matter",
    "thalamus proper",
    "thalamus proper",
    "white matter hypointensities",
    "non-white matter hypointensities",
    "optic chiasm",
    "corpus callosum posterior",
    "corpus callosum mid-posterior",
    "corpus callosum central",
    "corpus callosum mid-anterior",
    "corpus callosum anterior"
  ),
  structure = c(
    "cortex",
    "cortex",
    "white matter",
    "white matter",
    "ventricle",
    "ventricle",
    "ventricle",
    "ventricle",
    "ventricle",
    "ventricle",
    "csf",
    "basal ganglia",
    "basal ganglia",
    "basal ganglia",
    "basal ganglia",
    "basal ganglia",
    "basal ganglia",
    "basal ganglia",
    "basal ganglia",
    "limbic",
    "limbic",
    "limbic",
    "limbic",
    "basal ganglia",
    "basal ganglia",
    "diencephalon",
    "diencephalon",
    "other",
    "other",
    "ventricle",
    "ventricle",
    "brainstem",
    "cerebellum",
    "cerebellum",
    "cerebellum",
    "cerebellum",
    "basal ganglia",
    "basal ganglia",
    "white matter",
    "other",
    "other",
    "corpus callosum",
    "corpus callosum",
    "corpus callosum",
    "corpus callosum",
    "corpus callosum"
  )
)

aseg_metadata$hemi <- "midline"
aseg_metadata$hemi[grepl("^Left-", aseg_metadata$label)] <- "left"
aseg_metadata$hemi[grepl("^Right-", aseg_metadata$label)] <- "right"

aseg_metadata$region <- tolower(
  gsub("[-_]", " ", sub("^(Left|Right)-", "", aseg_metadata$label))
)

aseg_metadata <- aseg_metadata[,
  c("label", "hemi", "region", "display", "structure")
]
