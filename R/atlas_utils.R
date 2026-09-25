#' Extract unique region names from an atlas
#'
#' @param x brain atlas
#' @return Character vector of region names
#' @examples
#' atlas_regions(dk())
#' atlas_regions(aseg())
#'
#' @export
#' @family atlas accessors
atlas_regions <- function(x) {
  UseMethod("atlas_regions")
}

#' @export
atlas_regions.ggseg_atlas <- function(x) {
  get_uniq(x$core, "region")
}

#' @export
atlas_regions.brain_atlas <- function(x) {
  get_uniq(x$core, "region")
}

#' @export
atlas_regions.data.frame <- function(x) {
  get_uniq(x, "region")
}

#' Extract unique labels from an atlas
#'
#' @param x brain atlas
#' @return Character vector of atlas region labels
#' @examples
#' atlas_labels(dk())
#' atlas_labels(aseg())
#'
#' @export
#' @family atlas accessors
atlas_labels <- function(x) {
  UseMethod("atlas_labels")
}

#' @export
atlas_labels.ggseg_atlas <- function(x) {
  get_uniq(x$core, "label")
}

#' @export
atlas_labels.brain_atlas <- function(x) {
  get_uniq(x$core, "label")
}


#' @rdname atlas_regions
#' @export
brain_regions <- function(x) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "brain_regions()",
    "atlas_regions()"
  )
  atlas_regions(x)
}

#' @rdname atlas_labels
#' @export
brain_labels <- function(x) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "brain_labels()",
    "atlas_labels()"
  )
  atlas_labels(x)
}


#' Detect atlas type
#' @param x brain atlas object
#' @return Character string: one of "cortical", "subcortical", "tract" or
#'   "cerebellar".
#' @seealso [set_atlas_type()] to set the type.
#' @examples
#' atlas_type(dk())
#' atlas_type(aseg())
#' atlas_type(tracula())
#'
#' @export
#' @family atlas accessors
atlas_type <- function(x) {
  UseMethod("atlas_type")
}

#' @export
atlas_type.ggseg_atlas <- function(x) {
  guess_type(x)
}

#' @export
atlas_type.brain_atlas <- function(x) {
  guess_type(x)
}


# Atlas manipulation functions ----

#' Manipulate brain atlas regions and views
#'
#' Functions for modifying brain atlas objects. These cover three areas:
#'
#' **Region manipulation** modifies which regions are active in the atlas:
#' - `atlas_region_remove()`: completely remove regions
#' - `atlas_region_contextual()`: keep geometry but remove from core/palette
#' - `atlas_context_remove()`: drop all contextual sf geometry
#' - `atlas_region_rename()`: rename regions in core
#' - `atlas_region_keep()`: keep only matching regions
#' - `atlas_region_op()`: combine two regions' geometry with a boolean op
#'   (difference / intersection / union / symdifference)
#'
#' **View manipulation** modifies the 2D sf geometry data:
#' - `atlas_view_remove()`: remove entire views
#' - `atlas_view_keep()`: keep only matching views
#' - `atlas_view_remove_region()`: remove specific region geometry from sf
#' - `atlas_view_remove_small()`: remove small regions, or stray specks
#' - `atlas_view_select()`: keep each region only in the views that show it
#'   well
#' - `atlas_view_gather()`: reposition views to close gaps
#' - `atlas_view_reorder()`: change view order
#'
#' **Core manipulation** modifies atlas metadata:
#' - `atlas_core_add()`: join additional metadata columns
#'
#' @param atlas A `ggseg_atlas` object
#' @param pattern Character pattern to match. Uses
#'   `grepl(..., ignore.case = TRUE)`.
#' @param match_on Column to match against: `"region"` or `"label"`.
#' @param ignore.case For `atlas_region_contextual()`: passed to [grepl()].
#'   Defaults to `TRUE` for backwards compatibility, but note that a context
#'   pattern like `"Thalamus"` then also matches focus labels such as
#'   `"hypothalamus"`; set `FALSE` (and/or anchor the pattern) when that
#'   matters.
#' @param replacement For `atlas_region_rename()`: replacement string or
#'   function.
#' @param views For view functions: character vector of view names or
#'   patterns. Multiple values collapsed with `"|"` for matching.
#' @param order For `atlas_view_reorder()`: character vector of desired
#'   view order. Unspecified views appended at end.
#' @param min_area For `atlas_view_remove_small()`: minimum area to keep.
#'   What it applies to depends on `scope`; with the default
#'   `scope = "region"` context geometries are never removed.
#' @param gap Proportional gap between views (default 0.15 = 15% of max width).
#' @param data For `atlas_core_add()`: data.frame with metadata to join.
#' @param by For `atlas_core_add()`: column(s) to join by. Default `"region"`.
#'
#' @return Modified `ggseg_atlas` object
#'
#' @examples
#' dk() |>
#'   atlas_region_remove("bankssts") |>
#'   atlas_region_keep("frontal", match_on = "region")
#'
#' @name atlas_manipulation
#' @export
#' @family atlas manipulations
atlas_region_remove <- function(
  atlas,
  pattern,
  match_on = c("region", "label")
) {
  match_on <- match.arg(match_on)

  match_col <- atlas$core[[match_on]]
  keep_mask <- !grepl(pattern, match_col, ignore.case = TRUE)
  keep_mask[is.na(match_col)] <- TRUE

  labels_to_remove <- atlas$core$label[!keep_mask]

  new_core <- atlas$core[keep_mask, , drop = FALSE]
  new_palette <- atlas$palette[!names(atlas$palette) %in% labels_to_remove]

  new_geom <- geom_drop_pattern(geom_from_data(atlas$data), pattern)
  new_data <- rebuild_data_with_geom(
    atlas$data,
    new_geom,
    keep_row = function(label) !label %in% labels_to_remove
  )

  ggseg_atlas(
    atlas = atlas$atlas,
    type = atlas$type,
    palette = new_palette,
    core = new_core,
    data = new_data
  )
}


#' @describeIn atlas_manipulation Keep geometry for visual context but remove
#'   from core, palette, and 3D data. Context geometries render grey and don't
#'   appear in legends. Contextual rows are moved behind the remaining core
#'   regions so focus regions draw on top where they overlap in projection.
#'   Operates on whichever 2D representation the atlas carries (`sf` and/or
#'   `polygons`), keeping both in sync, and needs no `sf` for a polygon atlas.
#' @export
#' @family atlas manipulations
atlas_region_contextual <- function(
  atlas,
  pattern,
  match_on = c("region", "label"),
  ignore.case = TRUE # nolint: object_name_linter.
) {
  match_on <- match.arg(match_on)

  match_col <- atlas$core[[match_on]]
  keep_mask <- !grepl(pattern, match_col, ignore.case = ignore.case)
  keep_mask[is.na(match_col)] <- TRUE

  labels_to_remove <- atlas$core$label[!keep_mask]

  new_core <- atlas$core[keep_mask, , drop = FALSE]
  new_palette <- atlas$palette[!names(atlas$palette) %in% labels_to_remove]

  # Draw contextual regions behind core regions: 2D geometry renders in row
  # order, so move every row whose label is no longer in core (the regions
  # just made contextual, plus pipeline outlines like `cortex`/`Background`)
  # ahead of the core rows. This keeps focus regions on top where context
  # structures spatially overlap them in projection. `order_context_behind()`
  # works on either geometry representation without invoking sf.
  new_geom <- order_context_behind(geom_from_data(atlas$data), new_core$label)
  new_data <- rebuild_data_with_geom(
    atlas$data,
    new_geom,
    keep_row = function(label) !label %in% labels_to_remove
  )

  validate_data_labels(new_data, new_core, check_sf = FALSE)

  structure(
    list(
      atlas = atlas$atlas,
      type = atlas$type,
      palette = new_palette,
      core = new_core,
      data = new_data
    ),
    class = class(atlas)
  )
}


#' @describeIn atlas_manipulation Combine two sets of region geometry with a
#'   vector boolean operation (per view), writing the result to a new region
#'   `into`. `x` and `y` are patterns matched against `match_on`; within each
#'   view their matching geometries are unioned, then combined via `action`:
#'   `"difference"` (x minus y, e.g. punching white matter out of a cortex
#'   silhouette), `"intersection"`, `"union"`, or `"symdifference"`. Inputs are
#'   left in place; any existing `into` geometry is replaced. With a `colour`,
#'   `into` becomes a legended core region; otherwise it stays contextual
#'   (grey) and is drawn behind the core regions. Boolean ops need a geometry
#'   engine, so this is the one manipulation helper that always requires `sf`
#'   installed; a polygon-only atlas is rehydrated for the operation and the
#'   result is returned in polygon form.
#' @param x,y For `atlas_region_op()`: patterns selecting the two operands.
#' @param action For `atlas_region_op()`: the boolean operation to apply.
#' @param into For `atlas_region_op()`: label for the result region.
#' @param colour For `atlas_region_op()`: optional fill for `into`. When
#'   supplied, `into` is registered in core and palette; when `NULL`, the
#'   result is contextual geometry only.
#' @export
#' @family atlas manipulations
atlas_region_op <- function(
  atlas,
  x,
  y,
  action = c("difference", "intersection", "union", "symdifference"),
  into = NULL,
  match_on = c("label", "region"),
  colour = NULL
) {
  action <- match.arg(action)
  match_on <- match.arg(match_on)
  # Boolean geometry ops need a geometry engine (GEOS, via sf); there is no
  # pure-polygon equivalent. A polygon-only atlas is rehydrated to sf for the
  # operation and the result is converted back, so the atlas keeps its
  # original 2D format.
  require_sf("atlas_region_op()")

  if (is.null(into) || !is.character(into) || length(into) != 1) {
    cli::cli_abort("{.arg into} must be a single label for the result region.")
  }

  resolved <- region_op_sf_data(atlas$data)
  sf_data <- resolved$sf_data
  was_polygon_only <- resolved$was_polygon_only

  x_labels <- region_op_labels(x, atlas$core, sf_data, match_on)
  y_labels <- region_op_labels(y, atlas$core, sf_data, match_on)

  result <- region_op_result(sf_data, x_labels, y_labels, action, into)
  if (is.null(result) || nrow(result) == 0) {
    cli::cli_abort("{.arg action} produced no geometry for {.val {into}}.")
  }

  new_sf <- rbind(sf_data[sf_data$label != into, , drop = FALSE], result)

  meta <- add_op_region_meta(atlas$core, atlas$palette, into, colour)
  new_core <- meta$core
  new_palette <- meta$palette

  # Context regions (not in core) draw behind core regions; keep that order.
  new_sf <- order_context_behind(new_sf, new_core$label)

  # Convert the sf result back to polygons so a polygon-only atlas keeps its
  # original representation (the op rehydrates to sf only for the GEOS engine).
  new_geom <- if (was_polygon_only) sf_to_polygons(new_sf) else new_sf
  new_data <- rebuild_data_with_geom(atlas$data, new_geom)
  validate_data_labels(new_data, new_core, check_sf = FALSE)
  structure(
    list(
      atlas = atlas$atlas,
      type = atlas$type,
      palette = new_palette,
      core = new_core,
      data = new_data
    ),
    class = class(atlas)
  )
}


#' @describeIn atlas_manipulation Drop all contextual sf geometry — every
#'   sf row whose `label` is not present in `core`. Covers labels marked
#'   via [atlas_region_contextual()] plus pipeline-generated outlines
#'   (`cortex_`, `Background`, `unknown`). Remaining views are re-packed
#'   via [atlas_view_gather()] so the plot focuses tightly on the
#'   labelled regions.
#' @export
#' @family atlas manipulations
atlas_context_remove <- function(atlas) {
  if (is.null(data_sf(atlas$data))) {
    if (is.null(data_poly(atlas$data))) {
      return(atlas)
    }
    new_poly <- polygons_keep_labels(data_poly(atlas$data), atlas$core$label)
    return(atlas_view_gather(set_atlas_polygons(atlas, new_poly)))
  }

  require_sf("atlas_context_remove()")
  keep_mask <- data_sf(atlas$data)$label %in% atlas$core$label
  new_sf <- data_sf(atlas$data)[keep_mask, , drop = FALSE]

  new_data <- rebuild_atlas_data(atlas, new_sf)
  atlas_view_gather(rebuild_atlas(atlas, new_data))
}


#' @describeIn atlas_manipulation Rename regions matching a pattern. Only
#'   ever writes to the `region` column, never to `label`. `match_on` chooses
#'   which column the pattern is matched and substituted against: the default
#'   `"region"` rewrites the display names in place, while `"label"` derives
#'   them from the source identifiers, so
#'   `atlas_region_rename(atlas, "^ctx-lh-", "", match_on = "label")` turns
#'   label `ctx-lh-superiorfrontal` into region `superiorfrontal`. If
#'   `replacement` is a function, it receives the matched values of that
#'   column and returns the new region names.
#' @export
#' @family atlas manipulations
atlas_region_rename <- function(
  atlas,
  pattern,
  replacement,
  match_on = c("region", "label")
) {
  match_on <- match.arg(match_on)

  new_core <- atlas$core
  source_values <- new_core[[match_on]]
  match_mask <- grepl(pattern, source_values, ignore.case = TRUE)
  match_mask[is.na(source_values)] <- FALSE

  if (is.function(replacement)) {
    new_core$region[match_mask] <- replacement(source_values[match_mask])
  } else {
    new_core$region[match_mask] <- gsub(
      pattern,
      replacement,
      source_values[match_mask],
      ignore.case = TRUE
    )
  }

  ggseg_atlas(
    atlas = atlas$atlas,
    type = atlas$type,
    palette = atlas$palette,
    core = new_core,
    data = atlas$data
  )
}


#' @describeIn atlas_manipulation Keep only matching regions. Non-matching
#'   regions are removed from core, palette, and 3D data but sf geometry
#'   is preserved for surface continuity.
#' @export
#' @family atlas manipulations
atlas_region_keep <- function(atlas, pattern, match_on = c("region", "label")) {
  match_on <- match.arg(match_on)

  match_col <- atlas$core[[match_on]]
  keep_mask <- grepl(pattern, match_col, ignore.case = TRUE)
  keep_mask[is.na(match_col)] <- FALSE

  labels_to_keep <- atlas$core$label[keep_mask]

  new_core <- atlas$core[keep_mask, , drop = FALSE]
  new_palette <- atlas$palette[names(atlas$palette) %in% labels_to_keep]

  new_data <- rebuild_data_with_geom(
    atlas$data,
    geom_from_data(atlas$data),
    keep_row = function(label) label %in% labels_to_keep
  )

  ggseg_atlas(
    atlas = atlas$atlas,
    type = atlas$type,
    palette = new_palette,
    core = new_core,
    data = new_data
  )
}


#' @describeIn atlas_manipulation Join additional metadata columns to
#'   atlas core.
#' @export
#' @family atlas manipulations
atlas_core_add <- function(atlas, data, by = "region") {
  if (anyDuplicated(do.call(paste, c(data[by], sep = "\r")))) {
    cli::cli_abort(c(
      "{.arg data} must have unique {.field {by}} values.",
      "i" = "Adding to atlas core may only add columns, never rows."
    ))
  }

  new_core <- df_left_join(atlas$core, data, by = by)

  ggseg_atlas(
    atlas = atlas$atlas,
    type = atlas$type,
    palette = atlas$palette,
    core = new_core,
    data = atlas$data
  )
}


# Atlas view manipulation ----

#' Get available views in atlas
#'
#' @param atlas A `ggseg_atlas` object
#' @return Character vector of view names, or NULL if no sf data
#' @examples
#' atlas_views(aseg())
#' atlas_views(tracula())
#'
#' @export
#' @family atlas accessors
atlas_views <- function(atlas) {
  if (!is.null(data_sf(atlas$data))) {
    return(unique(data_sf(atlas$data)$view))
  }
  if (!is.null(data_poly(atlas$data))) {
    return(unique(polygons_unnest(data_poly(atlas$data))$view))
  }
  NULL
}

#' @rdname atlas_views
#' @export
#' @family atlas accessors
brain_views <- function(atlas) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "brain_views()",
    "atlas_views()"
  )
  atlas_views(atlas)
}


#' @describeIn atlas_manipulation Remove views matching pattern from sf
#'   data. Remaining views are re-packed via [atlas_view_gather()] so
#'   the layout stays tight.
#' @export
#' @family atlas manipulations
atlas_view_remove <- function(atlas, views) {
  if (is.null(data_sf(atlas$data))) {
    if (is.null(data_poly(atlas$data))) {
      cli::cli_warn("Atlas has no 2D geometry, nothing to remove")
      return(atlas)
    }
    new_poly <- polygons_filter_view(data_poly(atlas$data), views, keep = FALSE)
    if (is.null(new_poly)) {
      cli::cli_warn("All views removed, 2D geometry will be NULL")
    }
    return(atlas_view_gather(set_atlas_polygons(atlas, new_poly)))
  }

  require_sf("atlas_view_remove()")
  pattern <- paste(views, collapse = "|")
  keep_mask <- !grepl(pattern, data_sf(atlas$data)$view, ignore.case = TRUE)
  new_sf <- data_sf(atlas$data)[keep_mask, , drop = FALSE]

  if (nrow(new_sf) == 0) {
    cli::cli_warn("All views removed, sf data will be NULL")
    new_sf <- NULL
  }

  new_data <- rebuild_atlas_data(atlas, new_sf)
  atlas_view_gather(rebuild_atlas(atlas, new_data))
}


#' @describeIn atlas_manipulation Keep only views matching pattern.
#' @export
#' @family atlas manipulations
atlas_view_keep <- function(atlas, views) {
  if (is.null(data_sf(atlas$data))) {
    if (is.null(data_poly(atlas$data))) {
      cli::cli_warn("Atlas has no 2D geometry, nothing to keep")
      return(atlas)
    }
    new_poly <- polygons_filter_view(data_poly(atlas$data), views, keep = TRUE)
    if (is.null(new_poly)) {
      cli::cli_warn("No views matched pattern, 2D geometry will be NULL")
    }
    return(set_atlas_polygons(atlas, new_poly))
  }

  pattern <- paste(views, collapse = "|")
  keep_mask <- grepl(pattern, data_sf(atlas$data)$view, ignore.case = TRUE)
  new_sf <- data_sf(atlas$data)[keep_mask, , drop = FALSE]

  if (nrow(new_sf) == 0) {
    cli::cli_warn("No views matched pattern, sf data will be NULL")
    new_sf <- NULL
  }

  new_data <- rebuild_atlas_data(atlas, new_sf)
  rebuild_atlas(atlas, new_data)
}


#' @describeIn atlas_manipulation Remove specific region geometry from sf
#'   data only. Core, palette, and 3D data are unchanged. Views are
#'   re-packed via [atlas_view_gather()] in case any view shrank.
#' @export
#' @family atlas manipulations
atlas_view_remove_region <- function(
  atlas,
  pattern,
  match_on = c("label", "region"),
  views = NULL
) {
  match_on <- match.arg(match_on)

  if (is.null(data_sf(atlas$data))) {
    return(view_remove_region_poly(atlas, pattern, match_on, views))
  }

  require_sf("atlas_view_remove_region()")

  if (match_on == "region") {
    match_col <- atlas$core$region
    hit <- grepl(pattern, match_col, ignore.case = TRUE) & !is.na(match_col)
    labels_to_remove <- atlas$core$label[hit]
    is_match <- data_sf(atlas$data)$label %in% labels_to_remove
  } else {
    is_match <- grepl(pattern, data_sf(atlas$data)$label, ignore.case = TRUE)
  }

  if (!is.null(views)) {
    view_pattern <- paste(views, collapse = "|")
    in_view <- grepl(view_pattern, data_sf(atlas$data)$view, ignore.case = TRUE)
    is_match <- is_match & in_view
  }

  is_match[is.na(data_sf(atlas$data)$label)] <- FALSE
  new_sf <- data_sf(atlas$data)[!is_match, , drop = FALSE]

  if (nrow(new_sf) == 0) {
    cli::cli_warn("All region geometries removed, sf data will be NULL")
    new_sf <- NULL
  }

  new_data <- rebuild_atlas_data(atlas, new_sf)
  atlas_view_gather(rebuild_atlas(atlas, new_data))
}


#' @describeIn atlas_manipulation Remove geometry below a minimum area
#'   threshold. With `scope = "region"` (the default) a label's whole geometry
#'   in a view is removed when its combined area is too small, and context
#'   geometries (labels not in core) are never removed. With
#'   `scope = "piece"` individual disconnected pieces are removed while the
#'   rest of the region stays -- use this to clear stray specks left by
#'   volumetric projection. A region's largest piece in a view is always kept,
#'   so no region disappears, and context is cleaned too. Optionally scope to
#'   specific views. Views are re-packed via [atlas_view_gather()] in case any
#'   view shrank.
#' @param scope Whether `min_area` applies to a label's whole geometry in a
#'   view (`"region"`, the default) or to each disconnected piece
#'   (`"piece"`).
#' @param labels,exclude For `atlas_view_remove_small()`: optional regex
#'   scoping which labels are considered. `labels` restricts removal to
#'   matching labels, `exclude` spares them. Only one may be given. Useful
#'   with `scope = "piece"`, where a thin structure such as a cortical ribbon
#'   has legitimately small pieces that should not be treated as specks.
#' @export
#' @family atlas manipulations
atlas_view_remove_small <- function(
  atlas,
  min_area,
  views = NULL,
  scope = c("region", "piece"),
  labels = NULL,
  exclude = NULL
) {
  scope <- match.arg(scope)

  if (!is.null(labels) && !is.null(exclude)) {
    cli::cli_abort(
      "Specify only one of {.arg labels} or {.arg exclude}, not both."
    )
  }

  if (identical(scope, "piece")) {
    return(remove_small_pieces(atlas, min_area, views, labels, exclude))
  }

  if (is.null(data_sf(atlas$data))) {
    if (is.null(data_poly(atlas$data))) {
      cli::cli_warn("Atlas has no 2D geometry, nothing to remove")
      return(atlas)
    }
    res <- polygons_remove_small(
      data_poly(atlas$data),
      min_area,
      core_labels = atlas$core$label,
      views = views
    )
    if (res$n_removed > 0) {
      cli::cli_alert_info(
        "Removed {res$n_removed} geometr{?y/ies} below area {min_area}"
      )
    }
    return(atlas_view_gather(set_atlas_polygons(atlas, res$polygons)))
  }

  require_sf("atlas_view_remove_small()")
  areas <- as.numeric(sf::st_area(data_sf(atlas$data)$geometry))
  is_context <- is.na(data_sf(atlas$data)$label) |
    !data_sf(atlas$data)$label %in% atlas$core$label
  is_small <- areas < min_area & !is_context

  if (!is.null(views)) {
    pattern <- paste(views, collapse = "|")
    in_view <- grepl(pattern, data_sf(atlas$data)$view, ignore.case = TRUE)
    is_small <- is_small & in_view
  }

  n_removed <- sum(is_small)
  if (n_removed > 0) {
    cli::cli_alert_info(
      "Removed {n_removed} geometr{?y/ies} below area {min_area}"
    )
  }

  new_sf <- data_sf(atlas$data)[!is_small, , drop = FALSE]
  new_data <- rebuild_atlas_data(atlas, new_sf)
  atlas_view_gather(rebuild_atlas(atlas, new_data))
}


#' @describeIn atlas_manipulation Keep each region only in the views that show
#'   it well.
#'
#'   A slice or projection slab catches a structure in cross-section as readily
#'   as along its length, so most regions leave a sliver in most views. That
#'   leaves every panel cluttered and every region drawn several times over. A
#'   region is kept only where it is substantially represented: in any view
#'   holding at least `threshold` of the area it reaches in its best view.
#'
#'   Regions are compared as a whole, across all the labels that share a
#'   `region` in `core`, so bilateral structures stay together -- assigning
#'   left and right independently splits pairs across panels, which reads as
#'   an error rather than a choice. Every region is guaranteed to survive in
#'   at least one view, and context geometry (labels absent from `core`, such
#'   as a cortical outline) is never touched.
#'
#'   Single-hemisphere views are the awkward case: a sagittal panel cuts one
#'   hemisphere while axial and coronal panels show both, so on raw area it
#'   loses every comparison and empties out. Such views are detected from the
#'   hemispheres actually present in each view and their areas scaled to
#'   match, so they compete fairly. Pass `weights` to override.
#' @param threshold For `atlas_view_select()`: minimum share, between 0 and 1,
#'   of a region's best-view area that a view must hold to keep drawing it.
#'   Higher values are more aggressive.
#' @param weights For `atlas_view_select()`: optional named numeric vector of
#'   per-view multipliers applied before comparing areas. Overrides the
#'   automatic hemisphere-coverage weighting for the views named.
#' @export
atlas_view_select <- function(
  atlas,
  threshold = 0.5,
  weights = NULL
) {
  check_select_threshold(threshold)

  polygons <- atlas_polygons(atlas)
  if (is.null(polygons)) {
    cli::cli_warn("Atlas has no 2D geometry, nothing to select")
    return(atlas)
  }

  flat <- polygons_unnest(polygons)
  flat <- flat[flat$label %in% atlas$core$label, , drop = FALSE]
  if (!nrow(flat)) {
    cli::cli_warn("Atlas has no core geometry, nothing to select")
    return(atlas)
  }

  view_names <- atlas_views(atlas)
  keep <- view_selection_matrix(atlas, flat, view_names, threshold, weights)
  atlas <- apply_view_selection(atlas, keep, view_names)

  cli::cli_alert_info(
    "Regions drawn per view: \\
     {paste(view_names, colSums(keep), sep = '=', collapse = ', ')}"
  )

  atlas_view_gather(atlas)
}


#' @describeIn atlas_manipulation Reposition remaining views to close gaps
#'   after view removal.
#' @export
#' @family atlas manipulations
atlas_view_gather <- function(atlas, gap = 0.15) {
  sf_data <- data_sf(atlas$data)
  if (is.null(sf_data)) {
    return(gather_without_sf(atlas, gap))
  }
  if (!inherits(sf_data, "sf") || nrow(sf_data) == 0) {
    return(atlas)
  }

  new_sf <- reposition_views(sf_data, type = atlas$type, gap = gap)
  # nocov start: reposition_views always returns sf for non-empty sf input;
  # this guards a broken contract and cannot be reached in normal use.
  if (is.null(new_sf) || !inherits(new_sf, "sf")) {
    return(atlas)
  }
  # nocov end
  new_data <- rebuild_atlas_data(atlas, new_sf)
  rebuild_atlas(atlas, new_data)
}


#' @describeIn atlas_manipulation Reorder views and reposition. Views not
#'   in `order` are appended at end.
#' @export
#' @family atlas manipulations
atlas_view_reorder <- function(atlas, order, gap = 0.15) {
  if (is.null(data_sf(atlas$data))) {
    return(view_reorder_poly(atlas, order, gap))
  }

  sf_data <- data_sf(atlas$data)
  current_views <- unique(sf_data$view)

  missing_from_order <- setdiff(current_views, order)
  if (length(missing_from_order) > 0) {
    order <- c(order, missing_from_order)
  }

  order <- order[order %in% current_views]

  if (length(order) == 0) {
    cli::cli_warn("No matching views found in order specification")
    return(atlas)
  }

  group_order <- view_reorder_group_order(sf_data, order, atlas$type)

  new_sf <- reposition_views(
    sf_data,
    type = atlas$type,
    gap = gap,
    group_order = group_order
  )
  new_data <- rebuild_atlas_data(atlas, new_sf)
  rebuild_atlas(atlas, new_data)
}


#' @keywords internal
#' @noRd
get_uniq <- function(x, type) {
  type <- match.arg(type, c("label", "region"))
  x <- unique(x[[type]])
  x <- x[!is.na(x)]
  sort(x)
}

#' @noRd
#' @keywords internal
guess_type <- function(x) {
  if ("type" %in% names(x) && !is.na(x$type[1])) {
    return(unique(x$type))
  }

  cli::cli_warn("Atlas type not set, attempting to guess type.")

  # Modern atlases keep 2D geometry in `$data` (sf or polygons); `atlas_views()`
  # reads either. Fall back to the legacy bare `$sf` slot, then to a plain
  # data.frame's own `view` column.
  views <- if (inherits(x$data, "ggseg_atlas_data")) {
    atlas_views(x)
  } else if (!is.null(x$sf)) {
    x$sf$view
  } else if ("view" %in% names(x)) {
    x$view
  } else {
    character(0)
  }

  if (any(grepl("medial|lateral", views))) {
    "cortical"
  } else {
    "subcortical"
  }
}


#' Move contextual geometry rows behind core rows
#'
#' 2D geometry is drawn in row order, so contextual (non-core) regions must
#' come first to render behind the core regions they may overlap. Stable
#' within each group, preserving existing view order. Works on either an sf
#' data.frame (one row per label/view) or a `brain_polygons` data.frame (one row
#' per label) — both carry a `label` column — so reordering needs no sf.
#'
#' @param geom An sf data.frame, a `brain_polygons` data.frame, or NULL.
#' @param core_labels Character vector of labels still present in core.
#' @return Reordered geometry of the same class, or NULL if `geom` is NULL.
#' @noRd
order_context_behind <- function(geom, core_labels) {
  if (is.null(geom) || nrow(geom) == 0) {
    return(geom)
  }
  is_core <- geom$label %in% core_labels
  geom[c(which(!is_core), which(is_core)), , drop = FALSE]
}


#' sf geometry for a region op, rehydrating a polygon-only atlas
#' Returns a list with the sf geometry and `was_polygon_only` (whether the
#' atlas had no native sf and was rehydrated from polygons).
#' @noRd
#' @keywords internal
region_op_sf_data <- function(data) {
  sf_data <- data_sf(data)
  was_polygon_only <- is.null(sf_data)
  if (was_polygon_only) {
    poly <- data_poly(data)
    if (is.null(poly)) {
      cli::cli_abort("Atlas has no 2D geometry to operate on.")
    }
    sf_data <- polygons_to_sf(poly)
  }
  list(sf_data = sf_data, was_polygon_only = was_polygon_only)
}


#' Map a boolean action to its sf combiner
#' @noRd
#' @keywords internal
region_op_combine <- function(action) {
  switch(
    action,
    difference = sf::st_difference,
    intersection = sf::st_intersection,
    union = function(a, b) sf::st_union(c(a, b)),
    symdifference = sf::st_sym_difference
  )
}


#' Apply a boolean region op within a single view
#'
#' `op` bundles the loop-invariant inputs assembled by [atlas_region_op()]:
#' `sf_data`, `geom_col`, `x_labels`, `y_labels`, `combine`, `action`,
#' `template`, `into`. Returns a one-row sf result for view `v`, or `NULL` when
#' there is no `x` geometry in the view or the op yields empty geometry.
#' @noRd
#' @keywords internal
region_op_view <- function(v, op) {
  in_view <- op$sf_data$view == v
  gx <- op$sf_data[[op$geom_col]][in_view & op$sf_data$label %in% op$x_labels]
  gy <- op$sf_data[[op$geom_col]][in_view & op$sf_data$label %in% op$y_labels]
  if (length(gx) == 0) {
    return(NULL)
  }
  gx <- sf::st_union(sf::st_make_valid(gx))
  geom <- if (length(gy) > 0) {
    op$combine(gx, sf::st_union(sf::st_make_valid(gy)))
  } else if (op$action == "intersection") {
    gx[0]
  } else {
    gx
  }
  geom <- sf::st_make_valid(geom)
  if (length(geom) == 0 || all(sf::st_is_empty(geom))) {
    return(NULL)
  }
  row <- op$template[1, , drop = FALSE]
  row$label <- op$into
  row$view <- v
  geom <- sf::st_union(geom)
  sf::st_crs(geom) <- sf::st_crs(op$sf_data)
  sf::st_geometry(row) <- geom
  row
}


#' Add a result region to `core`/`palette` when a colour is given
#' @noRd
#' @keywords internal
add_op_region_meta <- function(core, palette, into, colour) {
  if (is.null(colour)) {
    return(list(core = core, palette = palette))
  }
  if (!into %in% core$label) {
    core_row <- core[1, , drop = FALSE]
    core_row[] <- NA
    core_row$label <- into
    if ("region" %in% names(core_row)) {
      core_row$region <- into
    }
    core <- rbind(core, core_row)
  }
  palette[[into]] <- colour
  list(core = core, palette = palette)
}


#' Gather an atlas that has no sf geometry
#'
#' Repositions the polygon representation when present; otherwise warns. Used
#' by [atlas_view_gather()]. Returns the (possibly unchanged) atlas.
#' @noRd
#' @keywords internal
gather_without_sf <- function(atlas, gap) {
  poly <- data_poly(atlas$data)
  if (!is.null(poly)) {
    new_poly <- reposition_polygons(poly, type = atlas$type, gap = gap)
    return(set_atlas_polygons(atlas, new_poly))
  }
  cli::cli_warn("Atlas has no 2D geometry")
  atlas
}


#' @param group_order Optional explicit left-to-right ordering of the
#'   view (or hemi+view) groups. When `NULL`, groups are ordered by their
#'   current centroid x so the packed layout is independent of row order
#'   (and therefore identical for sf and polygon representations).
#' @keywords internal
#' @noRd
reposition_views <- function(
  sf_obj,
  type = NULL,
  gap = 0.15,
  group_order = NULL
) {
  if (!inherits(sf_obj, "sf") && !inherits(sf_obj, "data.frame")) {
    return(sf_obj)
  }
  if (is.null(sf_obj) || nrow(sf_obj) == 0) {
    return(sf_obj)
  }

  require_sf("reposition_views()")

  if (inherits(sf_obj$geometry, "sfc_GEOMETRY")) {
    sf_obj <- sf::st_cast(sf_obj, "MULTIPOLYGON")
  }

  group_key <- sf_obj$view

  if (identical(type, "cortical")) {
    hemi <- hemi_from_label(sf_obj$label)
    group_key <- paste(hemi, sf_obj$view)
  }

  groups <- order_view_groups(
    group_key,
    group_order,
    centroid_x = function(g) {
      bbox <- sf::st_bbox(sf_obj$geometry[group_key == g])
      unname((bbox[["xmin"]] + bbox[["xmax"]]) / 2)
    }
  )

  view_data <- lapply(groups, function(g) {
    center_view_geometry(sf_obj[group_key == g, ])
  })

  view_data <- pack_views_horizontally(view_data, gap)

  result <- do.call(rbind, view_data)
  sf::st_as_sf(result)
}


#' Rebuild an atlas data object around a single new 2D geometry
#'
#' Stores `geom` (an sf or `brain_polygons` object, or NULL) in the unified
#' `geom` slot, preserving the 3D payload and clearing any legacy `sf` /
#' `polygons` slots so no redundant representation lingers.
#' @keywords internal
#' @noRd
rebuild_data_with_geom <- function(data, geom, keep_row = NULL) {
  filt <- function(df) {
    if (is.null(df) || is.null(keep_row)) {
      return(df)
    }
    df[keep_row(df$label), , drop = FALSE]
  }
  if (!is.null(data$vertices) && !is.null(data$meshes)) {
    ggseg_data_cerebellar(
      geom = geom,
      vertices = filt(data$vertices),
      meshes = filt(data$meshes)
    )
  } else if (!is.null(data$vertices)) {
    if (inherits(data, "ggseg_data_cerebellar")) {
      ggseg_data_cerebellar(geom = geom, vertices = filt(data$vertices))
    } else {
      ggseg_data_cortical(geom = geom, vertices = filt(data$vertices))
    }
  } else if (!is.null(data$meshes)) {
    ggseg_data_subcortical(geom = geom, meshes = filt(data$meshes))
  } else if (!is.null(data$centerlines)) {
    ggseg_data_tract(geom = geom, centerlines = filt(data$centerlines))
  } else {
    new_data <- data
    new_data$geom <- geom
    new_data$sf <- NULL
    new_data$polygons <- NULL
    new_data
  }
}

#' @keywords internal
#' @noRd
rebuild_atlas_data <- function(atlas, new_sf) {
  rebuild_data_with_geom(atlas$data, new_sf)
}

#' Swap in new polygon geometry on a polygon-only atlas
#'
#' Used by the sf-free view helpers. Stores `new_polygons` in the unified
#' `geom` slot and leaves the 3D payload untouched; `new_polygons` may be NULL
#' when all geometry was removed.
#' @noRd
#' @keywords internal
set_atlas_polygons <- function(atlas, new_polygons) {
  rebuild_atlas(atlas, rebuild_data_with_geom(atlas$data, new_polygons))
}

#' @noRd
#' @keywords internal
rebuild_atlas <- function(atlas, new_data) {
  validate_data_labels(new_data, atlas$core, check_sf = FALSE)

  structure(
    list(
      atlas = atlas$atlas,
      type = atlas$type,
      palette = atlas$palette,
      core = atlas$core,
      data = new_data
    ),
    class = c(
      paste0(atlas$type, "_atlas"),
      "ggseg_atlas",
      "list"
    )
  )
}


#' Classify hemisphere from an `lh_`/`rh_` label prefix
#'
#' Shared by the reposition/reorder helpers, which group cortical geometry by
#' hemisphere. Labels matching neither prefix get `default`.
#' @noRd
#' @keywords internal
hemi_from_label <- function(label, default = "") {
  out <- rep(default, length(label))
  out[grepl("^lh[_.]", label)] <- "left"
  out[grepl("^rh[_.]", label)] <- "right"
  out
}


#' Resolve an `atlas_region_op()` operand pattern to labels
#'
#' Region matches use the core `region` column; label matches grep the sf
#' labels directly. Extracted from [atlas_region_op()].
#' @noRd
#' @keywords internal
region_op_labels <- function(pattern, core, sf_data, match_on) {
  if (match_on == "region") {
    hit <- grepl(pattern, core$region, ignore.case = TRUE) &
      !is.na(core$region)
    core$label[hit]
  } else {
    unique(grep(pattern, sf_data$label, ignore.case = TRUE, value = TRUE))
  }
}


#' Build the combined-geometry rows for an `atlas_region_op()`
#'
#' Bundles the loop-invariant op inputs and runs `region_op_view()` across
#' every view, returning the row-bound sf result (or NULL when empty).
#' Extracted from [atlas_region_op()].
#' @noRd
#' @keywords internal
region_op_result <- function(sf_data, x_labels, y_labels, action, into) {
  op <- list(
    sf_data = sf_data,
    geom_col = attr(sf_data, "sf_column"),
    x_labels = x_labels,
    y_labels = y_labels,
    combine = region_op_combine(action),
    action = action,
    template = sf_data[sf_data$label %in% x_labels, , drop = FALSE][
      0,
      ,
      drop = FALSE
    ],
    into = into
  )
  result_rows <- lapply(unique(sf_data$view), region_op_view, op)
  do.call(rbind, result_rows)
}


#' Remove region geometry from a polygon-only atlas
#'
#' The sf-free branch of [atlas_view_remove_region()]: resolves labels to
#' drop, removes them from the polygon representation, and re-packs views.
#' @noRd
#' @keywords internal
view_remove_region_poly <- function(atlas, pattern, match_on, views) {
  if (is.null(data_poly(atlas$data))) {
    cli::cli_warn("Atlas has no 2D geometry, nothing to remove")
    return(atlas)
  }
  poly_labels <- data_poly(atlas$data)$label
  if (match_on == "region") {
    hit <- grepl(pattern, atlas$core$region, ignore.case = TRUE) &
      !is.na(atlas$core$region)
    drop_labels <- atlas$core$label[hit]
  } else {
    drop_labels <- poly_labels[grepl(pattern, poly_labels, ignore.case = TRUE)]
  }
  new_poly <- polygons_remove_region(
    data_poly(atlas$data),
    drop_labels,
    views = views
  )
  if (is.null(new_poly)) {
    cli::cli_warn("All region geometries removed, 2D geometry will be NULL")
  }
  atlas_view_gather(set_atlas_polygons(atlas, new_poly))
}


#' Reorder views on a polygon-only atlas
#'
#' The sf-free branch of [atlas_view_reorder()]: warns when no requested view
#' matches, then reorders and re-packs the polygon representation.
#' @noRd
#' @keywords internal
view_reorder_poly <- function(atlas, order, gap) {
  if (is.null(data_poly(atlas$data))) {
    cli::cli_warn("Atlas has no 2D geometry")
    return(atlas)
  }
  current_views <- unique(polygons_unnest(data_poly(atlas$data))$view)
  if (!any(order %in% current_views)) {
    cli::cli_warn("No matching views found in order specification")
  }
  new_poly <- reorder_polygons(
    data_poly(atlas$data),
    order,
    type = atlas$type,
    gap = gap
  )
  set_atlas_polygons(atlas, new_poly)
}


#' Expand a requested view order into reposition group keys
#'
#' For cortical atlases the packed groups are hemi+view, so each requested
#' view expands into its present hemispheres in left/right order. Other types
#' use the view order as-is. Extracted from [atlas_view_reorder()].
#' @noRd
#' @keywords internal
view_reorder_group_order <- function(sf_data, order, type) {
  if (!identical(type, "cortical")) {
    return(order)
  }
  hemi <- hemi_from_label(sf_data$label)
  unlist(lapply(order, function(v) {
    hemis <- intersect(
      c("left", "right", ""),
      unique(hemi[sf_data$view == v])
    )
    paste(hemis, v)
  }))
}


#' Centre a single view's geometry on the origin
#'
#' Shifts a view's sf rows so their bounding-box centre sits at `(0, 0)`,
#' the per-group step of `reposition_views()`.
#' @noRd
#' @keywords internal
center_view_geometry <- function(df) {
  bbox <- sf::st_bbox(df$geometry)
  center_x <- (bbox["xmin"] + bbox["xmax"]) / 2
  center_y <- (bbox["ymin"] + bbox["ymax"]) / 2
  df$geometry <- df$geometry - c(center_x, center_y)
  df
}


#' Pack origin-centred views left-to-right with a proportional gap
#'
#' Takes the centred per-view sf data from `reposition_views()` and offsets
#' each so the views sit side by side, top-aligned, separated by `gap` times
#' the widest view's width.
#' @noRd
#' @keywords internal
pack_views_horizontally <- function(view_data, gap) {
  ranges <- lapply(view_data, function(df) {
    coords <- sf::st_coordinates(df$geometry)
    list(x_range = range(coords[, 1]), y_range = range(coords[, 2]))
  })

  widths <- vapply(ranges, function(r) diff(r$x_range), numeric(1))
  half_widths <- vapply(ranges, function(r) max(abs(r$x_range)), numeric(1))
  max_height <- max(vapply(ranges, function(r) max(abs(r$y_range)), numeric(1)))
  gap_size <- max(widths) * gap

  # Running x position of each view's left edge is a prefix sum of preceding
  # widths plus gaps; offset each view to its packed centre.
  x_left <- cumsum(c(0, widths + gap_size))[seq_along(view_data)]
  x_offsets <- x_left + half_widths
  Map(
    function(view, x_offset) {
      view$geometry <- view$geometry + c(x_offset, max_height)
      view
    },
    view_data,
    x_offsets
  )
}


atlas_types <- function() {
  c("cortical", "subcortical", "tract", "cerebellar")
}


#' Scale each view by how much of the brain it can possibly show
#'
#' A view that cuts a single hemisphere can never match a bilateral view on
#' area, so on raw comparison it loses every region. Weight each view by the
#' reciprocal of the hemisphere share it covers, measured from the geometry
#' itself rather than assumed from the view's name.
#' @noRd
view_hemisphere_weights <- function(atlas, flat, view_names, weights) {
  hemi <- atlas$core$hemi[match(flat$label, atlas$core$label)]
  lateral <- hemi %in% c("left", "right")
  n_hemi <- vapply(
    view_names,
    function(v) {
      seen <- unique(hemi[lateral & flat$view == v])
      max(length(seen), 1L)
    },
    integer(1)
  )
  auto <- max(n_hemi) / n_hemi

  if (!is.null(weights)) {
    if (is.null(names(weights))) {
      cli::cli_abort("{.arg weights} must be a named numeric vector.")
    }
    unknown <- setdiff(names(weights), view_names)
    if (length(unknown)) {
      cli::cli_abort("Unknown view{?s} in {.arg weights}: {.val {unknown}}.")
    }
    auto[names(weights)] <- weights
  }

  auto
}


#' Remove disconnected pieces below an area threshold
#'
#' Piece-level counterpart of [atlas_view_remove_small()]. sf atlases are
#' routed through the polygon representation, which is where piece geometry is
#' explicit, and converted back afterwards.
#' @noRd
#' @keywords internal
remove_small_pieces <- function(
  atlas,
  min_area,
  views = NULL,
  labels = NULL,
  exclude = NULL
) {
  if (is.null(data_poly(atlas$data)) && is.null(data_sf(atlas$data))) {
    cli::cli_warn("Atlas has no 2D geometry, nothing to remove")
    return(atlas)
  }

  was_sf <- is.null(data_poly(atlas$data))
  work <- if (was_sf) as_polygon_atlas(atlas) else atlas

  res <- polygons_remove_small_pieces(
    data_poly(work$data),
    min_area,
    views = views,
    labels = labels,
    exclude = exclude
  )
  if (res$n_removed > 0) {
    cli::cli_alert_info(
      "Removed {res$n_removed} piece{?s} below area {min_area}"
    )
  }

  out <- atlas_view_gather(set_atlas_polygons(work, res$polygons))
  if (was_sf) as_sf_atlas(out) else out
}


#' Validate the `threshold` argument of [atlas_view_select()]
#' @noRd
check_select_threshold <- function(threshold) {
  if (
    !rlang::is_scalar_double(threshold) && !rlang::is_scalar_integer(threshold)
  ) {
    cli::cli_abort("{.arg threshold} must be a single number.")
  }
  if (threshold < 0 || threshold > 1) {
    cli::cli_abort("{.arg threshold} must be between 0 and 1.")
  }
  invisible(threshold)
}


#' Decide, per label and view, whether that label is drawn there
#'
#' Labels are compared within their `core$region`, so a bilateral structure's
#' left and right sides are selected together rather than competing.
#' @return Logical matrix, labels by views.
#' @noRd
view_selection_matrix <- function(atlas, flat, view_names, threshold, weights) {
  areas <- polygon_geometry_areas(flat)

  area_by_view <- tapply(areas$area, list(areas$label, areas$view), sum)
  area_by_view <- area_by_view[, view_names, drop = FALSE]
  area_by_view[is.na(area_by_view)] <- 0

  weights <- view_hemisphere_weights(atlas, flat, view_names, weights)

  region <- atlas$core$region[match(rownames(area_by_view), atlas$core$label)]
  region[is.na(region)] <- rownames(area_by_view)[is.na(region)]

  region_area <- rowsum(area_by_view, region)
  region_area <- sweep(region_area, 2, weights, `*`)
  region_keep <- region_area >= threshold * apply(region_area, 1, max)

  keep <- region_keep[region, , drop = FALSE] & area_by_view > 0
  dimnames(keep) <- dimnames(area_by_view)

  # A region's chosen views can hold no geometry for one of its labels -- a
  # sagittal plane is one-sided, so the other hemisphere's label would vanish
  # entirely. Fall back to wherever that label is largest.
  empty <- rowSums(keep) == 0
  for (i in which(empty)) {
    keep[i, which.max(area_by_view[i, ])] <- TRUE
  }

  keep
}


#' Drop each label from the views its selection matrix rules out
#' @noRd
apply_view_selection <- function(atlas, keep, view_names) {
  for (label in rownames(keep)) {
    drop_views <- view_names[!keep[label, ]]
    if (length(drop_views)) {
      atlas <- atlas_view_remove_region(
        atlas,
        paste0("^", label, "$"),
        match_on = "label",
        views = drop_views
      )
    }
  }
  atlas
}
