#' @param ignore.case Whether `pattern` matches case-insensitively, passed to
#'   [grepl()]. Defaults to `TRUE` for backwards compatibility, so a pattern
#'   like `"abc"` also selects `"ABC"` and a context pattern like
#'   `"Thalamus"` also selects a focus label such as `"hypothalamus"`. Case
#'   folding is locale-dependent; set `FALSE` (and/or anchor the pattern) when
#'   labels differ only in case.
