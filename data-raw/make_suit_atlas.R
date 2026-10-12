# Add the SUIT cerebellar atlas to R/sysdata.rda
#
# Imports the built SUIT cerebellar atlas from the ggsegSUIT package and stores
# it in the sf-optional polygon (`geom`) format, giving ggseg.formats one
# bundled atlas of each kind (cortical = dk, subcortical = aseg, tract =
# tracula, cerebellar = suit).
#
# Prerequisites:
#   - ggsegSUIT checked out alongside ggseg.formats (../atlases/ggsegSUIT),
#     with its built atlas in R/sysdata.rda (object `.suit`).
#   - The existing ggseg.formats R/sysdata.rda (meshes + dk/aseg/tracula).
#   - sf installed (the import converts the SUIT sf geometry to polygons once).
#
# Run with: source("data-raw/make_suit_atlas.R")

devtools::load_all()

suit_src <- "../atlases/ggsegSUIT/R/sysdata.rda"
if (!file.exists(suit_src)) {
  cli::cli_abort(c(
    "ggsegSUIT sysdata not found at {.path {suit_src}}.",
    "i" = "Clone ggsegSUIT into {.path ../atlases/ggsegSUIT}."
  ))
}

# Existing internal data (meshes + the three current atlases).
sys_env <- new.env()
load("R/sysdata.rda", envir = sys_env)
brain_mesh_inflated <- sys_env$brain_mesh_inflated
cerebellar_mesh_suit <- sys_env$cerebellar_mesh_suit
.dk_atlas <- sys_env$.dk_atlas
.aseg_atlas <- sys_env$.aseg_atlas
.tracula_atlas <- sys_env$.tracula_atlas

# Import the SUIT atlas and store it in the polygon (sf-optional) geom format.
suit_env <- new.env()
load(suit_src, envir = suit_env)
.suit_atlas <- as_polygon_atlas(suit_env$.suit)

# ggsegSUIT ships the parcel keys only, so the long-form `display` column
# comes from suit_metadata.R.
source("data-raw/suit_metadata.R")
hit <- match(.suit_atlas$core$region, suit_metadata$region)
stopifnot("every SUIT region must have a metadata row" = !anyNA(hit))
.suit_atlas$core$display <- suit_metadata$display[hit]
.suit_atlas$core <- .suit_atlas$core[,
  c("hemi", "region", "label", "display")
]

# ggsegSUIT marks the vermis as a hemisphere of its own. `hemi` carries only
# left/right/midline/NA, and the vermis is the cerebellar midline, so it is
# recorded as such. The labels keep the upstream `vermis_` spelling because
# they are the join key.
.suit_atlas$core$hemi[.suit_atlas$core$hemi == "vermis"] <- "midline"

usethis::use_data(
  brain_mesh_inflated,
  cerebellar_mesh_suit,
  .dk_atlas,
  .aseg_atlas,
  .tracula_atlas,
  .suit_atlas,
  internal = TRUE,
  overwrite = TRUE,
  compress = "xz"
)

cli::cli_alert_success("Added {.val .suit_atlas} to R/sysdata.rda.")
