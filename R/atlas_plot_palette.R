context_fill_colour <- "#CCCCCC"

# Labels the atlas pipelines generate for anatomical backdrop rather than for a
# parcel. Matched case-insensitively, with or without a hemisphere prefix.
context_label_pattern <- paste0(
  "^(lh|rh)[_-](unknown|background|medial[_-]?wall)$",
  "|^(unknown|background|medial[_-]?wall)$",
  "|^cortex([_-]|$)"
)

#' Get a plottable palette for an atlas
#'
#' Returns the atlas `palette` when it can tell the atlas's regions apart, and
#' otherwise a palette of automatically assigned, distinguishable colours. Use
#' this instead of reading `atlas$palette` directly whenever the palette is
#' about to be drawn: some atlases are built from colour lookup tables that give
#' every region the same colour (often black), and rendering those faithfully
#' produces a solid silhouette in which no region can be told from its
#' neighbours.
#'
#' A palette is treated as unusable when every one of the atlas's regions
#' resolves to a single colour. Contextual geometry -- the `cortex_` silhouette
#' and the `unknown` medial wall -- is excluded from that judgement and keeps
#' its conventional grey in the fallback, so backdrop is never mistaken for a
#' parcel. Atlases with a single region, and palettes that are merely dark but
#' varied, are left untouched: this replaces palettes that cannot be read, not
#' palettes that are unusual.
#'
#' Falling back warns, naming the atlas, because the fix belongs in the atlas's
#' colour lookup table. An atlas carrying no palette at all is a supported,
#' expected state rather than a broken table, so it falls back silently.
#'
#' @inheritParams atlas_palette
#' @return Named character vector of colours keyed by label.
#' @seealso [atlas_palette()] for the palette exactly as stored.
#' @export
#' @examples
#' # A well-formed palette comes back untouched
#' identical(atlas_plot_palette(dk()), atlas_palette(dk()))
atlas_plot_palette <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }

  plot_labels <- plot_palette_labels(atlas)
  stored <- atlas$palette

  if (palette_is_usable(stored, plot_labels, atlas$core$label)) {
    return(stored)
  }

  if (!is.null(stored) && length(stored) > 0L) {
    cli::cli_warn(c(
      "Atlas {.val {atlas$atlas}} has no usable colour palette.",
      "i" = "Every region is the same colour, so no region can be told from
             its neighbours; falling back to automatically assigned colours.",
      "!" = "Fix the atlas colour lookup table to give each region its
             own colour."
    ))
  }

  fallback_palette(plot_labels, atlas$core$label)
}


#' Is a label contextual geometry rather than an atlas region?
#'
#' Context is geometry drawn as anatomical backdrop -- the cortical silhouette a
#' subcortical slice sits on, or the medial wall -- rather than a parcel of the
#' atlas. A label is contextual when it is absent from `core_labels`, or when it
#' carries one of the names the atlas pipelines reserve for backdrop geometry
#' (`cortex_*`, `unknown`, `Background`, `medial_wall`, with or without a
#' hemisphere prefix). The name-based half matters because some atlases keep
#' their medial wall in `core`, and a context region must never be mistaken for
#' a parcel.
#'
#' @param labels Character vector of region labels.
#' @param core_labels Labels that are atlas regions. `NULL` treats every label
#'   as a region unless its name says otherwise.
#' @return Logical vector, one element per label.
#' @noRd
#' @keywords internal
is_context_label <- function(labels, core_labels = NULL) {
  not_core <- if (is.null(core_labels)) {
    rep(FALSE, length(labels))
  } else {
    !labels %in% core_labels
  }
  not_core | grepl(context_label_pattern, labels, ignore.case = TRUE)
}

#' Can a palette tell the atlas's regions apart?
#'
#' A palette is usable when its region entries hold more than one distinct
#' colour. Contextual labels are excluded from the judgement, so a grey medial
#' wall does not make an otherwise uniform palette look varied. Missing entries
#' count as a distinct state, so a palette covering only some regions is still
#' usable -- the uncovered regions render grey, which is a visible, honest gap.
#'
#' An atlas with a single region cannot be uniform in any meaningful sense, so
#' its palette is always usable. A dark palette is usable as long as its colours
#' differ: this rejects palettes that cannot be read, not palettes that are
#' merely dim, and it leaves a deliberate one-region design alone.
#'
#' @param palette Named character vector of colours keyed by label, or `NULL`.
#' @param labels Labels the plot will draw.
#' @param core_labels Labels that are atlas regions.
#' @return `TRUE` when the palette distinguishes regions.
#' @noRd
#' @keywords internal
palette_is_usable <- function(
  palette,
  labels = names(palette),
  core_labels = NULL
) {
  if (is.null(palette) || length(palette) == 0L) {
    return(FALSE)
  }
  region <- unique(labels[!is_context_label(labels, core_labels)])
  if (length(region) < 2L) {
    return(TRUE)
  }
  length(unique(toupper(unname(palette[region])))) > 1L
}

#' Build a palette of automatically assigned, distinguishable colours
#'
#' Qualitative `hcl()` colours are spread evenly across the atlas's regions;
#' contextual geometry keeps its conventional grey so it stays legible as
#' backdrop. Pure and deterministic, so the same atlas always gets the same
#' colours.
#'
#' @inheritParams is_context_label
#' @return Named character vector of colours, one per unique label.
#' @noRd
#' @keywords internal
fallback_palette <- function(labels, core_labels = NULL) {
  labels <- unique(labels[!is.na(labels)])
  region <- labels[!is_context_label(labels, core_labels)]
  n <- length(region)
  cols <- stats::setNames(rep(context_fill_colour, length(labels)), labels)
  cols[region] <- grDevices::hcl(
    h = seq(0, 360, length.out = n + 1L)[seq_len(n)],
    c = 80,
    l = 65
  )
  cols
}

#' All labels a plot of this atlas may need a colour for
#' @noRd
#' @keywords internal
plot_palette_labels <- function(atlas) {
  geom <- tryCatch(geom_from_data(atlas$data), error = function(e) NULL)
  geom_labels <- if (!is.null(geom) && "label" %in% names(geom)) geom$label
  all_labels <- unique(c(atlas$core$label, geom_labels))
  all_labels[!is.na(all_labels)]
}
