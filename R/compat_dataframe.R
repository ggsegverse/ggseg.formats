#' Tag a data.frame with the data.frame classes
#' @noRd
#' @keywords internal
as_tbl <- function(x) {
  x <- as.data.frame(x)
  rownames(x) <- NULL
  class(x) <- c("tbl_df", "tbl", "data.frame")
  x
}

#' Print the first `n` rows of a table as a plain data.frame
#'
#' Renders deterministically whether or not tibble is installed: the frame is
#' stripped to a base data.frame and list-columns are summarised as
#' `<type [size]>`, so output never depends on tibble's pretty-printer. The
#' package only tags frames as `tbl_df` for cosmetics and does
#' not depend on tibble, so relying on tibble's printer is a source of snapshot
#' drift across environments.
#' @noRd
#' @keywords internal
print_data_head <- function(x, n = 10L) {
  df <- as.data.frame(x)
  n_total <- nrow(df)
  df <- utils::head(df, n)
  for (col in names(df)) {
    if (is.list(df[[col]])) {
      df[[col]] <- vapply(df[[col]], format_list_cell, character(1))
    }
  }
  rownames(df) <- NULL
  print.data.frame(df)
  if (n_total > n) {
    cli::cli_text("{.emph ... with {n_total - n} more row{?s}}")
  }
  invisible(x)
}

#' Summarise a list-column cell as a compact `<type [size]>` token
#' @noRd
#' @keywords internal
format_list_cell <- function(cell) {
  if (is.null(cell)) {
    return("<NULL>")
  }
  if (is.data.frame(cell)) {
    return(sprintf("<df [%d x %d]>", nrow(cell), ncol(cell)))
  }
  abbr <- c(
    integer = "int",
    double = "dbl",
    character = "chr",
    logical = "lgl",
    complex = "cpl",
    list = "list"
  )
  type <- typeof(cell)
  label <- if (type %in% names(abbr)) abbr[[type]] else type
  sprintf("<%s [%d]>", label, length(cell))
}

#' Distinct rows over a set of columns
#' @noRd
#' @keywords internal
df_distinct <- function(df, cols) {
  as_tbl(unique(df[, cols, drop = FALSE]))
}

#' Left join on one or more key columns
#'
#' Replicates dplyr's one-to-many semantics: each row of `x` is repeated once
#' per matching row of `y` (in `y`'s order), and unmatched `x` rows are kept
#' once with `NA` in the added columns. Callers are expected to share only the
#' `by` columns; any other shared name is suffixed `.y` rather than silently
#' overwriting `x`, with a warning.
#' @noRd
#' @keywords internal
df_left_join <- function(x, y, by) {
  add <- setdiff(names(y), by)
  collide <- intersect(add, names(x))
  if (length(collide) > 0) {
    cli::cli_warn(c(
      "{.arg y} has non-key columns that collide with {.arg x}: {collide}.",
      "i" = "Keeping {.arg x}; {.arg y}'s copies are suffixed {.field .y}."
    ))
  }
  xkey <- do.call(paste, c(x[by], sep = "\r"))
  ykey <- do.call(paste, c(y[by], sep = "\r"))
  matches <- lapply(xkey, function(k) which(ykey == k))
  reps <- vapply(matches, function(m) max(length(m), 1L), integer(1))
  yidx <- unlist(lapply(
    matches,
    function(m) if (length(m)) m else NA_integer_
  ))
  out <- x[rep(seq_len(nrow(x)), reps), , drop = FALSE]
  for (col in add) {
    target <- if (col %in% collide) paste0(col, ".y") else col
    out[[target]] <- y[[col]][yidx]
  }
  as_tbl(out)
}

#' Row-bind a list of data.frames, optionally adding an id column from names
#'
#' Frames with differing columns are reconciled to their union (missing values
#' filled with `NA`) with a warning, rather than erroring as `rbind()` would.
#' @noRd
#' @keywords internal
df_bind_rows <- function(dfs, .id = NULL) {
  dfs <- Filter(Negate(is.null), dfs)
  if (!length(dfs)) {
    return(as_tbl(data.frame()))
  }
  if (!is.null(.id)) {
    if (is.null(names(dfs))) {
      cli::cli_abort("{.arg .id} requires a named list of data.frames.")
    }
    dfs <- Map(
      function(d, n) {
        d[[.id]] <- rep(n, nrow(d))
        d[c(.id, setdiff(names(d), .id))]
      },
      dfs,
      names(dfs)
    )
  }
  all_cols <- Reduce(union, lapply(dfs, names))
  ragged <- !all(vapply(
    dfs,
    function(d) setequal(names(d), all_cols),
    logical(1)
  ))
  if (ragged) {
    cli::cli_warn(
      "Row-binding data.frames with differing columns; gaps filled with NA."
    )
    dfs <- lapply(dfs, function(d) {
      miss <- setdiff(all_cols, names(d))
      if (length(miss) > 0) {
        d[miss] <- NA
      }
      d[all_cols]
    })
  }
  as_tbl(do.call(rbind, dfs))
}

#' Nest every column except `key` into a list-column named `into`
#' @noRd
#' @keywords internal
df_nest <- function(df, key, into) {
  ukey <- unique(df[[key]])
  rest <- setdiff(names(df), key)
  # One pass to group the rows, rather than a full scan and subset of the
  # whole table per key: that is O(keys x rows), and the table is every
  # coordinate in the atlas. Grouped on `match()` indices rather than on the
  # values, which keeps first-appearance key order and keeps an `NA` key in
  # its own group -- `df[[key]] == k` yielded NA-index rows for it, so an
  # NA-labelled group came back as every row filled with NA.
  grp <- factor(match(df[[key]], ukey), levels = seq_along(ukey))
  geoms <- unname(lapply(split(seq_len(nrow(df)), grp), function(i) {
    as_tbl(df[i, rest, drop = FALSE])
  }))
  out <- as_tbl(stats::setNames(list(ukey), key))
  out[[into]] <- geoms
  out
}

#' Unnest a list-column of data.frames, recycling the other columns
#' @noRd
#' @keywords internal
df_unnest <- function(df, col) {
  inner <- df[[col]]
  reps <- vapply(inner, nrow, integer(1))
  outer <- df[
    rep(seq_len(nrow(df)), reps),
    setdiff(names(df), col),
    drop = FALSE
  ]
  as_tbl(cbind(outer, do.call(rbind, inner)))
}
