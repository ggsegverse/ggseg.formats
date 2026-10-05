# Reapply the metadata tables in data-raw/*_metadata.R to the bundled atlases
# inside R/sysdata.rda.
#
# The metadata tables are the source of truth for `region`, `names`,
# `label_short` and the grouping column of each bundled atlas, but they are
# merged in by the make_*_atlas.R pipelines, which rebuild the geometry from
# scratch and need FreeSurfer, a fsaverage5 subject and a headless browser.
# Correcting a metadata column should not require any of that, so this
# refreshes the metadata in place and leaves the geometry untouched -- the same
# arrangement as refresh_sysdata_polygons.R.
#
# Prerequisite: R/sysdata.rda with the four bundled atlases in it.
#
# Safe to re-run. Run with: source("data-raw/refresh_sysdata_metadata.R")

devtools::load_all()

source("data-raw/dk_metadata.R")
source("data-raw/aseg_metadata.R")
source("data-raw/tracula_metadata.R")
source("data-raw/suit_metadata.R")

env <- new.env(parent = emptyenv())
load("R/sysdata.rda", envir = env)

apply_metadata <- function(
  atlas,
  metadata,
  core_key,
  meta_key,
  extra = character()
) {
  core <- atlas$core
  cols <- intersect(c("region", "names", "label_short", extra), names(metadata))
  hit <- match(core[[core_key]], metadata[[meta_key]])
  if (anyNA(hit)) {
    cli::cli_abort(
      "No metadata row for {.val {core[[core_key]][is.na(hit)]}}."
    )
  }
  for (col in cols) {
    core[[col]] <- metadata[[col]][hit]
  }
  ordered <- c(
    intersect(
      c("hemi", "region", "label", "label_short", "names"),
      names(core)
    ),
    setdiff(names(core), c("hemi", "region", "label", "label_short", "names"))
  )
  atlas$core <- core[, ordered, drop = FALSE]
  atlas
}

env$.dk_atlas <- apply_metadata(
  env$.dk_atlas,
  dk_metadata,
  core_key = "region",
  meta_key = "label",
  extra = "lobe"
)

env$.aseg_atlas <- apply_metadata(
  env$.aseg_atlas,
  aseg_metadata,
  core_key = "label",
  meta_key = "label",
  extra = "structure"
)

# TRACULA is keyed on the .bbr.prep name FreeSurfer emits, so the shipped
# labels are re-keyed from the short LUT form before the metadata is merged.
env$.tracula_atlas <- relabel_atlas(
  env$.tracula_atlas,
  stats::setNames(tracula_metadata$label, tracula_metadata$label_short)
)
env$.tracula_atlas <- apply_metadata(
  env$.tracula_atlas,
  tracula_metadata,
  core_key = "label",
  meta_key = "label",
  extra = "group"
)

env$.suit_atlas <- apply_metadata(
  env$.suit_atlas,
  suit_metadata,
  core_key = "region",
  meta_key = "region"
)

for (nm in c(".dk_atlas", ".aseg_atlas", ".tracula_atlas", ".suit_atlas")) {
  stopifnot(is_ggseg_atlas(env[[nm]]))
}

save(
  list = ls(env, all.names = TRUE),
  file = "R/sysdata.rda",
  envir = env,
  compress = "xz",
  version = 2
)

cli::cli_alert_success("Reapplied metadata to the four bundled atlases.")
