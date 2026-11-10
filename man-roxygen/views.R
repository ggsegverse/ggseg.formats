#' @param views Views to scope the pruning to, or `NULL` (the default) for
#'   every view. Matched whole and case-insensitively against the atlas's own
#'   views, so a name has to be one [atlas_views()] reports. Give them as a
#'   character vector, or in one string separated by `"|"`; the two are
#'   equivalent. Names that match no view are warned about and otherwise
#'   ignored.
