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
  if (
    !is.null(atlas_slot(x, "data")) &&
      inherits(atlas_slot(x, "data"), "ggseg_atlas_data")
  ) {
    return(x)
  }

  if (
    !is.null(atlas_slot(x, "core")) &&
      (!is.null(atlas_slot(x, "sf")) ||
        !is.null(atlas_slot(x, "vertices")) ||
        !is.null(atlas_slot(x, "meshes")))
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

  if (
    !is.null(atlas_slot(x, "data")) &&
      inherits(atlas_slot(x, "data"), "ggseg_atlas_data")
  ) {
    return(restamp_class(x))
  }

  has_legacy_slots <- !all(
    vapply(
      list(
        atlas_slot(x, "sf"),
        atlas_slot(x, "vertices"),
        atlas_slot(x, "meshes")
      ),
      is.null,
      logical(1)
    )
  )
  if (!is.null(atlas_slot(x, "core")) && has_legacy_slots) {
    return(convert_legacy_structure(x))
  }

  if (!is.null(atlas_slot(x, "data")) && is.data.frame(atlas_slot(x, "data"))) {
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
  if (
    "data" %in% names(x) && inherits(atlas_slot(x, "data"), "ggseg_atlas_data")
  ) {
    return(ggseg_atlas(
      atlas = atlas_slot(x, "atlas"),
      type = atlas_slot(x, "type"),
      palette = atlas_slot(x, "palette"),
      core = atlas_slot(x, "core"),
      data = atlas_slot(x, "data"),
      provenance = atlas_slot(x, "provenance")
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

  if (!is.null(atlas_slot(x, "core"))) {
    return(restamp_class(x))
  }

  require_sf("convert_legacy_brain_data()")
  sf_data <- normalize_legacy_sf(atlas_slot(x, "data"))
  type <- atlas_slot(x, "type") %||% "cortical"

  core <- legacy_core_from_sf(sf_data, atlas_slot(x, "atlas"))
  palette <- legacy_palette_from_sf(sf_data)

  data <- switch(
    type,
    "cortical" = ggseg_data_cortical(geom = sf_data, vertices = NULL),
    "subcortical" = ggseg_data_subcortical(geom = sf_data, meshes = NULL),
    "tract" = ggseg_data_tract(geom = sf_data, meshes = NULL),
    ggseg_data_cortical(geom = sf_data, vertices = NULL)
  )

  ggseg_atlas(
    atlas = atlas_slot(x, "atlas"),
    type = type,
    palette = palette,
    core = core,
    data = data,
    provenance = atlas_slot(x, "provenance")
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
  type <- atlas_slot(x, "type")

  core <- atlas_slot(x, "core")
  if (
    !is.null(core) && !"display" %in% names(core) && "region" %in% names(core)
  ) {
    core$display <- core$region
  }
  core <- normalise_legacy_hemi(core)
  core <- dedupe_legacy_core_labels(core, atlas_slot(x, "atlas"))

  data <- switch(
    type,
    "cortical" = ggseg_data_cortical(
      geom = atlas_slot(x, "sf"),
      vertices = atlas_slot(x, "vertices")
    ),
    "subcortical" = ggseg_data_subcortical(
      geom = atlas_slot(x, "sf"),
      meshes = atlas_slot(x, "meshes")
    ),
    "tract" = ggseg_data_tract(
      geom = atlas_slot(x, "sf"),
      meshes = atlas_slot(x, "meshes")
    ),
    cli::cli_abort("Unknown atlas type: {.val {type}}")
  )

  ggseg_atlas(
    atlas = atlas_slot(x, "atlas"),
    type = type,
    palette = atlas_slot(x, "palette"),
    core = core,
    data = data,
    provenance = atlas_slot(x, "provenance")
  )
}


#' @keywords internal
#' @noRd
restamp_class <- function(x) {
  type <- atlas_slot(x, "type") %||% "cortical"
  new_ggseg_atlas(
    atlas_slot(x, "atlas"),
    type,
    atlas_slot(x, "palette"),
    atlas_slot(x, "core"),
    as_atlas_data(atlas_slot(x, "data"), type),
    atlas_slot(x, "provenance")
  )
}


#' Wrap a legacy bare geometry table in the payload class for its type
#'
#' Legacy `brain_atlas` objects kept 2D geometry directly in `$data` as an sf
#' frame, and the old list representation let it stay there: `new_ggseg_atlas()`
#' was a bare `structure()` call that validated nothing, so a re-stamped atlas
#' carried whatever `$data` it was handed. An S7 class has no unvalidated
#' constructor, so the geometry is wrapped in the `ggseg_data_*()` payload its
#' type calls for, which is what every other construction path already
#' produces.
#' @noRd
as_atlas_data <- function(data, type) {
  if (
    is.null(data) || inherits(data, c("ggseg_atlas_data", "brain_atlas_data"))
  ) {
    return(data)
  }
  if (!is.data.frame(data)) {
    return(data)
  }
  switch(
    type,
    subcortical = ggseg_data_subcortical(geom = data, meshes = NULL),
    tract = ggseg_data_tract(geom = data, meshes = NULL),
    cerebellar = ggseg_data_cerebellar(geom = data, meshes = NULL),
    wm = ggseg_data_wm(geom = data, meshes = NULL),
    ggseg_data_cortical(geom = data, vertices = NULL)
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
legacy_core_from_sf <- function(sf_data, atlas = NA_character_) {
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
  core$display <- core$region
  dedupe_legacy_core_labels(core, atlas)
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
