#' Map pre-0.1.0 region names to current region keys
#'
#' Before version 0.1.0 the `region` column of the bundled atlases held a
#' long-form display name. From 0.1.0 it holds a short, hemisphere-free key
#' derived from `label`, and the long form moved to `names`. Joins and filters
#' written against the old values therefore match nothing and fail silently:
#' `merge(all.x = TRUE)` and the ggseg fill scale both yield `NA`, which draws
#' as a blank parcel rather than raising an error.
#'
#' This returns the translation between the two, so old code can be updated
#' mechanically. Where several old names collapsed onto one key -- the `aseg`
#' alias rows, where `"Thalamus"` and `"Thalamus Proper"` were both the single
#' `Left-Thalamus` label -- only the name retained in `names` is listed; the
#' aliases are gone and cannot be recovered.
#'
#' @param atlas A `ggseg_atlas` object carrying a `names` column.
#'
#' @return A named character vector whose names are the pre-0.1.0 `region`
#'   values and whose values are the current `region` keys. Zero-length when
#'   the atlas carries no `names` column.
#'
#' @seealso [atlas_names()], [atlas_regions()]
#' @family atlas accessors
#' @export
#' @examples
#' head(legacy_region_map(aseg()))
#' legacy_region_map(tracula())[["SLF I"]]
legacy_region_map <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  core <- atlas$core
  if (!"names" %in% names(core)) {
    cli::cli_warn(c(
      "{.val {atlas$atlas}} carries no {.field names} column.",
      "i" = "There is no pre-0.1.0 region name to map from."
    ))
    return(stats::setNames(character(0), character(0)))
  }
  keep <- !is.na(core$names) & !is.na(core$region)
  map <- stats::setNames(core$region[keep], core$names[keep])
  map[!duplicated(names(map))]
}
