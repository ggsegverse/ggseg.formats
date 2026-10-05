# Create the TRACULA white-matter tract atlas for the ggseg ecosystem
#
# TRACULA (TRActs Constrained by UnderLying Anatomy) ships 42 major bundles as
# tractography streamlines in MNI space. Each is reduced to a mean centerline
# and built into a proper tract atlas (type = "tract") with
# create_tract_from_tractography(): a 3D tube per tract, and a 2D projection
# over the grey anatomical silhouette that input_aseg supplies.
#
# The streamlines and the aparc+aseg reference are distributed together in the
# same trctrain directory and so already share a space; no registration step is
# needed, unlike the volumetric tract atlases.
#
# Source: FreeSurfer trctrain data, distributed with FreeSurfer in
#   $FREESURFER_HOME/trctrain/
#   (https://surfer.nmr.mgh.harvard.edu/fswiki/Tracula).
# Reference: Yendiki A, et al. (2011). "Automated probabilistic reconstruction
#   of white-matter pathways in health and disease using an atlas of the
#   underlying anatomy." Frontiers in Neuroinformatics, 5:23.
#   <doi:10.3389/fninf.2011.00023>
#
# Requires: ggseg.extra, RNifti, FreeSurfer 7.4.1 with trctrain data.
#
# Run with: source("data-raw/make_tracula_atlas.R")
#
# Set TRACULA_REBUILD to any non-empty value to discard the cached projection
# artefacts. Step 1 (streamline reading and tube meshes) is slab-independent
# and always reused; everything downstream of it depends on `tract_slabs`, so
# changing a slab position without clearing the cache silently reuses the old
# geometry.

library(dplyr)
library(ggseg.extra) # nolint
devtools::load_all()

source("data-raw/tracula_metadata.R")

options(freesurfer.verbose = FALSE)
future::plan(future::multisession(workers = 4))
progressr::handlers("cli")
progressr::handlers(global = TRUE)

fs_dir <- freesurfer::fs_dir()
tract_dir <- file.path(fs_dir, "trctrain", "hcp", "mgh_1017", "mni")

if (!dir.exists(tract_dir)) {
  cli::cli_abort(c(
    "TRACULA training data not found",
    "i" = "Expected {.path {tract_dir}}; needs FreeSurfer trctrain data"
  ))
}

tract_files <- list.files(tract_dir, pattern = "\\.trk$", full.names = TRUE)
aseg_file <- file.path(tract_dir, "aparc+aseg.nii.gz")

if (!file.exists(aseg_file)) {
  cli::cli_abort(c(
    "aparc+aseg.nii.gz not found",
    "i" = "Expected: {.path {aseg_file}}; needed for the 2D cortex outlines"
  ))
}

# ── Tract colour table ───────────────────────────────────────────────────
# FreeSurfer gives the TRACULA pathways their own colours in
# FreeSurferColorLUT.txt, at ids 5100-5399, so there is nothing here to
# invent: these are the colours the same bundles are drawn in by freeview and
# throughout the FreeSurfer documentation, and matching them is worth more
# than any palette we could generate.
#
# The scheme already pairs bilaterally -- lh.af and rh.af are both
# 153 255 255 -- which is the right call, since the two sides of a bundle are
# the same anatomy. It also gives the callosal segments only four colours
# between the eight of them (cc.genu shares with cc.bodyp, cc.rostrum with
# cc.splenium, and so on). That loses a distinction, but they are adjacent
# parts of one structure and FreeSurfer's own rendering has the same
# collisions, so consistency wins.
#
# Colours are matched to tracts by position, so the table is ordered to match
# tract_files. The match is asserted rather than assumed: an unmatched tract
# would otherwise fall back to a generated colour without saying so.
lut_all <- read_lut(file.path(fs_dir, "FreeSurferColorLUT.txt"))
tract_keys <- sub("\\.bbr\\.prep\\.trk$", "", basename(tract_files))
tract_lut <- lut_all[match(tract_keys, lut_all$label), ]
stopifnot(
  "every TRACULA tract must have a FreeSurfer LUT entry" = !anyNA(tract_lut$idx)
)
cli::cli_alert_info(
  "Tracts: {nrow(tract_lut)} in {length(unique(tract_lut$idx))} LUT entries, \\
   {length(unique(paste(tract_lut$R, tract_lut$G, tract_lut$B)))} colours"
)

# ── Projection slabs at fixed anatomical positions ───────────────────────
# Slice positions are given in RAS millimetres so they are anatomically
# meaningful and independent of the template's voxel grid, and each slab spans
# +/- slab_halfwidth slices around its midpoint.
#
# These are ggsegAtlasTrack's positions, unchanged. Both atlases are drawing
# the same thing -- major white-matter bundles over a whole-brain silhouette --
# and the cuts that work there work here: the superior axial crosses the SLF
# branches and the callosal body, the middle one the thalamic radiations and
# the forceps, the inferior one the uncinate, ILF and extreme capsule; the
# coronal catches the corticospinal tract and fornix at the internal capsule;
# and the sagittal sits just off midline, near enough to carry the callosal
# arch and cingulum but still cutting the association bundles along their
# length rather than across it.
#
# One sagittal cut, not three, and it must not sit on the midline. A midline
# cut looks like the obvious home for the eight callosal segments, but it is
# the one plane where they cannot win: it holds their thin arch cross-section,
# while mid_axial catches the forceps fanning out laterally and covers several
# times the area. Cut at x = 0 the panel came out with two regions in it, and
# narrowing the slab so it reads as a single-hemisphere view and earns
# atlas_view_select()'s weighting did not rescue it. At -12 mm it is off
# midline enough to be a bundle plane in its own right -- cingulum, fornix and
# the association bundles along their length -- while still crossing the
# callosal body, and it ends up among the best-populated panels. Mirroring it
# adds nothing: a left/right pair of sagittal panels draws the same bundles
# twice, since atlas_view_select() keeps bilateral regions together rather
# than splitting them across panels.
slab_halfwidth <- 8L
slice_mm <- data.frame(
  name = c(
    "superior_axial",
    "mid_axial",
    "inferior_axial",
    "coronal",
    "sagittal"
  ),
  type = c("axial", "axial", "axial", "coronal", "sagittal"),
  mm = c(17, 2, -11, -17, -12),
  stringsAsFactors = FALSE
)

# RAS millimetres -> index along the corresponding axis of the RAS+ reoriented
# volume. Derived from the template's own affine rather than hard-coded, so it
# stays correct if the reference volume changes.
ras_mm_to_index <- function(vox2ras, dims, ras_axis, mm) {
  native_axis <- which.max(abs(vox2ras[ras_axis, 1:3]))
  scale <- vox2ras[ras_axis, native_axis]
  native <- (mm - vox2ras[ras_axis, 4]) / scale
  index <- if (scale > 0) native else dims[native_axis] - 1 - native
  as.integer(round(index)) + 1L
}

aseg_img <- RNifti::readNifti(aseg_file, internal = TRUE)
aseg_vox2ras <- RNifti::xform(aseg_img)
aseg_dims <- dim(aseg_img)
ras_axis <- c(axial = 3L, coronal = 2L, sagittal = 1L)

slice_mm$mid <- mapply(
  function(type, mm) {
    ras_mm_to_index(aseg_vox2ras, aseg_dims, ras_axis[[type]], mm)
  },
  slice_mm$type,
  slice_mm$mm
)

tract_slabs <- data.frame(
  name = slice_mm$name,
  type = slice_mm$type,
  start = slice_mm$mid - slab_halfwidth,
  end = slice_mm$mid + slab_halfwidth,
  stringsAsFactors = FALSE
)
print(tract_slabs)

# ── Fit a centerline per tract and build the tract atlas ─────────────────
cli::cli_h1("Fitting tract centerlines")

# Everything from the projection step onward is slab-dependent. Step 1 is not,
# and is by far the slowest part, so it survives a rebuild.
rebuild <- !identical(Sys.getenv("TRACULA_REBUILD", ""), "")
if (rebuild) {
  cache <- file.path("data-raw", "tracula")
  keep <- file.path(cache, "step1_data.rds")
  stale <- setdiff(
    list.files(cache, full.names = TRUE, include.dirs = TRUE),
    keep
  )
  unlink(stale, recursive = TRUE)
}

tracula_raw <- create_tract_from_tractography(
  input_tracts = tract_files,
  input_aseg = aseg_file,
  input_lut = tract_lut,
  atlas_name = "tracula",
  output_dir = "data-raw",
  slabs = tract_slabs,
  tube_radius = 3,
  tube_segments = 6,
  n_points = 100,
  cleanup = FALSE,
  skip_existing = !rebuild,
  verbose = TRUE
)

stopifnot(
  "tracula must be a tract atlas" = is_tract_atlas(tracula_raw)
)

# ── Name and group the tracts ────────────────────────────────────────────
# The pipeline derives hemi and region mechanically from the .trk filenames.
# tracula_metadata.R carries the spelled-out names and the anatomical grouping
# those filenames cannot supply.
cli::cli_h2("Post-processing atlas")

# `label` is canonically the .bbr.prep form FreeSurfer emits, which is what
# users join their own TRACULA tables on. Depending on how much of the
# filename the reader strips, the raw labels may arrive in the short LUT form
# instead; relabelling to the canonical form is a no-op when they do not.
tracula_raw <- relabel_atlas(
  tracula_raw,
  setNames(tracula_metadata$label, tracula_metadata$label_short)
)

core_with_meta <- tracula_raw$core |>
  rename(region_raw = region) |>
  left_join(
    select(tracula_metadata, label, label_short, region, names, group),
    by = "label"
  ) |>
  mutate(region = coalesce(region, region_raw)) |>
  select(hemi, region, label, label_short, names, group)

n_with_group <- sum(!is.na(core_with_meta$group))
n_total <- nrow(core_with_meta)
cli::cli_alert_info(
  "Tracts with group info: {n_with_group}/{n_total}"
)

tracula <- ggseg_atlas(
  atlas = "tracula",
  type = "tract",
  palette = tracula_raw$palette,
  core = core_with_meta,
  data = tracula_raw$data
)

# Cache the unsmoothed atlas so smoothing can be retuned without rebuilding.
saveRDS(tracula, file.path("data-raw", "tracula_unsmoothed.rds"))

# ── Smooth and simplify ──────────────────────────────────────────────────
# Post-hoc, so retuning never means rerunning the pipeline. Smooth first, then
# simplify: smoothing interpolates vertices, so simplifying first would just
# have its saving undone.
#
# Projection leaves stray specks detached from their tract; those are dropped
# first, since smoothing them would only make them tidier. The cortex is
# spared: a thin ribbon's gyral cross-sections are legitimately small pieces,
# not specks, and removing them strips its detail.
#
# The two structures want different smoothing. Tracts are solid centerline
# tubes with no holes to lose, so morphological closing rounds them freely.
# The cortex is a thin ribbon whose sulci are enclosed holes, and closing
# fills any hole narrower than the smoothing distance -- so it gets
# "ksmooth", which low-pass filters the outline without dilating it. Chaikin
# also preserves holes but converges after two refinements, so it cannot be
# pushed as far.
cli::cli_alert_info("Cleaning up geometries")

tracula <- tracula |>
  atlas_view_remove_small(
    min_area = 20,
    scope = "piece",
    exclude = "^cortex"
  ) |>
  atlas_smooth(
    keep = 1,
    smoothness = 0.8,
    method = "close",
    exclude = "^cortex"
  ) |>
  atlas_smooth(
    keep = 1,
    smoothness = 0.6,
    method = "ksmooth",
    labels = "^cortex"
  ) |>
  atlas_smooth(keep = 0.2, labels = "^cortex") |>
  atlas_smooth(keep = 0.2, exclude = "^cortex")

# The cortex silhouette carries ~90% of the atlas's vertices -- it is a
# convoluted ribbon drawn across every view, against 42 smooth tubes -- so its
# `keep` sets the shipped size almost single-handedly. 0.2 is where the gyral
# detail stops changing visibly: it is indistinguishable from 0.4 at any
# plotting size while halving the atlas, and unlike 0.1 it still holds up
# zoomed in.

# ── Choose which tracts each view draws ──────────────────────────────────
# A slab catches a passing tract in cross-section as readily as along its
# length, so most tracts leave a sliver in most views -- which leaves every
# panel cluttered and every tract drawn several times over. A tract is kept
# only where it is substantially represented: in any view holding at least
# `threshold` of the area it reaches in its best view.
#
# This replaces the hand-curated per-view removals earlier releases carried:
# nine region/view pairs named one at a time, tuned against a single build and
# silently wrong after any reslice. atlas_view_select() compares per region
# rather than per label, so left and right stay together -- splitting a pair
# across panels reads as an error rather than a choice -- and weights
# single-hemisphere views so a sagittal panel is not beaten on raw area by the
# axial and coronal panels that show both hemispheres.
tracula <- atlas_view_select(tracula, threshold = 0.7)

# Ordering repositions the panels, so it runs last: atlas_view_select() drops
# regions from views and changes each panel's extent, and packing against the
# final extents is what keeps the gaps even. Panels then read superior ->
# inferior, then the other planes.
tracula <- atlas_view_reorder(tracula, slice_mm$name)

plot(tracula)

cli::cli_alert_success("tracula: {nrow(tracula$core)} tracts")
print(tracula)

cat("\nGroup distribution:\n")
print(table(tracula$core$group, useNA = "ifany"))

# ── Save ─────────────────────────────────────────────────────────────────
# make_sysdata.R folds data/tracula.rda into R/sysdata.rda, where the bundled
# atlases live, and clears data/ afterwards.
usethis::use_data(tracula, overwrite = TRUE, compress = "xz")
cli::cli_alert_success("Saved to data/tracula.rda")
