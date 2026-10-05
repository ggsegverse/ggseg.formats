# SUIT cerebellar atlas metadata
#
# One row per SUIT parcel, keyed on the parcel name the atlas uses as its
# hemisphere-free `region`. `label` is built from `hemi` and `region` by the
# atlas itself, so only `region` is matched on here.
#
# `names` holds the long-form display name, spelled out from the Diedrichsen
# SUIT nomenclature (lobules I-X plus Crus I/II for the cerebellar cortex, and
# the dentate, interposed and fastigial deep nuclei). The SUIT release ships no
# machine-readable lookup table of long names alongside the parcellation, so
# these are written out here rather than imported. `region` is unchanged from
# the CRAN 0.0.4 release, so nothing has to be recovered through `names`.
#
# Based on: https://github.com/DiedrichsenLab/cerebellar_atlases

suit_metadata <- data.frame(
  region = c(
    "I_IV",
    "V",
    "VI",
    "CrusI",
    "CrusII",
    "VIIb",
    "VIIIa",
    "VIIIb",
    "IX",
    "X",
    "Dentate",
    "Interposed",
    "Fastigial"
  ),
  names = c(
    "lobules I-IV",
    "lobule V",
    "lobule VI",
    "Crus I",
    "Crus II",
    "lobule VIIb",
    "lobule VIIIa",
    "lobule VIIIb",
    "lobule IX",
    "lobule X",
    "dentate nucleus",
    "interposed nucleus",
    "fastigial nucleus"
  )
)
