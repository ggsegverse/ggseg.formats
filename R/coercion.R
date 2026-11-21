#' Bring an atlas up to the current format
#'
#' Answers for every representation an atlas arrives in -- the S7 object this
#' release builds, the plain tagged list an atlas package built before 3.0.0,
#' a pre-2.0 `brain_atlas`, a `ggseg3d_atlas`, and an S7 atlas stamped with an
#' older schema -- and returns the current one. It is a no-op on an atlas that
#' is already current, so the cost falls on the objects that need it.
#'
#' Package authors should call this on an atlas handed to them by a user, so
#' that the rest of their code has a single kind of object to reason about.
#' The two ways it can fail are separately catchable: `ggseg.formats_not_atlas`
#' for "that is not an atlas", `ggseg.formats_invalid_atlas` for "that is an
#' atlas and it is malformed". Both name the caller's own argument, which is
#' what `arg` and `call` are for.
#'
#' Upgrading beats asserting at a boundary: [assert_ggseg_atlas()] returns its
#' input unchanged, which leaves every later path to cope with whatever it was
#' given. That is how a legacy list atlas reached `as.data.frame()` in
#' `brain_join()` and `plot.default()` from `plot()`.
#'
#' @param x An atlas, in any representation.
#' @param arg The argument name to blame in an error. Defaults to the
#'   caller's.
#' @param call The environment to attribute the error to.
#' @return `x` as a current `ggseg_atlas`.
#' @seealso [assert_ggseg_atlas()], which checks without upgrading.
#' @export
#' @examples
#' atlas <- as_ggseg_atlas(dk())
#' is_ggseg_atlas(atlas)
#'
#' # A no-op on an atlas that is already current.
#' identical(as_ggseg_atlas(dk()), dk())
as_ggseg_atlas <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is_atlas_class(x) && atlas_is_current(x)) {
    return(x)
  }

  rlang::try_fetch(
    convert_atlas(x),
    error = function(cnd) {
      if (!is_atlas_class(x)) {
        cli::cli_abort(
          "{.arg {arg}} must be a {.cls ggseg_atlas}, not
           {.cls {class(x)[1]}}.",
          class = "ggseg.formats_not_atlas",
          parent = cnd,
          call = call
        )
      }
      cli::cli_abort(
        "{.arg {arg}} is a {.cls ggseg_atlas} with an invalid structure.",
        class = "ggseg.formats_invalid_atlas",
        parent = cnd,
        call = call
      )
    }
  )
}


#' Is this atlas the current object, built against the current schema?
#' @noRd
atlas_is_current <- function(atlas) {
  S7::S7_inherits(atlas, ggseg_atlas_class) && atlas_schema_is_current(atlas)
}


#' Dispatch the upgrade over the representations an atlas arrives in
#'
#' Internal: the public door is [as_ggseg_atlas()], which owns the boundary
#' errors. Nothing outside this package registers a method, and the atlas
#' types are a closed set, so the dispatch is bookkeeping rather than an
#' extension point.
#' @noRd
convert_atlas <- function(x) {
  UseMethod("convert_atlas")
}


#' @noRd
convert_atlas.default <- function(x) {
  cli::cli_abort(
    "Cannot convert {.cls {class(x)[1]}} to {.cls ggseg_atlas}."
  )
}


#' @noRd
convert_atlas.ggseg_atlas <- function(x) {
  if (
    !is.null(atlas_slot(x, "data")) &&
      inherits(atlas_slot(x, "data"), "ggseg_atlas_data")
  ) {
    # Modern payload, but possibly not the current object: an atlas package
    # built before 3.0.0 ships a tagged list, and one built against an older
    # schema is an S7 object carrying a frozen copy of the class it was built
    # with. Both are upgraded the same way -- rebuilt through the current
    # constructor. That is the whole upgrade: no source data, no pipeline, no
    # geometry recomputed, so the result is the same atlas brought up to date.
    if (!S7::S7_inherits(x, ggseg_atlas_class)) {
      return(restamp_class(x))
    }
    if (!atlas_schema_is_current(x)) {
      return(restamp_class(x))
    }
    return(x)
  }

  has_legacy_geometry <- !is.null(atlas_slot(x, "sf")) ||
    !is.null(atlas_slot(x, "vertices")) ||
    !is.null(atlas_slot(x, "meshes"))

  if (!is.null(atlas_slot(x, "core")) && has_legacy_geometry) {
    return(convert_legacy_structure(x))
  }

  cli::cli_abort("Cannot convert ggseg_atlas: unrecognized structure.")
}


#' @noRd
convert_atlas.brain_atlas <- function(x) {
  lifecycle::deprecate_warn(
    "0.1.0",
    I("Converting legacy `brain_atlas` objects"),
    I("`ggseg_atlas()` (use `convert_atlas()`)"),
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


#' @noRd
convert_atlas.ggseg3d_atlas <- function(x) {
  lifecycle::deprecate_warn(
    "0.1.0",
    I("Converting legacy `ggseg3d_atlas` objects"),
    I("`ggseg_atlas()` (use `convert_atlas()`)"),
    always = TRUE
  )
  convert_legacy_brain_atlas(atlas_3d = x)
}


#' @noRd
convert_atlas.list <- function(x) {
  if (
    "data" %in% names(x) && inherits(atlas_slot(x, "data"), "ggseg_atlas_data")
  ) {
    return(restamp_class(x))
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
    "convert_atlas()"
  )
  convert_atlas(x)
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
  core <- repair_legacy_core(core, atlas_slot(x, "atlas"))

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


#' Bring a legacy core table up to the invariants the class enforces
#'
#' The closed `hemi` vocabulary and unique `label`s are invariants of the S7
#' class, but `vermis`, `middle`, `lh` and `rh` are spellings published atlases
#' shipped and are still accepted *as input*. Every upgrade path has to repair
#' them before construction, or an atlas that loaded on 2.x stops loading.
#'
#' @keywords internal
#' @noRd
repair_legacy_core <- function(core, atlas = NA_character_) {
  core <- normalise_legacy_hemi(core)
  dedupe_legacy_core_labels(core, atlas)
}

#' @keywords internal
#' @noRd
restamp_class <- function(x) {
  type <- atlas_slot(x, "type") %||% "cortical"
  new_ggseg_atlas(
    atlas_slot(x, "atlas"),
    type,
    atlas_slot(x, "palette"),
    repair_legacy_core(atlas_slot(x, "core"), atlas_slot(x, "atlas")),
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
  # A legacy `sf` carries the published `hemi` spellings, so this path needs
  # the same repair as the others.
  repair_legacy_core(core, atlas)
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
