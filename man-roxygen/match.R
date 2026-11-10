#' @param match How `views` is read. `"exact"`, the default, takes each name
#'   as a whole view name. `"pattern"` takes `views` as a regular expression
#'   instead, matched as a substring --- `"axial"` then reaches `axial_1` and
#'   `axial_2` as well. Prefer `"exact"`: a name that happens to sit inside
#'   another view's name silently scopes to both views under `"pattern"`.
