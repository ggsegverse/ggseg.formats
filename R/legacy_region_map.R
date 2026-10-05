#' Map pre-0.1.0 region names to current region keys
#'
#' Before version 0.1.0 the `region` column of the bundled atlases held a
#' long-form display name. From 0.1.0 it holds a short, hemisphere-free key
#' derived from `label`, and the long-form name lives in `names`. Joins and
#' filters written against the old values therefore match nothing and fail
#' silently: `merge(all.x = TRUE)` and the ggseg fill scale both yield `NA`,
#' which draws as a blank parcel rather than raising an error.
#'
#' This returns the translation between the two, so old code can be updated
#' mechanically:
#'
#' ```r
#' map <- legacy_region_map(dk())
#' my_data$region <- unname(map[my_data$region])
#' ```
#'
#' The mapping comes from a table of exactly what each bundled atlas shipped at
#' 0.0.4, not from the atlas's current `names` column -- `names` is the curated
#' display name and several 0.0.4 `region` values were mechanically derived
#' (`"ventraldc"`, `"cc posterior"`), so the two are deliberately not the same.
#' Where two old names shared one `label`, as `"Thalamus"` and
#' `"Thalamus Proper"` did in `aseg`, both still translate even though the alias
#' row itself is gone from `core`.
#'
#' @param atlas A `ggseg_atlas` object.
#'
#' @return A named character vector whose names are the pre-0.1.0 `region`
#'   values and whose values are the current `region` keys. Zero-length for an
#'   atlas this package ships no legacy table for, which is every atlas except
#'   the bundled four.
#'
#' @seealso [atlas_names()] for the curated display names, [atlas_regions()]
#'   for the current keys.
#' @family atlas accessors
#' @export
#' @examples
#' head(legacy_region_map(aseg()))
#' legacy_region_map(tracula())[["SLF I"]]
#' legacy_region_map(aseg())[["Thalamus Proper"]]
legacy_region_map <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  legacy <- if (length(atlas$atlas) == 1 && !is.na(atlas$atlas)) {
    .legacy_regions[[atlas$atlas]] # nolint: object_usage_linter.
  }
  if (is.null(legacy)) {
    cli::cli_warn(c(
      "No pre-0.1.0 region names are recorded for {.val {atlas$atlas}}.",
      "i" = "Only the atlases bundled with ggseg.formats were re-keyed in
             0.1.0, so there is nothing to migrate."
    ))
    return(stats::setNames(character(0), character(0)))
  }

  current <- atlas$core$region[match(legacy$label, atlas$core$label)]
  keep <- !is.na(current)
  map <- stats::setNames(current[keep], legacy$legacy_region[keep])
  map[!duplicated(names(map))]
}
