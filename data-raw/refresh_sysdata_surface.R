# Record on the bundled cerebellar atlas which reference surface its vertex
# indices address.
#
# `atlas_surface()` reads an unrecorded cerebellar surface back as SUIT, so
# nothing is broken without this, but the bundled atlas should state the
# surface rather than lean on that fallback -- it is the example every other
# atlas is read against.
#
# This refreshes R/sysdata.rda in place rather than re-running the build.
# That is the only option for `.suit_atlas`: make_suit_atlas.R imports it from
# ggsegSUIT, which is not checked out alongside this package. Safe to re-run.
#
# Run with: source("data-raw/refresh_sysdata_surface.R")

devtools::load_all()

env <- new.env(parent = emptyenv())
load("R/sysdata.rda", envir = env)

report <- function(when) {
  recorded <- env$.suit_atlas$data$surface %||% NA # nolint: object_usage_linter
  cli::cli_alert_info("{when}: surface {.val {recorded}}")
}

report("before")

if (is.null(env$.suit_atlas$data$surface)) {
  env$.suit_atlas$data$surface <- "suit"
}

report("after")

stopifnot(
  identical(env$.suit_atlas$data$surface, "suit"),
  identical(atlas_surface(env$.suit_atlas), "suit"),
  is.null(atlas_surface(env$.aseg_atlas)),
  is.null(atlas_surface(env$.tracula_atlas))
)

save(
  list = ls(env, all.names = TRUE),
  file = "R/sysdata.rda",
  envir = env,
  compress = "xz",
  version = 2
)

cli::cli_alert_success(
  "Recorded the reference surface in {.file R/sysdata.rda}."
)
