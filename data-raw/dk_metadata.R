# DK (Desikan-Killiany) cortical atlas metadata
#
# One row per raw FreeSurfer aparc annotation label. The annotation names are
# already clean and hemisphere-free, so `label` and `region` are identical and
# there is no `hemi` column (hemisphere is assigned per annotation file when
# the atlas is built). `lobe` groups regions.
#
# `display` holds the curated long-form display name. For this atlas it
# coincides
# with the `region` value CRAN 0.0.4 shipped, because the annotation's
# spelled-out names already read well; that is a coincidence, not the contract.
# Migration from the old keys goes through `legacy_region_map()`.
#
# Based on: https://surfer.nmr.mgh.harvard.edu/fswiki/CorticalParcellation

dk_metadata <- data.frame(
  label = c(
    "bankssts",
    "caudalanteriorcingulate",
    "caudalmiddlefrontal",
    "corpuscallosum",
    "cuneus",
    "entorhinal",
    "frontalpole",
    "fusiform",
    "inferiorparietal",
    "inferiortemporal",
    "insula",
    "isthmuscingulate",
    "lateraloccipital",
    "lateralorbitofrontal",
    "lingual",
    "medialorbitofrontal",
    "middletemporal",
    "paracentral",
    "parahippocampal",
    "parsopercularis",
    "parsorbitalis",
    "parstriangularis",
    "pericalcarine",
    "postcentral",
    "posteriorcingulate",
    "precentral",
    "precuneus",
    "rostralanteriorcingulate",
    "rostralmiddlefrontal",
    "superiorfrontal",
    "superiorparietal",
    "superiortemporal",
    "supramarginal",
    "temporalpole",
    "transversetemporal"
  ),
  display = c(
    "banks of superior temporal sulcus",
    "caudal anterior cingulate",
    "caudal middle frontal",
    "corpus callosum",
    "cuneus",
    "entorhinal",
    "frontal pole",
    "fusiform",
    "inferior parietal",
    "inferior temporal",
    "insula",
    "isthmus cingulate",
    "lateral occipital",
    "lateral orbitofrontal",
    "lingual",
    "medial orbitofrontal",
    "middle temporal",
    "paracentral",
    "parahippocampal",
    "pars opercularis",
    "pars orbitalis",
    "pars triangularis",
    "pericalcarine",
    "postcentral",
    "posterior cingulate",
    "precentral",
    "precuneus",
    "rostral anterior cingulate",
    "rostral middle frontal",
    "superior frontal",
    "superior parietal",
    "superior temporal",
    "supramarginal",
    "temporal pole",
    "transverse temporal"
  ),
  lobe = c(
    "temporal",
    "cingulate",
    "frontal",
    "white matter",
    "occipital",
    "temporal",
    "frontal",
    "temporal",
    "parietal",
    "temporal",
    "insula",
    "cingulate",
    "occipital",
    "frontal",
    "occipital",
    "frontal",
    "temporal",
    "frontal",
    "temporal",
    "frontal",
    "frontal",
    "frontal",
    "occipital",
    "parietal",
    "cingulate",
    "frontal",
    "parietal",
    "cingulate",
    "frontal",
    "frontal",
    "parietal",
    "temporal",
    "parietal",
    "temporal",
    "temporal"
  )
)

dk_metadata$region <- dk_metadata$label

dk_metadata <- dk_metadata[, c("label", "region", "display", "lobe")]
