# Legacy atlas conversion ----

#' Convert legacy ggseg atlases to ggseg_atlas format
#'
#' @description
#' `r lifecycle::badge("superseded")`
#'
#' Convert old-style ggseg (2D) and ggseg3d (3D) atlases into the new
#' `ggseg_atlas` format. This is a bridge function for working with existing
#' atlases during the transition period.
#'
#' For new atlases, use `ggsegExtra::create_cortical_atlas()` or
#' `ggsegExtra::create_subcortical_atlas()`
#' instead - they produce better results with proper vertex indices.
#'
#' The function handles three scenarios:
#' - **Both 2D and 3D**: Merges geometry with vertex data
#' - **3D only**: Extracts vertices, infers indices from mesh coordinates
#' - **2D only**: Keeps geometry, 3D rendering unavailable
#'
#' If the 3D atlas already contains vertex indices (newer ggseg3d atlases),
#' those are preserved. Otherwise, vertex indices are inferred from mesh
#' coordinates using hash-based matching (no FreeSurfer needed).
#'
#' @param atlas_2d A `ggseg_atlas` (or legacy `brain_atlas`) with 2D geometry,
#'   or NULL.
#' @param atlas_3d A `ggseg3d_atlas` with mesh data, or NULL.
#' @param atlas_name Name for the output atlas. If NULL, derived from input.
#' @param type Atlas type: `"cortical"` or `"subcortical"`. If NULL, inferred
#'   from the input atlases.
#' @param surface Which surface to match against when inferring vertices
#'   (e.g., `"inflated"`). Must match the 3D atlas surface exactly.
#' @param brain_meshes Optional user-supplied brain meshes for vertex
#'   inference.
#'
#' @return A `ggseg_atlas` object.
#' @export
#' @importFrom rlang %||%
#'
#' @examples
#' \donttest{
#' new_atlas <- convert_legacy_brain_atlas(atlas_2d = dk())
#' }
convert_legacy_brain_atlas <- function(
  atlas_2d = NULL,
  atlas_3d = NULL,
  atlas_name = NULL,
  type = NULL,
  surface = "inflated",
  brain_meshes = NULL
) {
  lifecycle::signal_stage("superseded", "convert_legacy_brain_atlas()")

  has_2d <- !is.null(atlas_2d)
  has_3d <- !is.null(atlas_3d)

  validate_legacy_inputs(has_2d, has_3d, atlas_2d, atlas_3d)

  original_palette <- if (has_2d) atlas_2d$palette else NULL

  if (has_2d && is.null(atlas_2d$core)) {
    atlas_2d <- convert_legacy_brain_data(atlas_2d) # nolint: object_usage_linter
  }

  setup <- legacy_atlas_setup(has_2d, atlas_2d, atlas_3d, atlas_name, type)

  result <- collect_legacy_atlas_parts(
    has_3d,
    atlas_2d,
    atlas_3d,
    setup$type,
    surface,
    brain_meshes,
    core = setup$core,
    palette = setup$palette,
    sf_data = setup$sf_data
  )

  assemble_legacy_atlas(setup, result, original_palette)
}


#' @rdname convert_legacy_brain_atlas
#' @export
unify_legacy_atlases <- function(
  atlas_2d = NULL,
  atlas_3d = NULL,
  atlas_name = NULL,
  type = NULL,
  surface = "inflated",
  brain_meshes = NULL
) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "unify_legacy_atlases()",
    "convert_legacy_brain_atlas()"
  )
  convert_legacy_brain_atlas(
    atlas_2d = atlas_2d,
    atlas_3d = atlas_3d,
    atlas_name = atlas_name,
    type = type,
    surface = surface,
    brain_meshes = brain_meshes
  )
}


#' @noRd
#' @keywords internal
validate_legacy_inputs <- function(has_2d, has_3d, atlas_2d, atlas_3d) {
  if (!has_2d && !has_3d) {
    cli::cli_abort(
      "At least one of {.arg atlas_2d} or {.arg atlas_3d} must be provided."
    )
  }
  if (
    has_2d &&
      !inherits(atlas_2d, "brain_atlas") &&
      !inherits(atlas_2d, "ggseg_atlas")
  ) {
    cli::cli_abort("{.arg atlas_2d} must be a {.cls ggseg_atlas} object.")
  }
  if (has_3d && !("ggseg_3d" %in% names(atlas_3d))) {
    cli::cli_abort(
      "{.arg atlas_3d} must have a {.field ggseg_3d} column."
    )
  }
}


#' @noRd
#' @keywords internal
extract_2d_sf <- function(has_2d, atlas_2d) {
  if (!has_2d) {
    return(NULL)
  }
  geom <- if (inherits(atlas_2d$data, "ggseg_atlas_data")) {
    geom_from_data(atlas_2d$data)
  } else {
    NULL
  }
  if (!is.null(geom)) geom else atlas_2d$sf
}


#' @noRd
#' @keywords internal
extract_3d_data <- function(
  atlas_3d,
  type,
  surface,
  brain_meshes,
  core,
  palette,
  sf_data
) {
  dt <- df_unnest(atlas_3d, "ggseg_3d")

  if (is.null(core)) {
    core <- df_distinct(
      dt[!is.na(dt$label), ],
      c("hemi", "region", "label")
    )
  }
  if (is.null(palette) && "colour" %in% names(dt)) {
    palette <- stats::setNames(dt$colour, dt$label)
    palette <- palette[!is.na(names(palette)) & !duplicated(names(palette))]
  }

  meshes <- NULL
  vertices <- NULL

  if (type %in% c("subcortical", "tract") && "mesh" %in% names(dt)) {
    meshes <- extract_meshes_from_rgl(dt)
    cli::cli_inform(c("i" = "Extracted meshes from 3D atlas."))
  } else if (has_vertex_data(dt)) {
    vertices <- data.frame(label = dt$label)
    vertices$vertices <- dt$vertices
    cli::cli_inform(
      c("i" = "Using existing vertex indices from 3D atlas.")
    )
  } else if (type == "cortical") {
    vertices <- try_infer_vertices(atlas_3d, surface, brain_meshes, sf_data)
  }

  list(core = core, palette = palette, vertices = vertices, meshes = meshes)
}


#' @noRd
#' @keywords internal
extract_meshes_from_rgl <- function(dt) {
  meshes_df <- data.frame(label = dt$label)
  meshes_df$mesh <- lapply(seq_len(nrow(dt)), function(i) {
    m <- dt$mesh[[i]]
    if (is.null(m)) {
      return(NULL)
    }
    convert_rgl_mesh(m)
  })
  meshes_df
}


#' @noRd
#' @keywords internal
convert_rgl_mesh <- function(m) {
  list(
    vertices = data.frame(
      x = if ("vb" %in% names(m)) m$vb[1, ] else m$vertices$x,
      y = if ("vb" %in% names(m)) m$vb[2, ] else m$vertices$y,
      z = if ("vb" %in% names(m)) m$vb[3, ] else m$vertices$z
    ),
    faces = data.frame(
      i = if ("it" %in% names(m)) m$it[1, ] else m$faces$i,
      j = if ("it" %in% names(m)) m$it[2, ] else m$faces$j,
      k = if ("it" %in% names(m)) m$it[3, ] else m$faces$k
    )
  )
}


#' @noRd
#' @keywords internal
try_infer_vertices <- function(atlas_3d, surface, brain_meshes, sf_data) {
  vertices_list <- infer_vertices_from_meshes(
    atlas_3d,
    surface = surface,
    brain_meshes = brain_meshes
  )
  if (!is.null(vertices_list)) {
    vertices_df <- data.frame(
      label = names(vertices_list)
    )
    vertices_df$vertices <- unname(vertices_list)
    cli::cli_inform(
      c("i" = "Inferred vertex indices from mesh coordinates.")
    )
    return(vertices_df)
  }

  cli::cli_warn(c(
    "Could not infer vertex indices from mesh data.",
    "i" = "For best results, recreate with {.fn create_cortical_atlas}."
  ))
  if (is.null(sf_data)) {
    cli::cli_abort(c(
      "Cannot create cortical atlas without vertices or 2D geometry.",
      "i" = "Recreate with {.fn create_cortical_atlas}."
    ))
  }
  NULL
}


#' @noRd
#' @keywords internal
extract_2d_data <- function(atlas_2d) {
  vertices <- NULL
  if (
    !is.null(atlas_2d$data$vertices) &&
      "vertices" %in% names(atlas_2d$data$vertices)
  ) {
    vertices <- atlas_2d$data$vertices
    cli::cli_inform(
      c("i" = "Using existing vertex data from 2D atlas.")
    )
  } else {
    cli::cli_inform(
      c("i" = "Created atlas from 2D only; 3D rendering needs vertex data.")
    )
  }
  list(core = NULL, palette = NULL, vertices = vertices, meshes = NULL)
}


#' @noRd
#' @keywords internal
build_atlas_data <- function(type, sf_data, vertices_df, meshes_df) {
  switch(
    type,
    "cortical" = ggseg_data_cortical(
      geom = sf_data,
      vertices = vertices_df
    ),
    "subcortical" = ggseg_data_subcortical(
      geom = sf_data,
      meshes = meshes_df
    ),
    "tract" = ggseg_data_tract(geom = sf_data, meshes = meshes_df),
    ggseg_data_cortical(geom = sf_data, vertices = vertices_df)
  )
}


#' @noRd
#' @keywords internal
infer_atlas_type <- function(has_2d, atlas_2d, atlas_3d) {
  if (has_2d) {
    return(atlas_2d$type)
  }
  if (any(atlas_3d$hemi == "subcort")) {
    return("subcortical")
  }
  "cortical"
}


#' @noRd
#' @keywords internal
has_vertex_data <- function(dt) {
  if (!("vertices" %in% names(dt))) {
    return(FALSE)
  }
  !all(vapply(dt$vertices, length, integer(1)) == 0)
}


#' @noRd
#' @keywords internal
remap_palette_to_labels <- function(palette, core) {
  if (is.null(palette)) {
    return(NULL)
  }

  new_palette <- unlist(lapply(names(palette), function(region_name) {
    labels <- core$label[!is.na(core$region) & core$region == region_name]
    stats::setNames(rep(unname(palette[region_name]), length(labels)), labels)
  }))
  if (length(new_palette) == 0) NULL else new_palette
}


#' Infer vertex indices by matching mesh coordinates to brain surface
#'
#' @description
#' Hash-based O(n+m) matching that rounds coordinates to 4 decimal places
#' and uses named vector lookup. Interpolated triangulation vertices that
#' don't match exactly are silently skipped.
#'
#' @param atlas_3d A `ggseg3d_atlas` with mesh data.
#' @param surface Which surface to match against (default `"inflated"`).
#' @param brain_meshes Brain mesh data to match against. If NULL, uses the
#'   internal inflated mesh. Supports both `list(lh = ..., rh = ...)` and
#'   `list(lh_inflated = ..., ...)` formats.
#' @return Named list of integer vertex indices (0-based) keyed by label,
#'   or NULL if brain_meshes unavailable.
#' @noRd
#' @keywords internal
infer_vertices_from_meshes <- function(
  atlas_3d,
  surface = "inflated",
  brain_meshes = NULL
) {
  hemi_map <- c("left" = "lh", "right" = "rh")
  vertices_list <- list()

  for (hemi in c("left", "right")) {
    brain_mesh <- get_brain_mesh(
      hemisphere = hemi_map[hemi],
      surface = surface,
      brain_meshes = brain_meshes
    )
    if (is.null(brain_mesh)) {
      next
    }
    row_idx <- which(atlas_3d$hemi == hemi & atlas_3d$surf == surface)
    if (length(row_idx) == 0) {
      next
    }
    ggseg <- atlas_3d$ggseg_3d[[row_idx]]
    if (!"mesh" %in% names(ggseg)) {
      next
    }

    matched_list <- match_ggseg_vertices(ggseg, mesh_vertex_index(brain_mesh))
    vertices_list[names(matched_list)] <- matched_list
  }

  if (length(vertices_list) == 0) NULL else vertices_list
}


#' Coordinate-key -> 0-based vertex index lookup for a surface mesh
#' @noRd
#' @keywords internal
mesh_vertex_index <- function(brain_mesh) {
  coords <- as.matrix(brain_mesh$vertices)
  keys <- coord_keys(coords)
  stats::setNames(seq_len(nrow(coords)) - 1L, keys)
}


#' Rounded "x y z" coordinate keys for a 3-column coordinate matrix
#' @noRd
#' @keywords internal
coord_keys <- function(coords) {
  paste(
    round(coords[, 1], 4),
    round(coords[, 2], 4),
    round(coords[, 3], 4)
  )
}


#' Region vertex coordinates from a mesh (rgl `vb` or a vertices data.frame)
#'
#' Returns a 3-column matrix, or `NULL` if the mesh carries no usable vertices.
#' @noRd
#' @keywords internal
region_coords_from_mesh <- function(m) {
  if ("vb" %in% names(m)) {
    cbind(m$vb[1, ], m$vb[2, ], m$vb[3, ])
  } else if ("vertices" %in% names(m) && !is.null(m$vertices)) {
    as.matrix(m$vertices)
  } else {
    NULL
  }
}


#' Match each region's mesh vertices to brain-surface vertex indices
#'
#' Returns a named list mapping region `label` to integer vertex indices.
#' @noRd
#' @keywords internal
match_ggseg_vertices <- function(ggseg, brain_index) {
  out <- list()
  for (i in seq_len(nrow(ggseg))) {
    region_coords <- region_coords_from_mesh(ggseg$mesh[[i]])
    if (is.null(region_coords)) {
      next
    }
    matched <- brain_index[coord_keys(region_coords)]
    matched <- unique(unname(matched[!is.na(matched)]))
    if (length(matched) > 0) {
      out[[ggseg$label[i]]] <- as.integer(matched)
    }
  }
  out
}


#' Resolve atlas name, type, sf, core and palette from legacy inputs
#' @noRd
#' @keywords internal
legacy_atlas_setup <- function(
  has_2d,
  atlas_2d,
  atlas_3d,
  atlas_name,
  type
) {
  atlas_name <- atlas_name %||%
    (if (has_2d) atlas_2d$atlas else gsub("_3d$", "", atlas_3d$atlas[1]))
  type <- type %||% infer_atlas_type(has_2d, atlas_2d, atlas_3d)
  list(
    atlas_name = atlas_name,
    type = type,
    sf_data = extract_2d_sf(has_2d, atlas_2d),
    core = if (has_2d) atlas_2d$core else NULL,
    palette = if (has_2d) atlas_2d$palette else NULL
  )
}


#' Build the final ggseg_atlas from setup and extracted result parts
#' @noRd
#' @keywords internal
assemble_legacy_atlas <- function(setup, result, original_palette) {
  core <- fill_legacy_core_names(result$core %||% setup$core)
  palette <- resolve_legacy_palette(
    result$palette %||% setup$palette,
    original_palette,
    core
  )
  data <- build_atlas_data(
    setup$type,
    setup$sf_data,
    result$vertices,
    result$meshes
  )
  ggseg_atlas(
    atlas = setup$atlas_name,
    type = setup$type,
    palette = palette,
    core = core,
    data = data
  )
}


#' Back-fill `names` on a core recovered from a legacy atlas
#'
#' A legacy atlas's `region` holds a long-form, human-readable name -- which is
#' exactly the contract `names` carries in the current schema -- so copying it
#' across leaves the converted atlas schema-complete instead of missing a
#' required column, and gives it a sensible display name rather than a
#' placeholder. This is unrelated to `legacy_region_map()`, which translates the
#' *bundled* atlases' old keys and reads its own recorded table.
#' @noRd
#' @keywords internal
fill_legacy_core_names <- function(core) {
  if (is.null(core) || "names" %in% names(core) || !"region" %in% names(core)) {
    return(core)
  }
  core$names <- core$region
  core
}


#' Collect core/palette/vertices/meshes from 2D or 3D legacy inputs
#' @noRd
#' @keywords internal
collect_legacy_atlas_parts <- function(
  has_3d,
  atlas_2d,
  atlas_3d,
  type,
  surface,
  brain_meshes,
  core,
  palette,
  sf_data
) {
  if (has_3d) {
    extract_3d_data(
      atlas_3d,
      type,
      surface,
      brain_meshes,
      core = core,
      palette = palette,
      sf_data = sf_data
    )
  } else {
    extract_2d_data(atlas_2d)
  }
}


#' Ensure a palette covers the core labels, remapping from regions if needed
#' @noRd
#' @keywords internal
resolve_legacy_palette <- function(palette, original_palette, core) {
  if (is.null(palette) || !any(names(palette) %in% core$label)) {
    palette <- remap_palette_to_labels(original_palette, core)
  }
  palette
}
