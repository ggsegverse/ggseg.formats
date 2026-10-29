# Cross-package gate: one atlas object has to survive the whole chain.
#
# Each package's own R CMD check proves that package works in isolation. None
# of them proves an atlas built against this ggseg.formats still renders in
# both ggseg and ggseg3d, because nothing drives all four in one process. That
# is the gap this script closes, and it is why it asserts region coverage
# rather than merely that a plot object was returned: a renderer that silently
# drops regions returns a perfectly valid object.
#
# Run from the directory holding the checked-out package trees.

suppressPackageStartupMessages({
  library(ggseg.formats)
  library(ggseg.extra)
  library(ggseg)
  library(ggseg3d)
  library(ggplot2)
})

report <- function(...) cat("[ecosystem-smoke]", ..., "\n")

fail <- function(...) {
  report("FAIL:", ...)
  quit(status = 1L)
}

atlas <- dk()
expected <- unique(atlas_labels(atlas))
report("ggseg.formats:", length(expected), "labels in dk()")

# ggseg.extra re-exports the reshaping vocabulary and claims those re-exports
# dispatch to ggseg.formats' single generic. Reaching the verbs through
# ggseg.extra is what tests that claim.
subset_labels <- expected[seq_len(min(6L, length(expected)))]
keep_pattern <- paste0("^(", paste(subset_labels, collapse = "|"), ")$")
reshaped <- ggseg.extra::atlas_region_keep(atlas, pattern = keep_pattern)
kept <- unique(atlas_labels(reshaped))
if (!setequal(kept, subset_labels)) {
  fail(
    "atlas_region_keep() through ggseg.extra kept",
    paste(sort(kept), collapse = ", "),
    "but was asked for",
    paste(sort(subset_labels), collapse = ", ")
  )
}
report("ggseg.extra: reshaped to", length(kept), "labels")

# 2D. Build the plot rather than snapshot it: this runs under CRAN rules,
# where vdiffr skips, and a structural assertion is what survives there.
built <- ggplot_build(ggplot() + geom_brain(atlas = atlas))
if (length(built$data) < 1L || nrow(built$data[[1]]) == 0L) {
  fail("geom_brain() built no data for dk()")
}
drawn_2d <- sum(!is.na(unique(built$data[[1]]$fill)))
if (drawn_2d < 2L) {
  fail("geom_brain() drew", drawn_2d, "distinct fills; the atlas has regions")
}
report("ggseg:", nrow(built$data[[1]]), "rows,", drawn_2d, "distinct fills")

widget <- ggseg3d(atlas = atlas)
if (!inherits(widget, "htmlwidget")) {
  fail("ggseg3d() returned", paste(class(widget), collapse = "/"))
}
mesh_colours <- unlist(lapply(widget$x$meshes, function(mesh) unique(mesh$colors)))
drawn_3d <- length(unique(mesh_colours))
if (drawn_3d < 2L) {
  fail("ggseg3d() painted", drawn_3d, "colours; the atlas has regions")
}
report("ggseg3d:", length(widget$x$meshes), "meshes,", drawn_3d, "distinct colours")

# The invariant worth gating. Both renderers resolve colour through
# ggseg.formats::atlas_plot_palette(), so for one atlas they must paint the
# same number of distinct colours. A renderer that silently drops regions
# still returns a valid object and still passes its own package's checks; it
# fails here. This is the only assertion in the ecosystem that compares the
# two backends against each other rather than each against itself.
if (drawn_2d != drawn_3d) {
  fail(
    "renderers disagree on how many regions dk() has:",
    "ggseg painted", drawn_2d, "distinct fills,",
    "ggseg3d painted", drawn_3d, "distinct colours"
  )
}

report("OK:", drawn_2d, "regions painted identically by both renderers")
