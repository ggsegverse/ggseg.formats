# Pure-R polygon view operations ----
#
# Filtering, area, and repositioning on the `brain_polygons` representation,
# implemented without sf so the atlas-view helpers work on polygon-only
# atlases (no GDAL/GEOS/PROJ). All operate on the flat coordinate table
# (`label`, `view`, `x`, `y`, `group`, `subgroup`) obtained by unnesting.

#' Determine the left-to-right ordering of view groups for repositioning
#'
#' When `group_order` is supplied (e.g. by reorder) it wins, filtered to the
#' groups actually present. Otherwise groups are ordered by their current
#' centroid x (ties broken by group name), which depends only on coordinates —
#' not on row order — so sf and `brain_polygons` inputs pack identically.
#'
#' @param group_key Per-row group assignment (view, or hemi+view).
#' @param group_order Optional explicit ordering, or NULL.
#' @param centroid_x Function mapping a group value to its centroid x.
#' @return Character vector of group values in left-to-right order.
#' @noRd
#' @keywords internal
order_view_groups <- function(group_key, group_order, centroid_x) {
  if (!is.null(group_order)) {
    return(group_order[group_order %in% group_key])
  }
  uniq <- unique(group_key)
  cx <- vapply(uniq, centroid_x, numeric(1))
  uniq[order(cx, uniq)]
}


#' Unnest a brain_polygons to its flat coordinate table
#' @noRd
#' @keywords internal
polygons_unnest <- function(polygons) {
  df_unnest(as_tbl(polygons), "geometry")
}


#' Re-nest a flat coordinate table back into brain_polygons
#'
#' Keeps only the canonical columns and nests by `label`. Returns NULL for an
#' empty table so callers can treat "all geometry removed" as no 2D data.
#' @noRd
#' @keywords internal
polygons_renest <- function(flat) {
  if (is.null(flat) || nrow(flat) == 0) {
    return(NULL)
  }
  flat <- flat[, c("label", "view", "x", "y", "group", "subgroup")]
  out <- df_nest(as_tbl(flat), "label", "geometry")
  structure(out, class = unique(c("brain_polygons", class(out))))
}


#' Keep only the given labels
#' @noRd
#' @keywords internal
polygons_keep_labels <- function(polygons, keep) {
  flat <- polygons_unnest(polygons)
  polygons_renest(flat[flat$label %in% keep, , drop = FALSE])
}


#' Drop labels matching a regex pattern
#' @noRd
#' @keywords internal
polygons_drop_pattern <- function(polygons, pattern) {
  flat <- polygons_unnest(polygons)
  drop <- grepl(pattern, flat$label, ignore.case = TRUE)
  polygons_renest(flat[!drop, , drop = FALSE])
}


#' Filter geometry by view pattern (keep or remove the matches)
#' @noRd
#' @keywords internal
polygons_filter_view <- function(polygons, views, keep) {
  flat <- polygons_unnest(polygons)
  pattern <- paste(views, collapse = "|")
  match <- grepl(pattern, flat$view, ignore.case = TRUE)
  polygons_renest(flat[if (keep) match else !match, , drop = FALSE])
}


#' Remove geometry for a set of labels, optionally scoped to views
#' @noRd
#' @keywords internal
polygons_remove_region <- function(polygons, drop_labels, views = NULL) {
  flat <- polygons_unnest(polygons)
  is_match <- flat$label %in% drop_labels
  if (!is.null(views)) {
    view_pattern <- paste(views, collapse = "|")
    is_match <- is_match & grepl(view_pattern, flat$view, ignore.case = TRUE)
  }
  polygons_renest(flat[!is_match, , drop = FALSE])
}


#' Drop labels matching a pattern from either geometry representation
#'
#' Class-dispatching wrapper: `brain_polygons` go through
#' `polygons_drop_pattern()` (sf-free), sf geometry is row-filtered on `label`.
#' @noRd
#' @keywords internal
#' Whether any geometry row's label matches a pattern
#'
#' Geometry carries labels core does not -- the context outlines a pipeline
#' draws behind the regions -- so "nothing matched" has to consult both.
#' @noRd
geom_matches_pattern <- function(geom, pattern) {
  if (is.null(geom)) {
    return(FALSE)
  }
  labels <- if (inherits(geom, "brain_polygons")) {
    polygons_unnest(geom)$label
  } else {
    geom$label
  }
  any(grepl(pattern, labels, ignore.case = TRUE))
}


geom_drop_pattern <- function(geom, pattern) {
  if (is.null(geom)) {
    return(NULL)
  }
  if (inherits(geom, "brain_polygons")) {
    return(polygons_drop_pattern(geom, pattern))
  }
  geom[!grepl(pattern, geom$label, ignore.case = TRUE), , drop = FALSE]
}


#' Shoelace area of a single ring
#' @noRd
#' @keywords internal
polygon_ring_area <- function(x, y) {
  n <- length(x)
  if (n < 3) {
    return(0)
  }
  abs(sum(x * c(y[-1], y[1]) - c(x[-1], x[1]) * y)) / 2
}


#' Area per label x view (exterior minus holes, summed over disjoint pieces)
#'
#' Mirrors `sf::st_area()` on each MULTIPOLYGON row: within a `group` the
#' lowest `subgroup` is the exterior ring and the rest are holes.
#' @noRd
#' @keywords internal
polygon_geometry_areas <- function(flat) {
  lv <- unique(flat[, c("label", "view")])
  ring_area_of <- function(piece, ring) {
    idx <- piece$subgroup == ring
    polygon_ring_area(piece$x[idx], piece$y[idx])
  }
  lv$area <- vapply(
    seq_len(nrow(lv)),
    function(k) {
      sub <- flat[flat$label == lv$label[k] & flat$view == lv$view[k], ]
      sum(vapply(
        unique(sub$group),
        function(g) {
          piece <- sub[sub$group == g, ]
          rings <- unique(piece$subgroup)
          ext <- min(rings)
          holes <- setdiff(rings, ext)
          a_holes <- sum(vapply(
            holes,
            function(r) ring_area_of(piece, r),
            numeric(1)
          ))
          ring_area_of(piece, ext) - a_holes
        },
        numeric(1)
      ))
    },
    numeric(1)
  )
  lv
}


#' Drop region geometries below an area threshold
#'
#' Context geometries (labels not in `core_labels`) are never removed.
#' Returns a list of the new polygons and the count of geometries removed.
#' @noRd
#' @keywords internal
polygons_remove_small <- function(
  polygons,
  min_area,
  core_labels,
  views = NULL
) {
  flat <- polygons_unnest(polygons)
  areas <- polygon_geometry_areas(flat)

  is_small <- areas$area < min_area & areas$label %in% core_labels
  if (!is.null(views)) {
    view_pattern <- paste(views, collapse = "|")
    is_small <- is_small &
      grepl(view_pattern, areas$view, ignore.case = TRUE)
  }
  small <- areas[is_small, c("label", "view"), drop = FALSE]

  flat_key <- paste(flat$label, flat$view, sep = "\r")
  small_key <- paste(small$label, small$view, sep = "\r")
  kept <- flat[!flat_key %in% small_key, , drop = FALSE]

  list(polygons = polygons_renest(kept), n_removed = nrow(small))
}


#' Drop disconnected pieces below an area threshold
#'
#' Unlike [polygons_remove_small()], which drops a label's whole geometry in a
#' view when its combined area is too small, this drops individual disconnected
#' pieces and keeps the rest of the region. A region's largest piece in a view
#' is always kept, so no region can disappear. Holes are not treated as pieces:
#' a piece's area is its exterior ring minus its holes.
#'
#' @param polygons A `brain_polygons` table.
#' @param min_area Pieces below this area are dropped.
#' @param views Optional character vector of view name patterns to scope to.
#' @return List with the new polygons and the count of pieces removed.
#' @noRd
#' @keywords internal
polygons_remove_small_pieces <- function(
  polygons,
  min_area,
  views = NULL,
  labels = NULL,
  exclude = NULL
) {
  flat <- polygons_unnest(polygons)
  if (nrow(flat) == 0) {
    return(list(polygons = polygons, n_removed = 0L))
  }

  piece_key <- paste(flat$label, flat$view, flat$group, sep = "\r")
  areas <- vapply(
    split(flat, piece_key),
    function(d) {
      rings <- unique(d$subgroup)
      ext <- min(rings)
      ring_area <- function(r) {
        idx <- d$subgroup == r
        polygon_ring_area(d$x[idx], d$y[idx])
      }
      ring_area(ext) - sum(vapply(setdiff(rings, ext), ring_area, numeric(1)))
    },
    numeric(1)
  )

  region_key <- vapply(
    strsplit(names(areas), "\r", fixed = TRUE),
    function(p) {
      paste(p[1:2], collapse = "\r")
    },
    character(1)
  )

  # Never drop a region's largest piece in a view, so nothing vanishes.
  largest <- tapply(areas, region_key, max)[region_key]
  drop <- areas < min_area & areas < largest

  if (!is.null(views)) {
    view_of <- vapply(
      strsplit(names(areas), "\r", fixed = TRUE),
      `[`,
      character(1),
      2
    )
    drop <- drop &
      grepl(paste(views, collapse = "|"), view_of, ignore.case = TRUE)
  }

  if (!is.null(labels) || !is.null(exclude)) {
    label_of <- vapply(
      strsplit(names(areas), "\r", fixed = TRUE),
      `[`,
      character(1),
      1
    )
    in_scope <- if (!is.null(labels)) {
      grepl(labels, label_of, ignore.case = TRUE)
    } else {
      !grepl(exclude, label_of, ignore.case = TRUE)
    }
    drop <- drop & in_scope
  }

  keep_keys <- names(areas)[!drop]
  list(
    polygons = polygons_renest(flat[piece_key %in% keep_keys, , drop = FALSE]),
    n_removed = sum(drop)
  )
}


#' Reposition view groups left-to-right on a flat coordinate table
#'
#' Pure-R equivalent of `reposition_views()`: centre each view group on the
#' origin, then lay groups out horizontally with a proportional gap.
#' `group_order` lets callers (e.g. reorder) pin the left-to-right sequence.
#' @noRd
#' @keywords internal
reposition_flat <- function(flat, type = NULL, gap = 0.15, group_order = NULL) {
  group_key <- flat$view
  if (identical(type, "cortical")) {
    hemi <- hemi_from_label(flat$label)
    group_key <- paste(hemi, flat$view)
  }

  groups <- order_view_groups(group_key, group_order, function(g) {
    idx <- group_key == g
    (min(flat$x[idx]) + max(flat$x[idx])) / 2
  })

  # `groups` always covers every value of `group_key`, so this factor has no
  # NAs and the group-wise ops below stay vectorised over the (few) views.
  gk <- factor(group_key, levels = groups)

  # Recentre each group on its own centroid.
  cx <- (tapply(flat$x, gk, min) + tapply(flat$x, gk, max)) / 2
  cy <- (tapply(flat$y, gk, min) + tapply(flat$y, gk, max)) / 2
  flat$x <- flat$x - cx[gk]
  flat$y <- flat$y - cy[gk]

  # Per-group extents after centring; group order follows `groups`.
  widths <- tapply(flat$x, gk, function(z) diff(range(z)))
  half_widths <- tapply(flat$x, gk, function(z) max(abs(z)))
  max_height <- max(abs(flat$y))
  gap_size <- max(widths) * gap

  # Lay groups left-to-right: a group's centre sits at the running left edge
  # (cumulative widths + gaps of the groups before it) plus its half-width.
  left_edge <- cumsum(c(0, utils::head(widths + gap_size, -1)))
  x_offset <- left_edge + half_widths
  flat$x <- flat$x + x_offset[gk]
  flat$y <- flat$y + max_height

  # Rows follow the group order too, not just the coordinates. Consumers read
  # view order off the row order -- ggseg::geom_brain() lays the panels out in
  # the order it meets them -- so leaving the rows alone made
  # atlas_view_reorder() move the geometry without moving the panels. The sf
  # branch has always rebuilt its rows group by group; this is the pure-R
  # branch catching up. order() on a factor is stable, so the structure order
  # within a view is untouched.
  flat[order(gk), , drop = FALSE]
}


#' Reposition a brain_polygons object
#' @noRd
#' @keywords internal
reposition_polygons <- function(polygons, type = NULL, gap = 0.15) {
  flat <- polygons_unnest(polygons)
  if (nrow(flat) == 0) {
    return(polygons)
  }
  polygons_renest(reposition_flat(flat, type = type, gap = gap))
}


#' Reorder view groups, then reposition
#' @noRd
#' @keywords internal
reorder_polygons <- function(polygons, order, type = NULL, gap = 0.15) {
  flat <- polygons_unnest(polygons)
  current_views <- unique(flat$view)
  order <- c(order, setdiff(current_views, order))
  order <- order[order %in% current_views]

  group_order <- view_reorder_group_order(flat, order, type)

  polygons_renest(reposition_flat(
    flat,
    type = type,
    gap = gap,
    group_order = group_order
  ))
}
