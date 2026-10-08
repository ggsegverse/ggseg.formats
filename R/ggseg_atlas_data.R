#' Create cortical atlas data
#'
#' Creates a data object for cortical brain atlases. Cortical atlases use
#' vertex indices that map regions to vertices on a shared brain surface mesh
#' (e.g., fsaverage5).
#'
#' @template geom
#' @param vertices data.frame with columns label and vertices (list-column of
#'   integer vectors). Each vector contains vertex indices for that region.
#' @template geom_dots
#'
#' @return An object of class c("ggseg_data_cortical", "ggseg_atlas_data")
#' @export
#'
#' @examples
#' data <- ggseg_data_cortical(
#'   vertices = data.frame(
#'     label = c("bankssts", "caudalanteriorcingulate"),
#'     vertices = I(list(c(1L, 2L, 3L), c(4L, 5L, 6L)))
#'   )
#' )
ggseg_data_cortical <- function(geom = NULL, vertices = NULL, ...) {
  geom <- resolve_geom(geom, ..., .fn = "ggseg_data_cortical")

  if (is.null(geom) && is.null(vertices)) {
    cli::cli_abort(
      "At least one of {.arg geom} or {.arg vertices} is required."
    )
  }

  if (!is.null(vertices)) {
    vertices <- validate_vertices(vertices)
  }

  structure(
    list(
      geom = geom,
      vertices = vertices
    ),
    class = c("ggseg_data_cortical", "ggseg_atlas_data")
  )
}


#' Create subcortical atlas data
#'
#' Creates a data object for subcortical brain atlases. Subcortical atlases
#' use individual 3D meshes for each structure (e.g., hippocampus, amygdala).
#'
#' @template geom
#' @param meshes data.frame with columns label and mesh (list-column).
#'   Each mesh is a list with:
#'   \itemize{
#'     \item vertices: data.frame with x, y, z columns
#'     \item faces: data.frame with i, j, k columns (1-based triangle indices)
#'   }
#' @template geom_dots
#'
#' @return An object of class c("ggseg_data_subcortical", "ggseg_atlas_data")
#' @export
#'
#' @examples
#' data <- ggseg_data_subcortical(
#'   meshes = data.frame(
#'     label = "hippocampus_left",
#'     mesh = I(list(list(
#'       vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
#'       faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
#'     )))
#'   )
#' )
ggseg_data_subcortical <- function(geom = NULL, meshes = NULL, ...) {
  geom <- resolve_geom(geom, ..., .fn = "ggseg_data_subcortical")

  if (is.null(geom) && is.null(meshes)) {
    cli::cli_abort("At least one of {.arg geom} or {.arg meshes} is required.")
  }

  if (!is.null(meshes)) {
    meshes <- validate_meshes(meshes)
  }

  structure(
    list(
      geom = geom,
      meshes = meshes
    ),
    class = c("ggseg_data_subcortical", "ggseg_atlas_data")
  )
}


#' Create cerebellar atlas data
#'
#' Creates a data object for cerebellar brain atlases. Cerebellar atlases
#' use sf polygons from a SUIT flatmap for 2D rendering and vertex indices
#' into the shared SUIT cerebellar surface mesh for 3D rendering.
#'
#' The shared mesh (see [get_cerebellar_mesh()]) includes a cap over the
#' peduncular surface where the cerebellum meets the brainstem. Vertices
#' on this cap (indices 28,935--30,012) are not assigned to any atlas
#' region and render as `na_colour` in 3D, analogous to the medial wall
#' in cortical atlases.
#'
#' Deep cerebellar structures (e.g. dentate, interposed, fastigial nuclei)
#' that are not on the cortical surface are stored as individual per-region
#' meshes in `meshes`, following the same format as subcortical atlases.
#' Their 2D sf geometries use views other than "flatmap" (e.g. "nuclei").
#'
#' @template geom
#' @param vertices data.frame with columns label and vertices (list-column of
#'   integer vectors). Each vector contains 0-based vertex indices into the
#'   SUIT cerebellar surface (see [get_cerebellar_mesh()]). Only for surface
#'   regions.
#' @param meshes Optional data.frame with columns label and mesh (list-column
#'   of mesh objects with vertices and faces). For deep cerebellar structures
#'   that are not on the cortical surface. Same format as
#'   [ggseg_data_subcortical()] meshes.
#' @template geom_dots
#'
#' @return An object of class c("ggseg_data_cerebellar", "ggseg_atlas_data")
#' @export
#'
#' @examples
#' data <- ggseg_data_cerebellar(
#'   vertices = data.frame(
#'     label = c("lobule_I", "lobule_II"),
#'     vertices = I(list(c(1L, 2L, 3L), c(4L, 5L, 6L)))
#'   )
#' )
ggseg_data_cerebellar <- function(
  geom = NULL,
  vertices = NULL,
  meshes = NULL,
  ...
) {
  geom <- resolve_geom(geom, ..., .fn = "ggseg_data_cerebellar")

  if (is.null(geom) && is.null(vertices) && is.null(meshes)) {
    cli::cli_abort(
      "At least one of {.arg geom}, {.arg vertices}, or {.arg meshes} is
       required."
    )
  }

  if (!is.null(vertices)) {
    vertices <- validate_vertices(vertices)
  }

  if (!is.null(meshes)) {
    meshes <- validate_meshes(meshes)
  }

  structure(
    list(
      geom = geom,
      vertices = vertices,
      meshes = meshes
    ),
    class = c("ggseg_data_cerebellar", "ggseg_atlas_data")
  )
}


#' Create tract atlas data
#'
#' Creates a data object for white matter tract atlases. Stores centerlines
#' compactly; tube meshes are generated at render time for efficiency.
#'
#' @template geom
#' @param centerlines data.frame with columns:
#'   \itemize{
#'     \item label: tract identifier (character)
#'     \item points: list-column of n x 3 matrices (centerline coordinates)
#'     \item tangents: list-column of n x 3 matrices (for orientation coloring)
#'   }
#' @param meshes `r lifecycle::badge("deprecated")` Use `centerlines` instead.
#'   If supplied, it is converted to the centerlines format.
#' @param ... Captures a deprecated `sf` argument (converted to polygons) and
#'   absorbs legacy fields (e.g. tube_radius, tube_segments) from old cached
#'   atlas objects.
#'
#' @return An object of class c("ggseg_data_tract", "ggseg_atlas_data")
#' @export
#'
#' @examples
#' centerlines_df <- data.frame(
#'   label = "cst_left",
#'   points = I(list(matrix(rnorm(150), ncol = 3))),
#'   tangents = I(list(matrix(rnorm(150), ncol = 3)))
#' )
#' data <- ggseg_data_tract(centerlines = centerlines_df)
ggseg_data_tract <- function(
  geom = NULL,
  centerlines = NULL,
  meshes = NULL,
  ...
) {
  if (!is.null(meshes)) {
    lifecycle::deprecate_warn(
      "0.1.0",
      "ggseg_data_tract(meshes)",
      "ggseg_data_tract(centerlines)",
      details = "Tube meshes are converted to centerlines via
                 `meshes_to_centerlines()`."
    )
    if (is.null(centerlines)) {
      centerlines <- meshes_to_centerlines(meshes)
    }
  }

  geom <- resolve_geom(geom, ..., .fn = "ggseg_data_tract")

  if (is.null(geom) && is.null(centerlines)) {
    cli::cli_abort(
      "At least one of {.arg geom} or {.arg centerlines} is required."
    )
  }

  if (!is.null(centerlines)) {
    centerlines <- validate_centerlines(centerlines)
  }

  structure(
    list(
      geom = geom,
      centerlines = centerlines
    ),
    class = c("ggseg_data_tract", "ggseg_atlas_data")
  )
}


#' @export
print.ggseg_data_cortical <- function(x, n = 10, ...) {
  cli::cli_h2("ggseg_data_cortical")

  twod_summary <- summarise_2d(x) # nolint: object_usage_linter
  if (!is.null(twod_summary)) {
    cli::cli_text(twod_summary)
  }

  if (!is.null(x$vertices)) {
    cli::cli_text("{.strong 3D (ggseg3d):} vertex indices")
    print_data_head(x$vertices, n)
  }

  invisible(x)
}


#' @export
print.ggseg_data_subcortical <- function(x, n = 10, ...) {
  cli::cli_h2("ggseg_data_subcortical")

  twod_summary <- summarise_2d(x) # nolint: object_usage_linter
  if (!is.null(twod_summary)) {
    cli::cli_text(twod_summary)
  }

  if (!is.null(x$meshes)) {
    cli::cli_text("{.strong 3D (ggseg3d):} meshes")
    print_mesh_summary(x$meshes, n)
  }

  invisible(x)
}


#' @export
print.ggseg_data_cerebellar <- function(x, n = 10, ...) {
  cli::cli_h2("ggseg_data_cerebellar")

  twod_summary <- summarise_2d(x) # nolint: object_usage_linter
  if (!is.null(twod_summary)) {
    cli::cli_text(twod_summary)
  }

  if (!is.null(x$vertices)) {
    cli::cli_text("{.strong 3D (ggseg3d):} vertex indices (SUIT surface)")
    print_data_head(x$vertices, n)
  }

  invisible(x)
}


#' @export
print.ggseg_data_tract <- function(x, ...) {
  cli::cli_h2("ggseg_data_tract")

  twod_summary <- summarise_2d(x) # nolint: object_usage_linter
  if (!is.null(twod_summary)) {
    cli::cli_text(twod_summary)
  }

  if (!is.null(x$centerlines)) {
    n_tracts <- nrow(x$centerlines) # nolint: object_usage_linter
    total_points <- sum(vapply(x$centerlines$points, nrow, integer(1))) # nolint
    cli::cli_text(
      "{.strong 3D (ggseg3d):} {n_tracts} centerlines ({total_points} points)"
    )
  }

  invisible(x)
}


# Deprecated wrappers ----

#' @param sf Deprecated. Pass 2D geometry via `geom` instead.
#' @rdname ggseg_data_cortical
#' @export
brain_data_cortical <- function(sf = NULL, vertices = NULL) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "brain_data_cortical()",
    "ggseg_data_cortical()"
  )
  ggseg_data_cortical(sf = sf, vertices = vertices)
}


#' @param sf Deprecated. Pass 2D geometry via `geom` instead.
#' @rdname ggseg_data_subcortical
#' @export
brain_data_subcortical <- function(sf = NULL, meshes = NULL) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "brain_data_subcortical()",
    "ggseg_data_subcortical()"
  )
  ggseg_data_subcortical(sf = sf, meshes = meshes)
}


#' @param sf Deprecated. Pass 2D geometry via `geom` instead.
#' @rdname ggseg_data_tract
#' @export
brain_data_tract <- function(
  sf = NULL,
  centerlines = NULL,
  meshes = NULL,
  ...
) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "brain_data_tract()",
    "ggseg_data_tract()"
  )
  ggseg_data_tract(
    sf = sf,
    centerlines = centerlines,
    meshes = meshes
  )
}


#' Convert legacy meshes to centerlines format
#' @noRd
#' @keywords internal
meshes_to_centerlines <- function(meshes) {
  if (is.null(meshes)) {
    return(NULL)
  }

  centerlines_list <- lapply(seq_len(nrow(meshes)), function(i) {
    mesh <- meshes$mesh[[i]]
    metadata <- mesh$metadata

    if (is.null(metadata) || is.null(metadata$centerline)) {
      cli::cli_warn(
        "Mesh for {meshes$label[i]} missing centerline metadata, skipping"
      )
      return(NULL)
    }

    data.frame(
      label = meshes$label[i],
      points = I(list(metadata$centerline)),
      tangents = I(list(metadata$tangents))
    )
  })

  centerlines_list <- centerlines_list[
    !vapply(centerlines_list, is.null, logical(1))
  ]
  if (length(centerlines_list) == 0) {
    cli::cli_abort("No valid centerlines could be extracted from meshes")
  }

  do.call(rbind, centerlines_list)
}


#' Validate centerlines data frame
#' @noRd
#' @keywords internal
validate_centerlines <- function(centerlines) {
  required_cols <- c("label", "points")
  missing <- setdiff(required_cols, names(centerlines))
  if (length(missing) > 0) {
    cli::cli_abort(
      "Centerlines missing required columns: {.val {missing}}"
    )
  }

  if (!is.list(centerlines$points)) {
    cli::cli_abort("{.arg points} must be a list-column of matrices")
  }

  for (i in seq_len(nrow(centerlines))) {
    pts <- centerlines$points[[i]]
    if (!is.matrix(pts) || ncol(pts) != 3) {
      cli::cli_abort(
        "points[[{i}]] must be an n x 3 matrix, got {class(pts)[1]}"
      )
    }
  }

  if (!"tangents" %in% names(centerlines)) {
    centerlines$tangents <- lapply(centerlines$points, compute_tangents)
  }

  centerlines
}


#' Compute tangent vectors from centerline points
#' @noRd
#' @keywords internal
compute_tangents <- function(points) {
  n <- nrow(points)

  # Finite differences: forward at the first point, backward at the last,
  # central in between.
  diffs <- matrix(0, nrow = n, ncol = 3)
  diffs[1, ] <- points[2, ] - points[1, ]
  diffs[n, ] <- points[n, ] - points[n - 1, ]
  if (n > 2) {
    mid <- 2:(n - 1)
    diffs[mid, ] <- points[mid + 1, , drop = FALSE] -
      points[mid - 1, , drop = FALSE]
  }

  norms <- sqrt(rowSums(diffs^2))
  tangents <- diffs / norms
  degenerate <- norms == 0
  if (any(degenerate)) {
    tangents[degenerate, ] <- matrix(
      c(1, 0, 0),
      nrow = sum(degenerate),
      ncol = 3,
      byrow = TRUE
    )
  }
  tangents
}

#' Summarise 2D atlas data for printing
#' @noRd
#' @keywords internal
summarise_2d <- function(x) {
  src <- geom_from_data(x)
  if (is.null(src)) {
    return(NULL)
  }
  kind <- if (inherits(src, "brain_polygons")) "polygons" else "sf"
  n_labels <- length(unique(src$label))
  if (kind == "sf") {
    views <- toString(unique(src$view))
  } else {
    views <- toString(
      unique(unlist(lapply(src$geometry, function(g) g$view)))
    )
  }
  sprintf(
    "{.strong 2D (ggseg):} %d labels (%s), views: %s",
    n_labels,
    kind,
    views
  )
}


#' @noRd
#' @keywords internal
print_mesh_summary <- function(meshes, n = 10) {
  summary_df <- data.frame(
    label = meshes$label,
    vertices = vapply(
      meshes$mesh,
      function(m) {
        if (is.null(m)) 0L else nrow(m$vertices)
      },
      integer(1)
    ),
    faces = vapply(
      meshes$mesh,
      function(m) {
        if (is.null(m)) 0L else nrow(m$faces)
      },
      integer(1)
    )
  )
  print_data_head(summary_df, n)
}
