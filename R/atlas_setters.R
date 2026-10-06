#' Set the palette of an atlas
#'
#' Replaces the colour palette of a brain atlas, validating that `value` is a
#' named character vector and warning if it does not cover every atlas label.
#' This is the setter counterpart to the [atlas_palette()] accessor; it returns
#' the modified atlas, so it composes with the pipe.
#'
#' @inheritParams atlas_palette
#' @param value Named character vector of colours keyed by atlas `label`.
#'
#' @return The `ggseg_atlas` with its palette replaced.
#' @family atlas setters
#' @seealso [atlas_palette()] to read the palette.
#' @export
#' @examples
#' a <- aseg()
#' labs <- atlas_labels(a)
#' a <- set_atlas_palette(a, setNames(grDevices::rainbow(length(labs)), labs))
set_atlas_palette <- function(atlas, value) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  if (!is.character(value) || is.null(names(value))) {
    cli::cli_abort(c(
      "{.arg value} must be a named character vector of colours.",
      "i" = "Names are the atlas region {.field label}s."
    ))
  }
  absent <- setdiff(unique(atlas_labels(atlas)), names(value))
  if (length(absent)) {
    cli::cli_warn(c(
      "Palette does not cover every atlas label.",
      "i" = "e.g. {.val {utils::head(absent, 3)}} ({length(absent)} total)."
    ))
  }
  atlas$palette <- value
  atlas
}


#' Set the type of an atlas
#'
#' Replaces the type of a brain atlas. The type is held in three coupled
#' places: the `type` field, the leading `<type>_atlas` class, and the
#' `ggseg_data_<type>` class of the data payload. This setter reconstructs the
#' atlas through [ggseg_atlas()] so all three stay in agreement -- assigning
#' the `type` field directly leaves the subclass stale and
#' [is_tract_atlas()] and friends disagreeing with [atlas_type()].
#'
#' Because type and payload are coupled, the new type must match the data the
#' atlas already carries: a `"tract"` atlas needs [ggseg_data_tract()]
#' (centerlines), a `"subcortical"` atlas needs [ggseg_data_subcortical()]
#' (meshes). Retyping an atlas whose payload does not match is an error --
#' rebuild the payload with the matching `ggseg_data_*()` constructor first.
#'
#' @inheritParams atlas_palette
#' @param value Atlas type; one of `"cortical"`, `"subcortical"`, `"tract"` or
#'   `"cerebellar"`.
#'
#' @return The `ggseg_atlas` with its type, subclass and payload class in
#'   agreement.
#' @family atlas setters
#' @seealso [atlas_type()] to read the type.
#' @export
#' @examples
#' a <- aseg()
#' a <- set_atlas_type(a, "subcortical")
#' atlas_type(a)
set_atlas_type <- function(atlas, value) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  value <- match.arg(value, atlas_types())

  ggseg_atlas(
    atlas = atlas$atlas,
    type = value,
    core = atlas$core,
    data = atlas$data,
    palette = atlas$palette
  )
}
