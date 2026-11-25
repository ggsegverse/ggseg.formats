#' Collapse several data rows per atlas region into one
#'
#' Groups `data` by the columns that identify an atlas region and reduces every
#' other column to a single value: numeric columns with `fun`, non-numeric
#' columns to their first value. This is what lets a plotting function accept
#' long data with several rows per region (e.g. one row per subject) and draw a
#' single summarised value per region, rather than letting the last row win.
#' `ggseg::geom_brain()` and `ggseg3d::ggseg3d()` both aggregate with it.
#'
#' @param data A data frame of values to plot, carrying the `keys` columns.
#' @param keys Character vector of columns identifying an atlas region, e.g.
#'   `c("label", "hemi")`. These are kept, never aggregated.
#' @param fun Aggregating function for numeric columns. It must reduce a vector
#'   to a single value; `mean` (the default), `median` and `max` all do.
#' @param ignore Columns to leave out of the result entirely: the atlas
#'   metadata columns the caller joins on anyway, plus the plotting system's own
#'   bookkeeping columns (for ggplot2: `group`, `PANEL`, `flipped_aes`).
#' @param warn_collapse Whether to warn with [warn_collapsed_rows()] when rows
#'   actually collapse. Pass `FALSE` when the rows are the atlas's own identity
#'   rows rather than user data.
#' @return One row per unique key combination, in order of first appearance,
#'   with the `keys` columns and the aggregated columns.
#' @examples
#' thickness <- data.frame(
#'   label = c("lh_precentral", "lh_precentral", "lh_insula"),
#'   hemi = "left",
#'   subject = c("s01", "s02", "s01"),
#'   thickness = c(0.1, 0.9, 0.5)
#' )
#'
#' aggregate_brain_values(thickness, c("label", "hemi"))
#'
#' aggregate_brain_values(thickness, c("label", "hemi"), fun = max)
#'
#' # Drop a column instead of aggregating it
#' aggregate_brain_values(thickness, c("label", "hemi"), ignore = "subject")
#' @seealso [warn_collapsed_rows()]
#' @export
aggregate_brain_values <- function(
  data,
  keys,
  fun = mean,
  ignore = character(),
  warn_collapse = TRUE
) {
  missing_keys <- setdiff(keys, names(data))
  if (length(keys) == 0 || length(missing_keys) > 0) {
    cli::cli_abort(c(
      "{.arg keys} must name one or more columns of {.arg data}.",
      "x" = if (length(keys) == 0) {
        "No key column was given."
      } else {
        "Not a column of {.arg data}: {.field {missing_keys}}."
      }
    ))
  }

  value_cols <- setdiff(names(data), c(keys, ignore))
  if (warn_collapse) {
    warn_collapsed_rows(data, keys, value_cols)
  }

  out_cols <- c(keys, value_cols)
  if (nrow(data) == 0) {
    return(data[, out_cols, drop = FALSE])
  }

  # Keyed on match() indices, not on the values: `as.character(NA)` is the
  # string "NA", so pasting values merges an NA key with one literally spelled
  # "NA", and `as.character()` on a double loses precision the same way.
  key_strings <- do.call(
    paste,
    c(
      lapply(data[keys], function(col) match(col, unique(col))),
      sep = "\r"
    )
  )
  groups <- split(
    seq_len(nrow(data)),
    factor(key_strings, levels = unique(key_strings))
  )

  out <- data[
    vapply(groups, function(rows) rows[1], integer(1)),
    out_cols,
    drop = FALSE
  ]
  rownames(out) <- NULL

  for (col in value_cols) {
    column <- data[[col]]
    if (!is.numeric(column)) {
      next
    }
    reduced <- lapply(groups, function(rows) fun(column[rows]))
    if (any(lengths(reduced) != 1L)) {
      cli::cli_abort(c(
        "{.arg fun} must reduce each region's values to a single value.",
        "i" = "It returned the wrong length for at least one region.",
        "i" = "Try {.fn mean} (the default), {.fn median}, or {.fn max}."
      ))
    }
    out[[col]] <- unlist(reduced, use.names = FALSE)
  }

  out
}


#' Warn once per session when values are collapsed per region
#'
#' Before ggseg 3.0.0 several `data` rows for the same region drew on top of
#' each other, so the last row won; they are now reduced with `fun`
#' ([aggregate_brain_values()], mean by default). That is a silent numeric
#' change for anyone plotting a cohort they have not summarised themselves, so
#' say so the first time it happens in a session. The warning has class
#' `"ggseg_collapsed_rows"`, so it can be muffled or caught on its own.
#'
#' @param data A data frame of values to plot.
#' @param keys Character vector of columns identifying an atlas region.
#' @param value_cols The columns that would be aggregated.
#' @return `invisible(NULL)`, called for its warning side effect.
#' @examples
#' thickness <- data.frame(
#'   label = c("lh_precentral", "lh_precentral"),
#'   thickness = c(0.1, 0.9)
#' )
#'
#' # Warns: two rows map to one region
#' warn_collapsed_rows(thickness, "label", "thickness")
#' @seealso [aggregate_brain_values()]
#' @export
warn_collapsed_rows <- function(data, keys, value_cols) {
  collapses <- length(value_cols) > 0 &&
    anyDuplicated(data[, keys, drop = FALSE]) > 0
  if (!collapses) {
    return(invisible(NULL))
  }
  rlang::warn(
    cli::format_message(c(
      "!" = paste(
        "Several {.arg data} rows map to the same atlas region;",
        "combining them with {.arg fun}."
      ),
      "i" = paste(
        "Before ggseg 3.0.0 these rows overplotted, so the last one won.",
        "Pass {.code fun = dplyr::last} to keep that behaviour."
      ),
      "i" = "Non-numeric columns take the first value regardless of {.arg fun}."
    )),
    class = "ggseg_collapsed_rows",
    .frequency = "once",
    .frequency_id = "ggseg_collapsed_rows"
  )
  invisible(NULL)
}
