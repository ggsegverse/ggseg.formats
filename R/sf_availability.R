#' Attach an `sfc` column and class a data frame as `sf`, without sf
#'
#' `merge()`, `cbind()` and `[` dispatch to sf's own methods only when the sf
#' namespace is loaded. Without it each strips a different part of the sf
#' representation: `merge()` loses the class, the `sf_column` attribute and the
#' column's own `sfc` class; `cbind()` loses the class and the attribute;
#' subsetting loses the column's class. Attribute-space work therefore happens
#' with the geometry detached and this is the one place that puts it back.
#'
#' `agr` is a named factor over the non-geometry columns with sf's three levels
#' and no values set, which is what `st_as_sf()` produces for a frame carrying
#' no attribute-geometry relationships.
#' @param x a data.frame, without its geometry column.
#' @param geometry an `sfc`, in `x`'s row order.
#' @param sf_column name to give the geometry column.
#' @param after insert the column after this many other columns, so the result
#'   keeps the column order callers already see. `NULL` appends.
#' @return `x` with `geometry` attached, classed as `sf`.
#' @seealso [reorder_sfc()] to permute the geometry alongside a reordered
#'   attribute table.
#' @family sf-optional helpers
#' @export
#' @examples
#' atlas <- dk()
#' sf_data <- atlas_sf(atlas)
#' geometry <- sf_data$geometry
#'
#' # Attribute-space work with the geometry detached, then reattached.
#' attrs <- sf_data
#' attrs$geometry <- NULL
#' class(attrs) <- "data.frame"
#' attrs$keep <- attrs$label %in% atlas_labels(atlas)[1:5]
#'
#' rebuilt <- attach_sfc(attrs, geometry)
#' class(rebuilt)
#' inherits(rebuilt$geometry, "sfc")
attach_sfc <- function(x, geometry, sf_column = "geometry", after = NULL) {
  x[[sf_column]] <- geometry
  if (!is.null(after)) {
    # Index rather than head()/tail(): tail(others, -0) drops every column
    # instead of keeping them, so after = 0 would lose the frame.
    others <- setdiff(names(x), sf_column)
    before <- others[seq_len(after)]
    x <- x[c(before, sf_column, setdiff(others, before))]
  }
  attrs <- setdiff(names(x), sf_column)
  attr(x, "agr") <- stats::setNames(
    factor(
      rep(NA_character_, length(attrs)),
      levels = c("constant", "aggregate", "identity")
    ),
    attrs
  )
  attr(x, "sf_column") <- sf_column
  class(x) <- c("sf", setdiff(class(x), "sf"))
  x
}


#' Reorder an `sfc` without sf
#'
#' Subsetting drops the `sfc` class without sf loaded. A permutation does not
#' change the geometry set, so `bbox`, `crs`, `precision` and `n_empty` stay
#' valid and the attributes are reattached unchanged.
#'
#' `i` must be a permutation or a repetition of row positions, not a subset: a
#' selection that drops geometries leaves `bbox` and `n_empty` describing rows
#' that are no longer present.
#' @param geometry an `sfc`.
#' @param i row positions, in the order wanted.
#' @return `geometry` in the order given by `i`, still an `sfc`.
#' @seealso [attach_sfc()] to put the result back on a data frame.
#' @family sf-optional helpers
#' @export
#' @examples
#' geometry <- atlas_sf(dk())$geometry
#' reversed <- reorder_sfc(geometry, rev(seq_along(geometry)))
#' inherits(reversed, "sfc")
reorder_sfc <- function(geometry, i) {
  keep <- attributes(geometry)
  out <- unclass(geometry)[i]
  attributes(out) <- keep
  out
}


#' Ensure the sf package is installed
#'
#' Internal guard used by every function in ggseg.formats that uses the
#' `sf` package. Since `sf` moved to Suggests with the sf-optional
#' milestone, sf-using functions need to error gracefully (with a pointer
#' to the polygon alternative) when sf isn't installed.
#'
#' @param what Character describing the calling function or operation, used
#'   in the error message.
#' @return Invisible `TRUE` if sf is installed; aborts otherwise.
#' @keywords internal
#' @noRd
require_sf <- function(what) {
  if (!has_sf()) {
    cli::cli_abort(c(
      "{what} requires the {.pkg sf} package, which is not installed.",
      "i" = "Install with {.run install.packages(\"sf\")}, or use the
             polygon-format alternative (see {.fn as_polygon_atlas})."
    ))
  }
  invisible(TRUE)
}


#' Test whether sf is available without raising
#'
#' @return Logical.
#' @keywords internal
#' @noRd
has_sf <- function() {
  rlang::is_installed("sf")
}
