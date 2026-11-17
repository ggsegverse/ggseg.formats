# Build the bundled inflated cortical meshes from their actual source.
#
# The previous version of this script read ggseg3d's R/sysdata.rda and copied
# brain_meshes out of it. That file no longer exists -- ggseg3d's sysdata went
# in the refactor -- so the script could not run, and the recorded provenance
# of the bundled meshes pointed at a deleted artefact. It also still wrote
# brain_pals, which is no longer in sysdata at all. This reads FreeSurfer's
# fsaverage5 surfaces instead, which is where the geometry came from in the
# first place.
#
# The geometry is asserted to be unchanged rather than assumed to be. Cortical
# vertex indices are what every atlas keys its regions to, so a rebuild that
# reordered or moved a vertex would relocate every region on every atlas while
# still rendering a perfectly convincing brain. If this script ever produces
# different geometry, that is a finding, not something to accept.
#
# Run with: source("data-raw/make_brain_mesh_inflated.R")

library(ggseg.formats)

fs_home <- Sys.getenv("FREESURFER_HOME")
if (!nzchar(fs_home)) {
  cli::cli_abort("{.envvar FREESURFER_HOME} is not set.")
}

surf_dir <- file.path(fs_home, "subjects", "fsaverage5", "surf")
if (!dir.exists(surf_dir)) {
  cli::cli_abort("No fsaverage5 surfaces at {.path {surf_dir}}.")
}

fs_version <- local({
  stamp <- file.path(fs_home, "build-stamp.txt")
  if (file.exists(stamp)) readLines(stamp, n = 1L) else "unknown"
})

hemi_names <- c(lh = "left", rh = "right")

read_inflated <- function(hemi) {
  path <- file.path(surf_dir, paste0(hemi, ".inflated"))
  surf <- freesurferformats::read.fs.surface(path) # nolint: object_usage_linter

  # Inflation moves every vertex, so an inflated surface has no anatomical
  # position: anatomical = FALSE, and no affine to MNI305. It is also why each
  # hemisphere arrives centred on the origin and the two would superimpose if
  # drawn as they are -- separating them is the renderer's display decision,
  # which is why no offset is recorded here.
  #
  # brain_mesh() checks the faces actually count from the base declared, so
  # the 1-based-to-0-based conversion below cannot silently go wrong.
  # nolint start: object_usage_linter.
  # lintr cannot resolve this package's own exports from data-raw, even with
  # library() above.
  brain_mesh(
    vertices = data.frame(
      x = surf$vertices[, 1],
      y = surf$vertices[, 2],
      z = surf$vertices[, 3]
    ),
    # read.fs.surface() returns 1-based faces; the bundled meshes are 0-based
    # and documented as such in get_brain_mesh(), so consumers rely on it.
    faces = data.frame(
      i = surf$faces[, 1] - 1L,
      j = surf$faces[, 2] - 1L,
      k = surf$faces[, 3] - 1L
    ),
    space = mesh_space(
      vertex_space = "fsaverage5",
      hemi = hemi_names[[hemi]],
      anatomical = FALSE,
      surface = "inflated",
      source = paste(fs_version, "fsaverage5", paste0(hemi, ".inflated"))
    ),
    face_index_base = 0L
  )
  # nolint end
}

brain_mesh_inflated <- list(
  lh = read_inflated("lh"),
  rh = read_inflated("rh")
)

# Geometry must be identical to what is already bundled, which is the
# committed sysdata: re-running with a FreeSurfer whose fsaverage5 differed
# would fail here rather than quietly replace the geometry every atlas
# indexes. Note this compares against the sysdata as it stands on disk, so
# the baseline is whatever is committed -- the guard catches a changed
# source, not a geometry change already committed in a previous run.
for (hemi in names(brain_mesh_inflated)) {
  built <- brain_mesh_inflated[[hemi]]
  bundled <- get_brain_mesh(hemi, "inflated")

  stopifnot(
    identical(nrow(built$vertices), nrow(bundled$vertices)),
    identical(nrow(built$faces), nrow(bundled$faces)),
    isTRUE(all.equal(built$vertices, bundled$vertices, tolerance = 1e-6)),
    identical(
      as.matrix(built$faces),
      as.matrix(bundled$faces)
    )
  )
  cli::cli_alert_success(
    "{hemi}: {nrow(built$vertices)} vertices, {nrow(built$faces)} faces,
     identical to the bundled mesh"
  )
}

# Everything else in sysdata is carried through untouched, read back by name
# rather than listed here. sysdata holds the bundled atlases as DOT-PREFIXED
# objects (.dk_atlas, .aseg_atlas, ...), which `ls()` hides unless you ask for
# `all.names = TRUE`; a hand-written list of what to save therefore silently
# dropped every atlas and left a package that could not build.
existing <- new.env()
load("R/sysdata.rda", envir = existing)

keep <- setdiff(ls(existing, all.names = TRUE), "brain_mesh_inflated")
for (nm in keep) {
  assign(nm, get(nm, envir = existing))
}

to_save <- c("brain_mesh_inflated", keep)
cli::cli_alert_info("Saving {length(to_save)} objects: {.val {to_save}}")

do.call(
  usethis::use_data,
  c(
    lapply(to_save, as.name),
    list(internal = TRUE, overwrite = TRUE, compress = "xz")
  )
)

# The count must not shrink. Rewriting sysdata from a partial list is how the
# atlases were lost once already.
reloaded <- new.env()
load("R/sysdata.rda", envir = reloaded)
stopifnot(
  setequal(
    ls(reloaded, all.names = TRUE),
    ls(existing, all.names = TRUE)
  )
)

cli::cli_alert_success(
  "Wrote R/sysdata.rda with all
   {length(ls(reloaded, all.names = TRUE))} objects intact"
)
