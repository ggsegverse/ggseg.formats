#' Reorder the structures of an atlas
#'
#' @description
#' Moves structures within an atlas's geometry, the way [dplyr::relocate()]
#' moves columns. Geometry rows are drawn in the order they appear, so this
#' is what decides which structure is painted over which where two overlap.
#'
#' Overlap is common in subcortical atlases: a slab is a thick slice of the
#' volume flattened into one panel, so structures that never touch in the
#' brain can still overlap on the page.
#'
#' @details
#' **Later rows are drawn on top.** With neither `.before` nor `.after`, the
#' structures move to the front, matching [dplyr::relocate()], which means
#' they are drawn *first*, and so end up *behind* everything else. To bring a
#' structure to the front visually, move it after the last one.
#'
#' The order is a property of the structure, not of a single view: an atlas
#' holds one geometry row per structure with its views nested inside, so a
#' structure keeps the same depth in every view it appears in.
#'
#' @param atlas A `ggseg_atlas` object.
#' @param structures Structures to move, as a character vector matched
#'   against `match_on`. They are moved together, keeping the order given
#'   here.
#' @param .before,.after One structure to move `structures` next to. Give at
#'   most one of the two.
#' @template match_on
#'
#' @return The `ggseg_atlas`, with its geometry rows in the new order.
#' @family atlas manipulations
#' @seealso [atlas_view_reorder()], which moves whole views around the
#'   canvas rather than structures within them.
#' @export
#' @examples
#' a <- aseg()
#'
#' # Draw the thalamus on top of everything else
#' last <- utils::tail(atlas_labels(a), 1)
#' a <- atlas_structure_reorder(a, "Left-Thalamus", .after = last)
#'
#' # Or tuck it behind its neighbours
#' a <- atlas_structure_reorder(a, "Left-Thalamus", .before = "Left-Putamen")
atlas_structure_reorder <- function(
  atlas,
  structures,
  .before = NULL,
  .after = NULL,
  match_on = c("label", "region")
) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  match_on <- match.arg(match_on)

  if (!is.null(.before) && !is.null(.after)) {
    cli::cli_abort(
      "Give at most one of {.arg .before} and {.arg .after}."
    )
  }

  geom <- geom_from_data(atlas$data)
  if (is.null(geom)) {
    cli::cli_abort("{.arg atlas} has no 2D geometry to reorder.")
  }

  drawn <- geom$label
  move <- resolve_structures(atlas, structures, match_on, drawn, "structures")

  # A label can own more than one row: geometry that has not been gathered
  # holds a row per structure and view. Move every row a structure owns, in
  # the order the structures were named, and keep each structure's own rows in
  # the order they were in.
  is_move <- drawn %in% move
  idx <- which(is_move)[order(match(drawn[is_move], move))]
  rest <- which(!is_move)

  anchor <- if (is.null(.before)) .after else .before
  if (is.null(anchor)) {
    new_order <- c(idx, rest)
  } else {
    anchor_label <- resolve_structures(
      atlas,
      anchor,
      match_on,
      drawn,
      if (is.null(.before)) ".after" else ".before"
    )
    if (length(anchor_label) != 1) {
      cli::cli_abort(c(
        "{.arg {if (is.null(.before)) '.after' else '.before'}} must name one
         structure, not {length(anchor_label)}.",
        "i" = "It matched {.val {anchor_label}}."
      ))
    }
    at <- which(drawn[rest] == anchor_label)
    if (!length(at)) {
      cli::cli_abort("Cannot move a structure next to itself.")
    }
    # Land outside every row the anchor owns, not just its first.
    after <- if (is.null(.before)) max(at) else min(at) - 1L
    new_order <- append(rest, idx, after = after)
  }

  new_data <- rebuild_data_with_geom(
    atlas$data,
    geom[new_order, , drop = FALSE]
  )

  ggseg_atlas(
    atlas = atlas$atlas,
    type = atlas$type,
    palette = atlas$palette,
    core = atlas$core,
    data = new_data
  )
}

#' Resolve structure names to the labels drawn in an atlas's geometry
#'
#' Contextual geometry (a grey cortex silhouette, say) is drawn but has no
#' `core` row, so names are matched against `core` first and fall back to the
#' drawn labels.
#' @noRd
#' @keywords internal
resolve_structures <- function(atlas, structures, match_on, drawn, arg) {
  if (!is.character(structures) || !length(structures)) {
    cli::cli_abort("{.arg {arg}} must be a character vector.")
  }

  # Resolve each name in turn so the caller's order is the order they move in.
  # One region can name several drawn structures (its two hemispheres).
  resolved <- unlist(lapply(structures, function(x) {
    from_core <- atlas$core$label[atlas$core[[match_on]] == x]
    hit <- unique(c(from_core, x))
    hit[hit %in% drawn]
  }))
  resolved <- unique(resolved)

  named <- structures %in% atlas$core[[match_on]] | structures %in% drawn
  if (!all(named)) {
    cli::cli_abort(c(
      "{.arg {arg}} names {cli::qty(sum(!named))}{?a structure/structures}
       not in this atlas.",
      "x" = "Unknown: {.val {structures[!named]}}."
    ))
  }

  if (!length(resolved)) {
    cli::cli_abort(c(
      "{.arg {arg}} names nothing that this atlas draws.",
      "i" = "{.val {structures}} {?is/are} in {.field core} but {?has/have} no
             geometry."
    ))
  }

  resolved
}
