#' Constructor for ggseg atlas
#'
#' Creates an object of class 'ggseg_atlas' for plotting brain parcellations
#' using ggseg (2D) and ggseg3d (3D).
#'
#' @param atlas atlas short name, length one
#' @param type atlas type: "cortical", "subcortical", "tract", or "cerebellar"
#' @param palette named character vector of colours keyed by label
#' @param core data.frame with required columns hemi, region, label. `label` is
#'   the key the palette and every geometry slot are joined on, so it must be
#'   unique: a duplicated `label` is an error. May contain additional columns
#'   for grouping or metadata (e.g., lobe, network, Brodmann area).
#' @param data a ggseg_atlas_data object created by
#'   [ggseg_data_cortical()], [ggseg_data_subcortical()],
#'   [ggseg_data_tract()], or [ggseg_data_cerebellar()].
#'   Must match the specified type.
#'
#' @return an object of class 'ggseg_atlas'
#' @export
#'
#' @examples
#' core <- data.frame(
#'   hemi = c("left", "left"),
#'   region = c("region1", "region2"),
#'   label = c("lh_region1", "lh_region2")
#' )
#' vertices <- data.frame(
#'   label = c("lh_region1", "lh_region2"),
#'   vertices = I(list(c(1L, 2L, 3L), c(4L, 5L, 6L)))
#' )
#' atlas <- ggseg_atlas(
#'   atlas = "test",
#'   type = "cortical",
#'   core = core,
#'   data = ggseg_data_cortical(vertices = vertices)
#' )
ggseg_atlas <- function(atlas, type, core, data, palette = NULL) {
  type <- match.arg(type, atlas_types())

  validate_ggseg_atlas_inputs(atlas, core, data, type)

  data <- validate_data_labels(data, core, report_2d_coverage = TRUE)

  if (!is.null(palette)) {
    palette <- validate_palette(palette, core)
  }

  structure(
    list(
      atlas = atlas,
      type = type,
      palette = palette,
      core = core,
      data = data
    ),
    class = c(
      paste0(type, "_atlas"),
      "ggseg_atlas",
      "list"
    )
  )
}


#' @rdname ggseg_atlas
#' @export
brain_atlas <- function(atlas, type, core, data, palette = NULL) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "brain_atlas()",
    "ggseg_atlas()"
  )
  ggseg_atlas(
    atlas = atlas,
    type = type,
    core = core,
    data = data,
    palette = palette
  )
}


#' Check ggseg atlas class
#'
#' These functions check both the class tag and structural validity
#' by passing the object through [ggseg_atlas()]. An object that
#' carries the right class but fails validation returns `FALSE`.
#'
#' @param x an object
#' @return logical
#' @seealso [assert_ggseg_atlas()], which aborts with the reason instead of
#'   reducing it to `FALSE`.
#' @name is_ggseg_atlas
#' @export
#' @examples
#' is_ggseg_atlas(dk())
#' is_cortical_atlas(dk())
#' is_subcortical_atlas(aseg())
#' is_tract_atlas(tracula())
is_ggseg_atlas <- function(x) {
  is_atlas_class(x) && validate_ggseg_atlas(x)
}

#' @rdname is_ggseg_atlas
#' @export
is_cortical_atlas <- function(x) {
  inherits(x, "cortical_atlas") && validate_ggseg_atlas(x)
}

#' @rdname is_ggseg_atlas
#' @export
is_subcortical_atlas <- function(x) {
  inherits(x, "subcortical_atlas") && validate_ggseg_atlas(x)
}

#' @rdname is_ggseg_atlas
#' @export
is_tract_atlas <- function(x) {
  inherits(x, "tract_atlas") && validate_ggseg_atlas(x)
}

#' @rdname is_ggseg_atlas
#' @export
is_cerebellar_atlas <- function(x) {
  inherits(x, "cerebellar_atlas") && validate_ggseg_atlas(x)
}

#' @rdname is_ggseg_atlas
#' @export
is_brain_atlas <- function(x) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "is_brain_atlas()",
    "is_ggseg_atlas()"
  )
  is_ggseg_atlas(x)
}

#' Require a valid ggseg atlas, reporting why it is not
#'
#' The companion to [is_ggseg_atlas()] for code that cannot continue without a
#' valid atlas. The predicate answers a yes/no question and so has nothing to
#' say about *why* an object failed; callers that turned that `FALSE` into an
#' error could only report the class, which is the one thing that was usually
#' fine. `assert_ggseg_atlas()` separates the two failure kinds:
#'
#' * A wrong class is reported as a wrong class.
#' * A `ggseg_atlas` whose parts do not satisfy the schema aborts with the
#'   [ggseg_atlas()] constructor's own diagnostic, chained as the parent error,
#'   so the reader sees the missing column, the duplicated label or the
#'   mismatched data class instead of a message about the class tag.
#'
#' Prefer this wherever a bad atlas would otherwise propagate; keep
#' [is_ggseg_atlas()] for control flow, where signalling is wrong.
#'
#' @param x an object
#' @param arg argument name to report, for use inside another function
#' @param call environment the error is attributed to
#'
#' @return `x`, invisibly, when it is a valid atlas. Aborts otherwise.
#' @export
#' @examples
#' atlas <- assert_ggseg_atlas(dk())
#'
#' broken <- dk()
#' broken$core$label <- NULL
#' try(assert_ggseg_atlas(broken))
assert_ggseg_atlas <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (!is_atlas_class(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a {.cls ggseg_atlas}, not {.cls {class(x)[1]}}.",
      class = "ggseg.formats_not_atlas",
      call = call
    )
  }

  defect <- atlas_structure_defect(x)
  if (!is.null(defect)) {
    cli::cli_abort(
      "{.arg {arg}} is a {.cls ggseg_atlas} with an invalid structure.",
      class = "ggseg.formats_invalid_atlas",
      parent = defect,
      call = call
    )
  }

  invisible(x)
}

#' Check if object is a legacy ggseg3d atlas
#'
#' @param x an object
#' @return logical
#' @export
#' @examples
#' is_ggseg3d_atlas(dk())
is_ggseg3d_atlas <- function(x) {
  is.data.frame(x) && "ggseg_3d" %in% names(x)
}


#' @export
#' @importFrom stats na.omit
print.ggseg_atlas <- function(x, n = 10, ...) {
  data <- x$data
  geom <- geom_from_data(data)
  has_sf <- !is.null(geom)
  has_3d <- !is.null(data$vertices) ||
    !is.null(data$meshes) ||
    !is.null(data$centerlines)

  print_atlas_summary(x, has_sf)
  print_atlas_rendering(x, data, has_sf, has_3d)

  cli::cli_rule()

  print_data_head(x$core, n)

  invisible(x)
}


#' @export
as.list.ggseg_atlas <- function(x, ...) {
  list(
    atlas = x$atlas,
    type = x$type,
    palette = x$palette,
    core = x$core,
    data = x$data
  )
}


#' @export
as.data.frame.ggseg_atlas <- function(x, ...) {
  sf_data <- as_sf_for_data_frame(x)
  result <- merge_core_into_sf(sf_data, x$core)

  if (x$type == "cortical") {
    result <- infer_cortical_hemi(result)
  }

  result$atlas <- x$atlas
  result$type <- x$type

  if (!is.null(x$palette)) {
    result$colour <- unname(x$palette[result$label])
  }

  result <- order_context_behind(result, x$core$label)

  sf::st_as_sf(result)
}

#' @importFrom graphics mtext par plot.new plot.window polygon polypath
#' @export
plot.ggseg_atlas <- function(x, ...) {
  flat <- polygons_unnest(atlas_polygons(x))
  flat <- order_context_behind(flat, x$core$label)
  fill_colors <- resolve_fill_colors(
    flat$label,
    atlas_plot_palette(x),
    x$core$label
  )
  dots <- list(...)

  # One panel per spatially separate piece, arranged in a near-square grid so
  # each gets enough room to read. This is a quick overview of the atlas, not a
  # publication figure.
  cell <- plot_cells(flat, resolve_plot_hemi(flat$label, x$core))
  cells <- order_cells_spatially(cell, flat$x)
  ncol <- ceiling(sqrt(length(cells)))
  nrow <- ceiling(length(cells) / ncol)
  cell_tables <- split(flat, cell)

  old_par <- par(
    mfrow = c(nrow, ncol),
    mar = c(0.3, 0.3, 0.3, 0.3),
    oma = c(0, 0, 2, 0)
  )
  on.exit(par(old_par), add = TRUE)

  for (ci in cells) {
    cf <- cell_tables[[as.character(ci)]]
    plot.new()
    plot.window(
      xlim = range(cf$x, na.rm = TRUE),
      ylim = range(cf$y, na.rm = TRUE),
      asp = 1
    )
    # Factor levels follow first appearance (not the alphabetical order a bare
    # character split would impose) so the context-behind ordering set above is
    # honoured when the pieces are drawn.
    piece_id <- piece_keys(cf)
    pieces <- split(cf, factor(piece_id, levels = unique(piece_id)))
    invisible(lapply(pieces, function(piece) {
      draw_piece(piece, fill_colors[[piece$label[[1L]]]], dots)
    }))
  }

  mtext(paste(x$atlas, x$type, "atlas"), outer = TRUE, cex = 1, line = 0.5)

  invisible(x)
}

#' Order plot panels by their left-to-right position
#'
#' Panel ids come from [plot_cells()], which numbers cells in the order views
#' are encountered in the row table. For `brain_polygons` those rows are nested
#' by `label`, so encounter order depends on which views the first label happens
#' to carry -- it neither follows the atlas layout nor is stable. Ordering by
#' each cell's leftmost x makes the panels read in the order the views are
#' actually laid out, so [atlas_view_reorder()] is honoured.
#' @noRd
#' @keywords internal
order_cells_spatially <- function(cell, x) {
  cells <- unique(cell)
  left <- vapply(
    cells,
    function(ci) min(x[cell == ci], na.rm = TRUE),
    numeric(1)
  )
  cells[order(left, cells)]
}


#' Lightweight class check for atlas-classed objects
#'
#' `TRUE` when `x` carries the `ggseg_atlas` or legacy `brain_atlas` class
#' tag, without the structural revalidation that [is_ggseg_atlas()] performs.
#' @noRd
#' @keywords internal
is_atlas_class <- function(x) {
  inherits(x, "ggseg_atlas") || inherits(x, "brain_atlas")
}


#' Structurally revalidate an atlas, without signalling
#'
#' Reports only whether the `ggseg_atlas()` constructor accepts the parts of
#' `x`. Every class predicate (`is_ggseg_atlas()` and friends) goes through
#' here, and renderers call those predicates in their control flow, so this
#' must stay silent and must keep returning a bare logical: the constructor's
#' schema nudges are for the atlas author at build time, not for the user of a
#' published atlas. `assert_ggseg_atlas()` is the signalling counterpart.
#' @keywords internal
#' @noRd
validate_ggseg_atlas <- function(x) {
  is.null(atlas_structure_defect(x))
}


#' The constructor error an atlas's parts raise, or `NULL`
#'
#' Re-runs the `ggseg_atlas()` constructor on the parts of `x` and returns the
#' condition it threw, so a caller can either reduce it to a logical
#' (`validate_ggseg_atlas()`) or re-raise it as the parent of its own error
#' (`assert_ggseg_atlas()`). Messages and warnings are muffled either way;
#' only an error distinguishes a structurally invalid atlas.
#' @keywords internal
#' @noRd
atlas_structure_defect <- function(x) {
  rlang::try_fetch(
    suppressMessages(suppressWarnings({
      ggseg_atlas(
        atlas = x$atlas,
        type = x$type,
        core = x$core,
        data = x$data,
        palette = x$palette
      )
      NULL
    })),
    error = function(cnd) cnd
  )
}


#' Resolve an atlas's 2D geometry to a non-empty sf data frame
#'
#' Used by `as.data.frame.ggseg_atlas()`. Aborts when there is no 2D geometry
#' (or it is empty) and requires sf.
#' @noRd
#' @keywords internal
as_sf_for_data_frame <- function(x) {
  geom <- if (inherits(x$data, "ggseg_atlas_data")) {
    geom_from_data(x$data)
  } else {
    NULL
  }
  has_2d_slot <- !is.null(geom) ||
    inherits(x$data, "sf") ||
    inherits(x$data, "data.frame")
  if (!has_2d_slot) {
    cli::cli_abort("Cannot convert ggseg_atlas to data.frame: no 2D geometry.")
  }
  require_sf("as.data.frame.ggseg_atlas()")

  sf_data <- if (!is.null(geom)) {
    sf::st_as_sf(
      if (inherits(geom, "brain_polygons")) polygons_to_sf(geom) else geom
    )
  } else {
    sf::st_as_sf(x$data)
  }

  if (nrow(sf_data) == 0) {
    cli::cli_abort("Cannot convert ggseg_atlas to data.frame: no 2D geometry.")
  }
  sf_data
}


#' Merge atlas `core` metadata into the sf geometry by label
#'
#' Returns the sf data unchanged when `core` is `NULL`. Preserves an sf-side
#' `hemi` column to fill gaps left by the join.
#' @noRd
#' @keywords internal
merge_core_into_sf <- function(sf_data, core) {
  if (is.null(core)) {
    return(sf_data)
  }
  has_sf_hemi <- "hemi" %in% names(sf_data)
  if (has_sf_hemi) {
    sf_data$.sf_hemi <- sf_data$hemi
  }
  core_cols <- c("hemi", "region")
  if (any(core_cols %in% names(sf_data))) {
    sf_data[core_cols] <- NULL
  }
  result <- merge(sf_data, core, by = "label", all.x = TRUE)
  if (has_sf_hemi) {
    missing <- is.na(result$hemi) & !is.na(result$.sf_hemi)
    if (any(missing)) {
      result$hemi[missing] <- result$.sf_hemi[missing]
    }
    result$.sf_hemi <- NULL
  }
  result
}


#' Infer missing hemispheres from `lh`/`rh` label prefixes (cortical atlases)
#'
#' Rows whose hemisphere cannot be determined are dropped.
#' @noRd
#' @keywords internal
infer_cortical_hemi <- function(result) {
  if (!"hemi" %in% names(result)) {
    result$hemi <- NA_character_
  }
  missing_hemi <- is.na(result$hemi)
  if (any(missing_hemi)) {
    result$hemi[missing_hemi] <- hemi_from_label(
      result$label[missing_hemi],
      default = NA_character_
    )
  }
  still_missing <- is.na(result$hemi)
  if (any(still_missing)) {
    result <- result[!still_missing, , drop = FALSE]
  }
  result
}

#' Resolve per-label fill colours for plotting
#'
#' Palette entries win where present and non-NA; labels with no palette entry
#' (or an `NA` entry) fall back to grey. With no palette at all, qualitative
#' `hcl()` colours are generated across the label set. Pure and deterministic
#' so the colour logic can be tested without a graphics device.
#'
#' Contextual geometry is always grey. A label absent from `core` is anatomical
#' backdrop -- the cortical outline a slice is drawn over -- rather than a
#' region of the atlas, and that is a property of the geometry, not of the
#' palette. Atlas creation returns no palette when it was given no colours, so
#' without this the generated colours would be spread across the backdrop too
#' and it would compete with the regions it sits behind. The generated branch
#' additionally greys the backdrop names the pipelines reserve (`cortex_*`,
#' `unknown`), which some atlases keep inside `core`.
#'
#' @param labels Character vector of region labels (deduplicated internally).
#' @param palette Optional named character vector of colours keyed by label.
#' @param core_labels Labels that are atlas regions. Any other label is drawn
#'   as context. Defaults to treating every label as a region.
#' @return Named character vector of colours, one per unique label.
#' @noRd
#' @keywords internal
resolve_fill_colors <- function(labels, palette = NULL, core_labels = NULL) {
  labels <- unique(labels)
  is_context <- if (is.null(core_labels)) {
    rep(FALSE, length(labels))
  } else {
    !labels %in% core_labels
  }

  if (!is.null(palette)) {
    vals <- palette[labels]
    matched <- !is.na(vals) & !is_context
    return(stats::setNames(
      ifelse(matched, vals, context_fill_colour),
      labels
    ))
  }

  fallback_palette(labels, labels[!is_context])
}

#' Draw a single atlas polygon piece on the current device
#'
#' One contiguous region piece, keyed by label × view × group. A piece with a
#' single ring is drawn with [graphics::polygon()]; a piece with holes (multiple
#' `subgroup` rings) is drawn with [graphics::polypath()] using NA-separated
#' rings and the even-odd rule. `dots` overrides the styling defaults so callers
#' can pass e.g. `lwd` or `border` through `plot()`.
#' @noRd
#' @keywords internal
draw_piece <- function(piece, col, dots = list()) {
  rings <- sort(unique(piece$subgroup))
  defaults <- list(col = col, border = "white", lwd = 0.3)

  if (length(rings) == 1L) {
    do.call(
      polygon,
      c(
        list(x = piece$x, y = piece$y),
        utils::modifyList(defaults, dots)
      )
    )
    return(invisible())
  }

  rings_xy <- split(piece[c("x", "y")], piece$subgroup)[as.character(rings)]
  xs <- unlist(
    lapply(rings_xy, function(r) c(r$x, NA_real_)),
    use.names = FALSE
  )
  ys <- unlist(
    lapply(rings_xy, function(r) c(r$y, NA_real_)),
    use.names = FALSE
  )
  do.call(
    polypath,
    c(
      list(x = xs[-length(xs)], y = ys[-length(ys)]),
      utils::modifyList(c(defaults, list(rule = "evenodd")), dots)
    )
  )
  invisible()
}

#' Identify the drawable pieces of a polygon table
#'
#' A piece is one contiguous polygon: a region's rings for a single view. The
#' `view` component keeps a region's per-view instances from being joined.
#' Panel assignment works at this granularity so a piece is never split across
#' two panels.
#' @noRd
#' @keywords internal
piece_keys <- function(flat) {
  paste(flat$label, flat$view, flat$group, sep = "\r")
}

#' Resolve a hemisphere for each polygon row
#'
#' Reads `hemi` from the atlas core, falling back to the `lh_`/`rh_` label
#' prefix for contextual regions that are drawn but hold no core entry. `NA`
#' where neither resolves.
#' @noRd
#' @keywords internal
resolve_plot_hemi <- function(label, core) {
  out <- rep(NA_character_, length(label))
  if (!is.null(core) && all(c("label", "hemi") %in% names(core))) {
    out <- as.character(core$hemi[match(label, core$label)])
  }
  unresolved <- is.na(out)
  out[unresolved] <- hemi_from_label(label[unresolved], default = NA_character_)
  out
}

#' Partition one view's rows into left and right hemisphere panels
#'
#' Hemisphere is the boundary these panels are meant to follow, so it is
#' preferred over the coordinate-gap heuristic, whose threshold is measured
#' against the width of the whole view and so drifts between atlases that look
#' alike. Returns `NULL` — leaving the caller on the gap heuristic — unless the
#' view divides unambiguously: both hemispheres present, their x extents
#' disjoint, and every remaining piece (midline structures, contextual
#' silhouettes) falling wholly inside one of them. Anything spanning the divide
#' blocks the split, so no piece is ever clipped out of both panels. Panel 1 is
#' the leftmost hemisphere on screen, matching the ordering [gap_groups()]
#' produces.
#' @noRd
#' @keywords internal
hemi_cells <- function(hemi, x, piece) {
  side <- ifelse(hemi %in% c("left", "right"), hemi, NA_character_)
  is_left <- !is.na(side) & side == "left"
  is_right <- !is.na(side) & side == "right"
  if (!any(is_left) || !any(is_right)) {
    return(NULL)
  }

  left <- range(x[is_left])
  right <- range(x[is_right])
  if (left[[1L]] <= right[[2L]] && right[[1L]] <= left[[2L]]) {
    return(NULL)
  }

  keys <- unique(piece)
  rows_of <- split(seq_along(x), factor(piece, levels = keys))
  piece_side <- vapply(
    rows_of,
    function(ix) {
      lateral <- unique(side[ix])
      lateral <- lateral[!is.na(lateral)]
      if (length(lateral) == 1L) {
        return(lateral)
      }
      contained_in(range(x[ix]), left, right)
    },
    character(1L)
  )

  if (anyNA(piece_side)) {
    return(NULL)
  }

  leftmost <- if (left[[1L]] < right[[1L]]) "left" else "right"
  unname(ifelse(piece_side[match(piece, keys)] == leftmost, 1L, 2L))
}

#' Name the hemisphere extent that wholly contains a span
#'
#' `NA` when the span straddles the divide or sits in the gap between the two,
#' which is the signal that a hemisphere split would orphan the piece.
#' @noRd
#' @keywords internal
contained_in <- function(span, left, right) {
  if (span[[1L]] >= left[[1L]] && span[[2L]] <= left[[2L]]) {
    return("left")
  }
  if (span[[1L]] >= right[[1L]] && span[[2L]] <= right[[2L]]) {
    return("right")
  }
  NA_character_
}

#' Partition coordinates into groups separated by empty gaps along one axis
#'
#' Returns a contiguous integer group id per element. A break is placed wherever
#' the sorted values jump by more than `gap_frac` of the total span — i.e. an
#' empty band wider than that fraction. Order of the input is preserved.
#' @noRd
#' @keywords internal
gap_groups <- function(values, gap_frac) {
  span <- diff(range(values))
  if (span == 0) {
    return(rep(1L, length(values)))
  }
  o <- order(values)
  breaks <- cumsum(c(0L, diff(values[o]) > gap_frac * span))
  out <- integer(length(values))
  out[o] <- breaks + 1L
  out
}

#' Subdivide an existing grouping by gaps along one axis
#'
#' Splits each current group further wherever `values` has an empty band, and
#' renumbers the result to contiguous ids. Order is preserved.
#' @noRd
#' @keywords internal
refine_by_gaps <- function(cell, values, gap_frac) {
  refined <- integer(length(cell))
  next_id <- 0L
  for (cid in unique(cell)) {
    within <- which(cell == cid)
    sub <- gap_groups(values[within], gap_frac)
    refined[within] <- sub + next_id
    next_id <- next_id + max(sub)
  }
  refined
}

#' Assign each row to a display cell
#'
#' The atlas views are pre-positioned in one coordinate space, but a surface
#' atlas still splits into spatially separate pieces within a view (e.g. the
#' left and right hemispheres, drawn apart with empty space between). Each view
#' is divided by hemisphere where `hemi` makes the division unambiguous, since
#' that is the boundary the panels are meant to follow; views it cannot resolve
#' fall back to gap-splitting along x then y. Returns a cell id per row, with
#' order preserved.
#'
#' @param flat Unnested polygon table with `view`, `x`, `y` columns.
#' @param hemi Optional hemisphere per row, from [resolve_plot_hemi()].
#' @param gap_frac Gap threshold for the fallback heuristic, as a fraction of
#'   the view's total span.
#' @noRd
#' @keywords internal
plot_cells <- function(flat, hemi = NULL, gap_frac = 0.12) {
  ids <- integer(nrow(flat))
  pieces <- piece_keys(flat)
  base <- 0L
  for (v in unique(flat$view)) {
    ix <- which(flat$view == v)
    cell <- NULL
    if (!is.null(hemi)) {
      cell <- hemi_cells(hemi[ix], flat$x[ix], pieces[ix])
    }
    if (is.null(cell)) {
      cell <- rep(1L, length(ix))
      for (axis in c("x", "y")) {
        cell <- refine_by_gaps(cell, flat[[axis]][ix], gap_frac)
      }
    }
    ids[ix] <- cell + base
    base <- base + max(cell)
  }
  ids
}

#' Validate constructor inputs for [ggseg_atlas()]
#'
#' Checks `atlas`, `core`, and `data` for type, required columns, and the
#' expected `ggseg_data_*`/`brain_data_*` class for `type`. Aborts on the first
#' violation; returns invisibly when all checks pass.
#' @noRd
#' @keywords internal
validate_ggseg_atlas_inputs <- function(atlas, core, data, type) {
  if (length(atlas) != 1 || !is.character(atlas)) {
    cli::cli_abort(
      "{.arg atlas} must be a single character string, not {length(atlas)}."
    )
  }

  if (!is.data.frame(core)) {
    cli::cli_abort("{.arg core} must be a data.frame.")
  }

  required_core <- c("region", "label")
  missing_core <- setdiff(required_core, names(core))
  if (length(missing_core) > 0) {
    cli::cli_abort(
      "{.arg core} must contain columns: {.field {missing_core}}."
    )
  }

  validate_core_display(core, atlas)
  validate_core_label_unique(core, atlas)

  if (
    !inherits(data, "ggseg_atlas_data") &&
      !inherits(data, "brain_atlas_data")
  ) {
    cli::cli_abort(c(
      "{.arg data} must be a {.cls ggseg_atlas_data} object.",
      "i" = "Use {.fn ggseg_data_cortical}, {.fn ggseg_data_subcortical},
      {.fn ggseg_data_tract}, or {.fn ggseg_data_cerebellar}."
    ))
  }

  expected_new <- paste0("ggseg_data_", type)
  expected_old <- paste0("brain_data_", type)
  if (!inherits(data, expected_new) && !inherits(data, expected_old)) {
    cli::cli_abort(c(
      "Atlas type {.val {type}} requires {.cls {expected_new}}.",
      "x" = "Got {.cls {class(data)[1]}}."
    ))
  }

  invisible()
}

#' Abort when `core$label` is not unique
#'
#' `label` is the key the palette and every geometry slot are joined on, so a
#' duplicated label fans one geometry row into several: the same parcel is
#' drawn more than once, which in 3D also breaks semi-transparent compositing.
#' The bundled `aseg` carried such alias rows (`Thalamus` / `Thalamus Proper`)
#' until 0.1.0, and 18 of its 47 meshes were exact duplicates as a result.
#'
#' This is a schema violation rather than schema incompleteness, so it aborts
#' from the constructor, where the atlas author stands and can fix the table.
#' Read paths stay forgiving: legacy conversion collapses alias rows (see
#' `dedupe_legacy_core_labels()`) and ggseg3d de-duplicates defensively at
#' render time, so already-published atlases keep loading and drawing.
#' @noRd
#' @keywords internal
validate_core_label_unique <- function(core, atlas) {
  dupes <- unique(core$label[duplicated(core$label)]) # nolint
  if (length(dupes) == 0) {
    return(invisible())
  }
  cli::cli_abort(
    c(
      "{.arg core$label} must be unique in {.val {atlas}}.",
      "x" = "Duplicated: {.val {dupes}}.",
      "i" = "{.field label} is the key the palette and geometry join on, so a
             duplicate draws the same region more than once.",
      "i" = "Keep one row per {.field label} and move any alias name into
             {.field display}."
    ),
    class = "ggseg.formats_duplicate_labels"
  )
}


#' Collapse duplicated `core$label` rows on a legacy conversion path
#'
#' The constructor rejects duplicated labels, but the legacy atlases
#' [convert_legacy_brain_atlas()] and [as_ggseg_atlas()] exist to migrate are
#' exactly the ones that carry alias rows. Keeping the first row per `label`
#' and warning lets the migration finish with a schema-valid atlas instead of
#' aborting on data the caller cannot edit.
#' @noRd
#' @keywords internal
dedupe_legacy_core_labels <- function(core, atlas = NA_character_) {
  if (is.null(core) || !is.data.frame(core) || !"label" %in% names(core)) {
    return(core)
  }
  dupes <- unique(core$label[duplicated(core$label)]) # nolint
  if (length(dupes) == 0) {
    return(core)
  }
  cli::cli_warn(
    c(
      "Collapsed {length(dupes)} duplicated {.field label} row{?s} while
       converting {.val {atlas}}: {.val {dupes}}.",
      "i" = "The first row of each duplicated {.field label} is kept."
    ),
    class = "ggseg.formats_collapsed_duplicate_labels"
  )
  core[!duplicated(core$label), , drop = FALSE]
}


#' Enforce the `display` column of `core`
#'
#' `display` holds the curated long-form display name and is part of the `core`
#' schema. It arrived after roughly twenty atlas packages had already been
#' published against the schema without it, so a hard requirement would break
#' every one of them on load. The policy is therefore: required and strictly
#' validated when present -- a malformed `display` is an error, because a
#' half-filled column is worse than none -- and, when absent, a message once per
#' atlas per session. Only the atlas author can add the column, so the signal is
#' raised on construction, where an author stands, and muffled by
#' `validate_ggseg_atlas()`, which every class predicate and renderer reaches.
#' @noRd
#' @keywords internal
validate_core_display <- function(core, atlas) {
  if (!"display" %in% names(core)) {
    rlang::inform(
      cli::format_message(c(
        "i" = "{.arg core} has no {.field display} column.",
        "i" = "{.field display} holds the long-form display name and is part
               of the {.arg core} schema; add it when rebuilding
               {.val {atlas}}.",
        "i" = "See {.fn atlas_display}."
      )),
      class = "ggseg.formats_missing_display",
      .frequency = "once",
      .frequency_id = paste0("ggseg.formats-core-display-", atlas)
    )
    return(invisible())
  }

  if (!is.character(core$display)) {
    cli::cli_abort(
      "{.arg core$display} must be a character vector, not
       {.cls {class(core$display)[1]}}."
    )
  }

  invisible()
}


#' Print the header and summary block for a ggseg atlas
#'
#' Emits the title, type, region count, hemispheres, and (when 2D geometry is
#' present) the available views. Side-effecting; returns invisibly.
#' @noRd
#' @keywords internal
print_atlas_summary <- function(x, has_sf) {
  n_regions <- length(stats::na.omit(unique(x$core$region))) # nolint
  hemis <- paste0(unique(x$core$hemi), collapse = ", ") # nolint

  cli::cli_h1("{x$atlas} ggseg atlas")

  cli::cli_text("{.strong Type: {x$type}}")
  cli::cli_text("{.strong Regions:} {n_regions}")
  cli::cli_text("{.strong Hemispheres:} {hemis}")

  if (has_sf) {
    views <- paste0(atlas_views(x), collapse = ", ") # nolint
    cli::cli_text("{.strong Views:} {views}")
  }

  invisible()
}

#' Print the palette and rendering-support block for a ggseg atlas
#'
#' Emits palette presence plus ggseg (2D) and ggseg3d (3D) rendering status,
#' noting which 3D geometry slot is available. Side-effecting; returns
#' invisibly.
#' @noRd
#' @keywords internal
print_atlas_rendering <- function(x, data, has_sf, has_3d) {
  has_palette <- !is.null(x$palette) # nolint: object_usage_linter

  check <- function(val) {
    # nolint: object_usage_linter
    if (val) {
      cli::col_green(cli::symbol$tick)
    } else {
      cli::col_red(cli::symbol$cross)
    }
  }

  cli::cli_text("{.strong Palette:} {check(has_palette)}")

  # nolint start: object_usage_linter
  render_3d <- if (!is.null(data$centerlines)) {
    # nolint end
    "centerlines"
  } else if (!is.null(data$meshes)) {
    "meshes"
  } else if (!is.null(data$vertices)) {
    "vertices"
  } else {
    "none"
  }
  ggseg_status <- check(has_sf) # nolint: object_usage_linter
  ggseg3d_status <- check(has_3d) # nolint: object_usage_linter
  cli::cli_text("{.strong Rendering:} {ggseg_status} ggseg")
  cli::cli_text("             {ggseg3d_status} ggseg3d ({render_3d})")

  invisible()
}
