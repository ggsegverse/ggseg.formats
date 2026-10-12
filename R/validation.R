#' Validate sf component
#' @param sf sf data.frame to validate
#' @return validated sf object
#' @keywords internal
#' @noRd
validate_sf <- function(sf) {
  if (!is.data.frame(sf)) {
    cli::cli_abort("{.arg sf} must be a data.frame.")
  }

  required <- c("label", "view", "geometry")
  missing <- setdiff(required, names(sf))
  if (length(missing) > 0) {
    cli::cli_abort("{.arg sf} must contain columns: {.field {missing}}.")
  }

  if (!inherits(sf$geometry, "sfc")) {
    cli::cli_abort(
      "{.field geometry} column must be an sf geometry column (sfc)."
    )
  }

  # Everything above is a shape check on a plain data.frame, so it reports the
  # real problem whether or not sf is installed. Only the coercion and the
  # emptiness test below need sf itself.
  require_sf("validate_sf()")

  if (!inherits(sf, "sf")) {
    sf <- sf::st_as_sf(sf)
  }

  empty_geom <- sf::st_is_empty(sf$geometry)
  if (any(empty_geom)) {
    cli::cli_abort(c(
      "All sf entries must contain geometry.",
      "i" = "Empty geometry for: {.val {sf$label[empty_geom]}}."
    ))
  }

  sf
}


#' Validate vertices component
#' @param vertices vertices data.frame to validate
#' @return validated vertices object
#' @keywords internal
#' @noRd
validate_vertices <- function(vertices) {
  if (!is.data.frame(vertices)) {
    cli::cli_abort("{.arg vertices} must be a data.frame.")
  }

  required <- c("label", "vertices")
  missing <- setdiff(required, names(vertices))
  if (length(missing) > 0) {
    cli::cli_abort("{.arg vertices} must contain columns: {.field {missing}}.")
  }

  if (!is.list(vertices$vertices)) {
    cli::cli_abort("{.field vertices} column must be a list-column.")
  }

  vertex_lengths <- vapply(vertices$vertices, length, integer(1))
  empty_labels <- vertices$label[vertex_lengths == 0]
  if (length(empty_labels) > 0) {
    cli::cli_abort(c(
      "All vertex entries must contain data.",
      "i" = "Empty vertices for: {.val {empty_labels}}."
    ))
  }

  as_tbl(vertices)
}


#' Validate meshes component
#' @param meshes meshes data.frame to validate
#' @param tract If TRUE, validates additional tract-specific mesh components
#' @return validated meshes object
#' @keywords internal
#' @noRd
validate_meshes <- function(meshes, tract = FALSE) {
  if (!is.data.frame(meshes)) {
    cli::cli_abort("{.arg meshes} must be a data.frame.")
  }

  required <- c("label", "mesh")
  missing <- setdiff(required, names(meshes))
  if (length(missing) > 0) {
    cli::cli_abort("{.arg meshes} must contain columns: {.field {missing}}.")
  }

  if (!is.list(meshes$mesh)) {
    cli::cli_abort("{.field mesh} column must be a list-column.")
  }

  is_empty <- vapply(
    seq_len(nrow(meshes)),
    function(i) validate_one_mesh(meshes$mesh[[i]], meshes$label[i], tract),
    logical(1)
  )

  empty_labels <- meshes$label[is_empty]
  if (length(empty_labels) > 0) {
    cli::cli_abort(c(
      "All mesh entries must contain data.",
      "i" = "Empty mesh for: {.val {empty_labels}}."
    ))
  }

  meshes
}


#' Validate a single mesh entry
#'
#' Aborts on a structurally invalid mesh. Returns `TRUE` when the mesh is empty
#' (`NULL`, or no vertices/faces) so the caller can collect empty labels, and
#' `FALSE` when it carries data.
#' @noRd
#' @keywords internal
validate_one_mesh <- function(mesh, label, tract) {
  if (is.null(mesh)) {
    return(TRUE)
  }

  if (!is.list(mesh) || !all(c("vertices", "faces") %in% names(mesh))) {
    cli::cli_abort(
      "Mesh for {.val {label}} needs {.field vertices} and {.field faces}."
    )
  }

  if (mesh_geometry_empty(mesh, label)) {
    return(TRUE)
  }

  if (tract && !is.null(mesh$metadata)) {
    validate_tract_metadata(mesh$metadata, label)
  }

  FALSE
}


#' Validate a mesh's vertices and faces sub-tables
#'
#' Aborts on a malformed sub-table. Returns `TRUE` if either table has no rows
#' (so the caller treats the mesh as empty).
#' @noRd
#' @keywords internal
mesh_geometry_empty <- function(mesh, label) {
  validate_mesh_part(mesh$vertices, label, "vertices", c("x", "y", "z"))
  if (nrow(mesh$vertices) == 0) {
    return(TRUE)
  }
  validate_mesh_part(mesh$faces, label, "faces", c("i", "j", "k"))
  nrow(mesh$faces) == 0
}


#' A mesh sub-table must be a data.frame containing `cols`
#' @noRd
#' @keywords internal
validate_mesh_part <- function(part, label, kind, cols) {
  if (!is.data.frame(part) || !all(cols %in% names(part))) {
    cli::cli_abort(c(
      "Mesh {kind} for {.val {label}} must be a data.frame.",
      "i" = "Required columns: {.field {cols}}."
    ))
  }
}


#' Validate tract mesh metadata
#' @param metadata metadata list to validate
#' @param label label for error messages
#' @return No return value, called for side effects
#' @keywords internal
#' @noRd
validate_tract_metadata <- function(metadata, label) {
  if (!is.list(metadata)) {
    cli::cli_warn("Mesh metadata for {.val {label}} should be a list.")
    return(invisible())
  }

  recommended <- c("n_centerline_points", "centerline", "tangents")
  missing <- setdiff(recommended, names(metadata))

  if (length(missing) > 0 && length(missing) < length(recommended)) {
    cli::cli_warn(
      "Mesh metadata for {.val {label}} missing: {.field {missing}}. ",
      "Orientation coloring may not work."
    )
  }
}


#' Validate data labels against core
#'
#' 3D sources (vertices, meshes, centerlines) are validated strictly: every
#' core label must have a corresponding entry. This check always runs.
#'
#' 2D coverage is *reported*, never enforced. Partial 2D coverage is a normal
#' property of an atlas, not a defect: no single slice contains every
#' structure, and narrowing an atlas to one view legitimately drops geometry
#' while `core` stays whole. Deciding that a freshly *built* atlas has too
#' little geometry is a construction-pipeline judgement and lives in
#' ggseg.extra. When `report_2d_coverage = TRUE` (the default at construction
#' time) incomplete coverage warns, so an atlas author sees it; the object is
#' valid either way.
#'
#' During manipulation (view removal, region cleanup) coverage naturally
#' drops, so `rebuild_atlas` calls with `report_2d_coverage = FALSE`.
#'
#' Labels in data that are not in core are always allowed — these represent
#' context-only geometry (like medial wall) that renders grey without
#' appearing in legends.
#'
#' @param data ggseg_atlas_data object
#' @param core core data.frame
#' @param report_2d_coverage if TRUE, warn when 2D geometry covers fewer than
#'   90 percent of core labels
#' @return data (unchanged)
#' @keywords internal
#' @noRd
validate_data_labels <- function(data, core, report_2d_coverage = FALSE) {
  core_labels <- core$label[!is.na(core$label)]
  n_core <- length(core_labels)

  validate_3d_data_labels(data, core_labels)

  if (isTRUE(report_2d_coverage) && n_core > 0) {
    report_2d_label_coverage(data, core_labels, n_core)
  }

  data
}


#' Validate 3D source labels (vertices, meshes, centerlines) against core
#'
#' Every core label must have a corresponding entry in each present 3D source.
#' Aborts via [cli::cli_abort()] when any are missing.
#' @keywords internal
#' @noRd
validate_3d_data_labels <- function(data, core_labels) {
  has_vertices <- !is.null(data$vertices)
  has_meshes <- !is.null(data$meshes)

  if (has_vertices && has_meshes) {
    combined_labels <- unique(c(data$vertices$label, data$meshes$label))
    validate_3d_labels(combined_labels, core_labels, "vertices+meshes")
  } else if (has_vertices) {
    validate_3d_labels(data$vertices$label, core_labels, "vertices")
  } else if (has_meshes) {
    validate_3d_labels(data$meshes$label, core_labels, "meshes")
  }

  if (!is.null(data$centerlines)) {
    validate_3d_labels(data$centerlines$label, core_labels, "centerlines")
  }

  invisible(data)
}


#' Report 2D (sf/polygon) label coverage against core
#'
#' Warns when fewer than 90 percent of core labels have 2D geometry. This is
#' informational only: it never makes the atlas invalid. A hard coverage floor
#' used to live here and was wrong for any derived atlas — one view of
#' `aseg()` carries 52 percent of the labels and is a perfectly good atlas.
#' The construction-time equivalent belongs to the atlas-building pipeline in
#' ggseg.extra.
#' @keywords internal
#' @noRd
report_2d_label_coverage <- function(data, core_labels, n_core) {
  twod_source <- geom_from_data(data)
  if (is.null(twod_source)) {
    return(invisible(data))
  }

  # nolint start: object_usage_linter
  twod_kind <- if (inherits(twod_source, "brain_polygons")) {
    "polygons"
  } else {
    "sf"
  }
  # nolint end

  twod_labels <- unique(twod_source$label[!is.na(twod_source$label)])
  missing <- setdiff(core_labels, twod_labels)
  coverage <- 1 - length(missing) / n_core

  if (coverage < 0.9) {
    cli::cli_warn(
      c(
        "{twod_kind} covers only {.strong {round(coverage * 100)}%} of core
        labels.",
        "i" = "Missing from {twod_kind}: {.val {missing}}.",
        "i" = "This is informational; the atlas is still valid."
      ),
      class = "ggseg.formats_partial_2d_coverage"
    )
  }

  invisible(data)
}


#' @keywords internal
#' @noRd
validate_3d_labels <- function(labels, core_labels, source) {
  source_labels <- labels[!is.na(labels)]
  missing <- setdiff(core_labels, source_labels)
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "All core labels must have corresponding {.field {source}} data.",
      "i" = "Missing from {source}: {.val {missing}}."
    ))
  }
}


#' Validate palette
#' @param palette named character vector of colours
#' @param core core data.frame
#' @return palette (unchanged)
#' @keywords internal
#' @noRd
validate_palette <- function(palette, core) {
  if (!is.character(palette) || is.null(names(palette))) {
    cli::cli_abort("{.arg palette} must be a named character vector.")
  }

  unknown_labels <- setdiff(names(palette), core$label)
  if (length(unknown_labels) > 0) {
    cli::cli_warn(c(
      "Some labels in {.arg palette} not found in {.arg core}.",
      "i" = "Unknown: {.val {unknown_labels}}."
    ))
  }

  palette
}
