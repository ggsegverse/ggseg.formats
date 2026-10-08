#' Coerce to ggseg atlas
#'
#' @param x object to make into a ggseg_atlas
#' @return an object of class 'ggseg_atlas'
#' @export
#' @examples
#' atlas <- as_ggseg_atlas(dk())
#' is_ggseg_atlas(atlas)
as_ggseg_atlas <- function(x) {
  UseMethod("as_ggseg_atlas")
}


#' @export
as_ggseg_atlas.default <- function(x) {
  cli::cli_abort(
    "Cannot convert {.cls {class(x)[1]}} to {.cls ggseg_atlas}."
  )
}


#' @export
as_ggseg_atlas.ggseg_atlas <- function(x) {
  if (!is.null(x$data) && inherits(x$data, "ggseg_atlas_data")) {
    return(x)
  }

  if (
    !is.null(x$core) &&
      (!is.null(x$sf) || !is.null(x$vertices) || !is.null(x$meshes))
  ) {
    return(convert_legacy_structure(x))
  }

  cli::cli_abort("Cannot convert ggseg_atlas: unrecognized structure.")
}


#' @export
as_ggseg_atlas.brain_atlas <- function(x) {
  lifecycle::deprecate_warn(
    "0.1.0",
    I("Converting legacy `brain_atlas` objects"),
    I("`ggseg_atlas()` (use `as_ggseg_atlas()`)"),
    always = TRUE
  )

  if (!is.null(x$data) && inherits(x$data, "ggseg_atlas_data")) {
    return(restamp_class(x))
  }

  has_legacy_slots <- !all(
    vapply(
      list(x$sf, x$vertices, x$meshes),
      is.null,
      logical(1)
    )
  )
  if (!is.null(x$core) && has_legacy_slots) {
    return(convert_legacy_structure(x))
  }

  if (!is.null(x$data) && is.data.frame(x$data)) {
    return(convert_legacy_brain_data(x))
  }

  cli::cli_abort("Cannot convert legacy brain_atlas: unrecognized structure.")
}


#' @export
as_ggseg_atlas.ggseg3d_atlas <- function(x) {
  lifecycle::deprecate_warn(
    "0.1.0",
    I("Converting legacy `ggseg3d_atlas` objects"),
    I("`ggseg_atlas()` (use `as_ggseg_atlas()`)"),
    always = TRUE
  )
  convert_legacy_brain_atlas(atlas_3d = x)
}


#' @export
as_ggseg_atlas.list <- function(x) {
  if ("data" %in% names(x) && inherits(x$data, "ggseg_atlas_data")) {
    return(ggseg_atlas(
      atlas = x$atlas,
      type = x$type,
      palette = x$palette,
      core = x$core,
      data = x$data
    ))
  }

  if (
    "core" %in%
      names(x) &&
      ("sf" %in% names(x) || "vertices" %in% names(x) || "meshes" %in% names(x))
  ) {
    legacy <- structure(x, class = "ggseg_atlas")
    return(convert_legacy_structure(legacy))
  }

  cli::cli_abort(
    "Cannot convert list to {.cls ggseg_atlas}."
  )
}


#' @rdname as_ggseg_atlas
#' @export
as_brain_atlas <- function(x) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "as_brain_atlas()",
    "as_ggseg_atlas()"
  )
  as_ggseg_atlas(x)
}


#' Convert legacy brain_atlas data to unified format
#'
#' Converts an old-style brain_atlas (where `$data` contains sf directly)
#' to the unified format with `$core` and `$data` (ggseg_atlas_data).
#'
#' @param x A legacy brain_atlas
#' @return A ggseg_atlas in unified format
#' @keywords internal
#' @noRd
convert_legacy_brain_data <- function(x) {
  if (!is_atlas_class(x)) {
    cli::cli_abort(
      "{.arg x} must be a {.cls brain_atlas} or {.cls ggseg_atlas}."
    )
  }

  if (!is.null(x$core)) {
    return(restamp_class(x))
  }

  require_sf("convert_legacy_brain_data()")
  sf_data <- normalize_legacy_sf(x$data)
  type <- x$type %||% "cortical"

  core <- legacy_core_from_sf(sf_data)
  palette <- legacy_palette_from_sf(sf_data)

  data <- switch(
    type,
    "cortical" = ggseg_data_cortical(geom = sf_data, vertices = NULL),
    "subcortical" = ggseg_data_subcortical(geom = sf_data, meshes = NULL),
    "tract" = ggseg_data_tract(geom = sf_data, meshes = NULL),
    ggseg_data_cortical(geom = sf_data, vertices = NULL)
  )

  ggseg_atlas(
    atlas = x$atlas,
    type = type,
    palette = palette,
    core = core,
    data = data
  )
}


#' Convert legacy brain_atlas structure
#'
#' Converts a brain_atlas with separate sf/vertices/meshes fields to the
#' new structure with a single data field.
#'
#' @param x A legacy brain_atlas
#' @return A ggseg_atlas with the new structure
#' @keywords internal
#' @noRd
convert_legacy_structure <- function(x) {
  type <- x$type

  core <- x$core
  if (
    !is.null(core) && !"names" %in% names(core) && "region" %in% names(core)
  ) {
    core$names <- core$region
  }

  data <- switch(
    type,
    "cortical" = ggseg_data_cortical(geom = x$sf, vertices = x$vertices),
    "subcortical" = ggseg_data_subcortical(geom = x$sf, meshes = x$meshes),
    "tract" = ggseg_data_tract(geom = x$sf, meshes = x$meshes),
    cli::cli_abort("Unknown atlas type: {.val {type}}")
  )

  ggseg_atlas(
    atlas = x$atlas,
    type = type,
    palette = x$palette,
    core = core,
    data = data
  )
}


#' @keywords internal
#' @noRd
restamp_class <- function(x) {
  type <- x$type %||% "cortical"
  structure(
    list(
      atlas = x$atlas,
      type = type,
      palette = x$palette,
      core = x$core,
      data = x$data
    ),
    class = c(
      paste0(type, "_atlas"),
      "ggseg_atlas",
      "list"
    )
  )
}


#' Strip legacy classes from sf data and rename `side` to `view`
#' @noRd
#' @keywords internal
normalize_legacy_sf <- function(sf_data) {
  class(sf_data) <- setdiff(
    class(sf_data),
    c("brain_data", "ggseg_atlas", "brain_atlas")
  )
  if ("side" %in% names(sf_data) && !"view" %in% names(sf_data)) {
    names(sf_data)[names(sf_data) == "side"] <- "view"
  }
  sf_data
}


#' Distinct hemi/region/label core table from legacy sf data
#' @noRd
#' @keywords internal
legacy_core_from_sf <- function(sf_data) {
  core <- df_distinct(
    sf::st_drop_geometry(sf_data[
      !is.na(sf_data$label),
      c("hemi", "region", "label"),
      drop = FALSE
    ]),
    c("hemi", "region", "label")
  )
  # A legacy atlas's `region` is the long-form display name, which is what
  # `names` holds in the current schema, so the converted atlas is complete
  # rather than missing a required column.
  core$names <- core$region
  core
}


#' Label-keyed colour palette from legacy sf data, or NULL
#' @noRd
#' @keywords internal
legacy_palette_from_sf <- function(sf_data) {
  if (!("colour" %in% names(sf_data))) {
    return(NULL)
  }
  pal <- stats::setNames(sf_data$colour, sf_data$label)
  pal[!is.na(names(pal)) & !duplicated(names(pal))]
}
