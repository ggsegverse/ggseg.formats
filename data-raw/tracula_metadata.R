# TRACULA tract metadata
#
# One row per FreeSurfer TRACULA tract. `label` is the atlas identifier: the
# name TRACULA writes its per-pathway outputs under, which carries a trailing
# .bbr.prep. That suffix names a processing step rather than the tract, but it
# is what FreeSurfer emits and what users join their own tables on, so it is
# the canonical key. `label_short` is the same identifier with the suffix
# stripped -- the name FreeSurferColorLUT.txt gives the pathway (ids
# 5100-5399). `hemi` and `region` are derived mechanically from `label_short`
# (the lh./rh. prefix becomes `hemi`, the remainder with dots spaced becomes
# `region`); `group` classifies tracts.
#
# `display` holds the curated long-form display name: fully spelled out, chosen
# to read well as a figure label or legend entry. It is deliberately NOT the
# `region` value the CRAN 0.0.4 release shipped -- several of those were
# mechanically derived and read poorly. Migration from the old keys goes
# through data-raw/legacy_regions.R and `legacy_region_map()` instead.
#
# Based on: https://surfer.nmr.mgh.harvard.edu/fswiki/Tracula

tracula_metadata <- data.frame(
  label_short = c(
    # Corpus callosum segments
    "cc.rostrum",
    "cc.genu",
    "cc.bodyc",
    "cc.bodypf",
    "cc.bodypm",
    "cc.bodyp",
    "cc.bodyt",
    "cc.splenium",
    # Anterior commissure
    "acomm",
    # Middle cerebellar peduncle
    "mcp",
    # Left hemisphere tracts
    "lh.cst",
    "lh.af",
    "lh.ar",
    "lh.atr",
    "lh.cbd",
    "lh.cbv",
    "lh.emc",
    "lh.fat",
    "lh.fx",
    "lh.ilf",
    "lh.mlf",
    "lh.or",
    "lh.slf1",
    "lh.slf2",
    "lh.slf3",
    "lh.uf",
    # Right hemisphere tracts
    "rh.cst",
    "rh.af",
    "rh.ar",
    "rh.atr",
    "rh.cbd",
    "rh.cbv",
    "rh.emc",
    "rh.fat",
    "rh.fx",
    "rh.ilf",
    "rh.mlf",
    "rh.or",
    "rh.slf1",
    "rh.slf2",
    "rh.slf3",
    "rh.uf"
  ),
  display = c(
    # CC segments
    "corpus callosum rostrum",
    "corpus callosum genu",
    "corpus callosum body central",
    "corpus callosum body prefrontal",
    "corpus callosum body premotor",
    "corpus callosum body parietal",
    "corpus callosum body temporal",
    "corpus callosum splenium",
    # Commissures
    "anterior commissure",
    # Cerebellar
    "middle cerebellar peduncle",
    # Left tracts
    "corticospinal tract",
    "arcuate fasciculus",
    "acoustic radiation",
    "anterior thalamic radiation",
    "cingulum dorsal",
    "cingulum ventral",
    "extreme capsule",
    "frontal aslant tract",
    "fornix",
    "inferior longitudinal fasciculus",
    "middle longitudinal fasciculus",
    "optic radiation",
    "superior longitudinal fasciculus I",
    "superior longitudinal fasciculus II",
    "superior longitudinal fasciculus III",
    "uncinate fasciculus",
    # Right tracts (same names)
    "corticospinal tract",
    "arcuate fasciculus",
    "acoustic radiation",
    "anterior thalamic radiation",
    "cingulum dorsal",
    "cingulum ventral",
    "extreme capsule",
    "frontal aslant tract",
    "fornix",
    "inferior longitudinal fasciculus",
    "middle longitudinal fasciculus",
    "optic radiation",
    "superior longitudinal fasciculus I",
    "superior longitudinal fasciculus II",
    "superior longitudinal fasciculus III",
    "uncinate fasciculus"
  ),
  group = c(
    rep("corpus callosum", 8),
    "commissure",
    "cerebellar",
    rep("projection", 1),
    rep("association", 3),
    rep("limbic", 3),
    rep("association", 2),
    rep("limbic", 1),
    rep("association", 5),
    rep("limbic", 1),
    rep("projection", 1),
    rep("association", 3),
    rep("limbic", 3),
    rep("association", 2),
    rep("limbic", 1),
    rep("association", 5),
    rep("limbic", 1)
  )
)

tracula_metadata$label <- paste0(tracula_metadata$label_short, ".bbr.prep")

tracula_metadata$hemi <- "midline"
tracula_metadata$hemi[grepl("^lh\\.", tracula_metadata$label_short)] <- "left"
tracula_metadata$hemi[grepl("^rh\\.", tracula_metadata$label_short)] <- "right"

tracula_metadata$region <- tracula_metadata$label_short |>
  sub("^(lh|rh)\\.", "", x = _) |>
  gsub("\\.", " ", x = _)

tracula_metadata <- tracula_metadata[,
  c("label", "label_short", "hemi", "region", "display", "group")
]
