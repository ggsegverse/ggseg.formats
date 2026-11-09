# Create ASEG (Automatic Subcortical Segmentation) Atlas
#
# Generates the aseg subcortical atlas using ggseg.extra from FreeSurfer's
# aseg.mgz volume on fsaverage5.
#
# Uses projection-based 2D views (6 views) to show subcortical structures
# in their spatial relationships with reduced overlap.
#
# Requirements:
#   - FreeSurfer installed with fsaverage5 subject
#   - ggseg.extra package
#   - Chrome/Chromium for snapshots
#
# Run with: source("data-raw/make_aseg_atlas.R")

library(dplyr)
library(ggseg.extra) # nolint
devtools::load_all()
options(freesurfer.verbose = FALSE)
future::plan(future::multicore())
progressr::handlers("cli")
progressr::handlers(global = TRUE)

# Load metadata
source("data-raw/aseg_metadata.R")

# Setup paths
fs_dir <- freesurfer::fs_dir()
subjects_dir <- file.path(fs_dir, "subjects")

aseg_volume <- file.path(subjects_dir, "fsaverage5", "mri", "aseg.mgz")
color_lut <- file.path(fs_dir, "ASegStatsLUT.txt")

# Verify files exist
if (!file.exists(aseg_volume)) {
  cli::cli_abort("aseg.mgz not found at {.path {aseg_volume}}")
}
if (!file.exists(color_lut)) {
  color_lut <- file.path(fs_dir, "FreeSurferColorLUT.txt")
}

# FreeSurfer ships no `context` column, so nothing in a stock lookup table is
# backdrop and the atlas would arrive with no silhouette to draw its structures
# against. The two cerebral cortex labels are traced as one `cortex` ribbon;
# cerebellum cortex stays a region, and white matter is deliberately left out
# -- drawn as context it fills the sulci and turns the ribbon into a blob.
aseg_lut <- read_lut(color_lut)
aseg_lut$context <- ifelse(
  grepl("Cerebral-Cortex$", aseg_lut$label),
  "cortex",
  NA_character_
)

# Display names and hemispheres ride in on the lookup table so the pipeline
# derives `region` from them, rather than core being rewritten afterwards.
# The column must be `display`: that is the one the pipeline reads, and a
# lookup table carrying the curated names under any other name is silently
# ignored in favour of the source's own label.
meta_row <- match(aseg_lut$label, aseg_metadata$label)
aseg_lut$display <- aseg_metadata$display[meta_row]
aseg_lut$hemi <- aseg_metadata$hemi[meta_row]

# Labels dropped after the build, listed once.
drop_patterns <- c(
  "White-Matter",
  "WM-hypointensities",
  "-Ventricle",
  "-Vent$",
  "CSF"
)

# Create atlas using ggseg.extra with projection-based views: three coronal,
# three axial and one sagittal slab over the subcortical range.
aseg_raw <- create_subcortical_from_volume(
  input_volume = aseg_volume,
  input_lut = aseg_lut,
  atlas_name = "aseg",
  output_dir = "data-raw/",
  skip_existing = FALSE,
  cleanup = FALSE
)

cli::cli_h2("Post-processing atlas")

cli::cli_alert_info("Remove unwanted regions")
aseg_raw_simple <- Reduce(
  function(atlas, pattern) {
    atlas_region_remove(atlas, pattern, match_on = "label")
  },
  drop_patterns,
  init = aseg_raw
) |>
  atlas_prune_region(
    pattern = "cerebellum",
    match_on = "label",
    views = "coronal"
  )

# Tiling the label bounding box puts slabs where the structures are not: the
# most superior axial and the most anterior coronal come back carrying a
# handful of regions against a full backdrop. Drop them by counting what each
# view actually holds, rather than by naming the views, because a name that
# stops existing is a silent no-op.
counts <- atlas_view_region_counts(aseg_raw_simple)
cli::cli_alert_info(
  "Views by region count: {paste0(names(counts), '=', as.integer(counts))}"
)

# A view earns a panel by showing at least half the structures. Below that it
# repeats what the denser views already show: of the two this drops, one is
# the best view of no structure at all, and the other only of the right
# cerebellar cortex, which the kept axial still shows at 61% of that size.
# Expressed as a share rather than a count so it cannot silently stop
# discriminating when the atlas gains or loses regions.
drawn_labels <- setdiff(
  atlas_labels(aseg_raw_simple),
  atlas_context(aseg_raw_simple)
)
aseg_raw_simple <- atlas_view_remove_sparse(
  aseg_raw_simple,
  min_regions = ceiling(length(drawn_labels) / 2)
)

cli::cli_alert_info("Gathering views")
aseg_raw_simple <- atlas_view_gather(aseg_raw_simple)

# Smooth the voxel-stepped 2D contours. Geometry shaping is not part of atlas
# creation, so the polygons arrive stepped and are tidied here.
#
# `smoothness` counts voxels, and the close is what welds the traced ribbon
# into a mantle, so the value decides whether there is a cortex left: at 1 the
# gyri fuse and the silhouette inflates into a blob, while 0.4 keeps the
# sulcal notches and the interhemispheric fissure open. Raise it and the
# ribbon goes.
cli::cli_alert_info("Smoothing contours")
aseg_raw_smooth <- aseg_raw_simple |>
  atlas_smooth(smoothness = 0.6, exclude = "^cortex") |>
  atlas_polish(keep = 0.3, smoothness = 0.4, labels = "^cortex")


cli::cli_h2("Merging metadata")

# `structure` is the one column the lookup table cannot carry, so it is the
# only thing joined onto the finished core.
aseg <- atlas_core_add(
  aseg_raw_smooth,
  select(aseg_metadata, label, structure),
  by = "label"
)

has_structure <- aseg_metadata$label[!is.na(aseg_metadata$structure)]
n_with_structure <- sum(atlas_labels(aseg) %in% has_structure)
n_total <- length(atlas_labels(aseg))
cli::cli_alert_info(
  "Regions with structure info: {n_with_structure}/{n_total}"
)

cli::cli_alert_success("ASEG atlas created with {n_total} regions")
print(aseg)

# Preview
atlas_labels(aseg)

plot(aseg)

# Save
usethis::use_data(aseg, overwrite = TRUE, compress = "xz")
cli::cli_alert_success("Saved to data/aseg.rda")
