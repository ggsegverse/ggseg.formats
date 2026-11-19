#' Get the core table of an atlas
#'
#' Returns the `core` data frame: one row per region, carrying `label` (the
#' key the palette and every geometry slot join on), `region`, `hemi`, and
#' whatever grouping or metadata columns the atlas curates (`display`, `lobe`,
#' `network`, `structure`).
#'
#' @param atlas a `ggseg_atlas` object
#' @return A data frame with one row per region.
#' @family atlas accessors
#' @seealso [atlas_labels()] and [atlas_regions()] for single columns of it,
#'   [atlas_core_add()] to add columns to it.
#' @export
#' @examples
#' head(atlas_core(dk()))
#' nrow(atlas_core(aseg()))
atlas_core <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  atlas_slot(atlas, "core")
}


#' Get the geometry payload of an atlas
#'
#' Returns the whole `ggseg_data_*` payload. Prefer the accessor for the
#' geometry you actually want -- [atlas_geom()], [atlas_sf()],
#' [atlas_polygons()], [atlas_vertices()], [atlas_meshes()],
#' [atlas_centerlines()] -- and reach for this only when the payload itself is
#' the subject.
#'
#' @param atlas a `ggseg_atlas` object
#' @return A `ggseg_atlas_data` object.
#' @family atlas accessors
#' @export
#' @examples
#' class(atlas_data(dk()))
atlas_data <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  atlas_slot(atlas, "data")
}


#' Get the short name of an atlas
#'
#' Returns the atlas's own name, the one it is published and cited under --
#' `"dk"`, `"aseg"`, `"schaefer17_100"`. Named `atlas_name()` rather than
#' `atlas_atlas()`, which is what the slot would suggest.
#'
#' @param atlas a `ggseg_atlas` object
#' @return A length-one character vector.
#' @family atlas accessors
#' @export
#' @examples
#' atlas_name(dk())
#' atlas_name(aseg())
atlas_name <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  atlas_slot(atlas, "atlas")
}


#' Get the palette of an atlas
#'
#' Retrieves the colour palette from a brain atlas: a named character vector
#' mapping region `label`s to colours. To change the palette, use the
#' [set_atlas_palette()] setter.
#'
#' @param atlas a `ggseg_atlas` object
#' @param ... Additional arguments (unused)
#'
#' @return Named character vector of colours.
#' @family atlas accessors
#' @seealso [set_atlas_palette()] to set the palette.
#' @export
#' @examples
#' atlas_palette(aseg())
#' atlas_palette(dk())
atlas_palette <- function(atlas, ...) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  atlas_slot(atlas, "palette")
}


#' Get the raw 2D geometry of an atlas
#'
#' Returns the single 2D geometry object stored in `atlas_slot(atlas, "data")$geom`, which is
#' either an sf-class data frame or a `brain_polygons` data.frame. Its class
#' determines which rendering path is used downstream.
#'
#' For backward compatibility with released atlases built before the unified
#' `geom` slot, this falls back to the legacy `sf` slot. Reverse dependencies
#' should call this accessor (or [atlas_sf()] / [atlas_polygons()]) rather than
#' reaching into `atlas_slot(atlas, "data")` directly.
#'
#' @param atlas a ggseg_atlas object
#' @return an sf or `brain_polygons` object, or `NULL` if the atlas has no 2D
#'   geometry
#' @export
#' @examples
#' g <- atlas_geom(dk())
#' atlas_geometry_type(dk())
#' @family atlas accessors
atlas_geom <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas}.")
  }
  geom_from_data(atlas_slot(atlas, "data"))
}

#' Classify or test an atlas's 2D geometry
#'
#' @param atlas a ggseg_atlas object
#' @return `atlas_geometry_type()` returns `"sf"` or `"polygon"`, and errors if
#'   the atlas has no recognised 2D geometry. `is_atlas_sf()` /
#'   `is_atlas_polygon()` return a logical scalar (`FALSE` for non-atlases).
#' @export
#' @examples
#' atlas_geometry_type(dk())
#' is_atlas_polygon(dk())
#' @family atlas accessors
atlas_geometry_type <- function(atlas) {
  geom <- atlas_geom(atlas)
  if (inherits(geom, "sf")) {
    "sf"
  } else if (inherits(geom, "brain_polygons")) {
    "polygon"
  } else {
    cli::cli_abort(
      "Atlas has no recognised 2D geometry
       ({.cls sf} or {.cls brain_polygons})."
    )
  }
}

#' @rdname atlas_geometry_type
#' @export
is_atlas_sf <- function(atlas) {
  is_ggseg_atlas(atlas) &&
    inherits(geom_from_data(atlas_slot(atlas, "data")), "sf")
}

#' @rdname atlas_geometry_type
#' @export
is_atlas_polygon <- function(atlas) {
  is_ggseg_atlas(atlas) &&
    inherits(geom_from_data(atlas_slot(atlas, "data")), "brain_polygons")
}

#' Get atlas data for 2D rendering
#'
#' Returns sf data joined with core region info and palette colours. This is
#' the interception point used by ggseg for plotting: it always returns
#' sf geometry, converting from the polygon representation when needed.
#'
#' @param atlas a ggseg_atlas object
#' @return sf data.frame ready for plotting
#' @export
#' @examplesIf requireNamespace("sf", quietly = TRUE)
#' sf_data <- atlas_sf(dk())
#' head(sf_data)
#' @family atlas accessors
atlas_sf <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas}.")
  }

  geom <- atlas_geom(atlas)
  if (is.null(geom)) {
    cli::cli_abort("Atlas does not contain 2D geometry for rendering.")
  }

  # Gate after the argument checks, so a bad atlas reports what is wrong with
  # it rather than reporting a missing optional dependency.
  require_sf("atlas_sf()")

  sf_geom <- if (inherits(geom, "brain_polygons")) {
    polygons_to_sf(geom)
  } else {
    geom
  }

  sf_data <- sf::st_as_sf(sf_geom)
  core_cols <- intersect(names(sf_data), c("hemi", "region"))
  if (length(core_cols) > 0) {
    sf_data[core_cols] <- NULL
  }

  # `sort = FALSE` keeps the geometry's row order; the default re-sorts by
  # `label`, which would discard the context-behind-core draw order that
  # `order_context_behind()` establishes upstream. Re-apply that ordering
  # afterwards so contextual rows draw behind the core regions, mirroring
  # `as.data.frame.ggseg_atlas()`.
  result <- merge(
    sf_data,
    atlas_slot(atlas, "core"),
    by = "label",
    all.x = TRUE,
    sort = FALSE
  )
  result <- order_context_behind(result, atlas_slot(atlas, "core")$label)

  if (!is.null(atlas_slot(atlas, "palette"))) {
    result$colour <- unname(atlas_slot(atlas, "palette")[result$label])
  }

  class(result) <- c("ggseg_sf", class(result))
  result
}

#' Get atlas polygons for 2D rendering
#'
#' Returns the `brain_polygons` representation of the atlas geometry,
#' converting from sf when needed. The sf-optional counterpart to [atlas_sf()].
#'
#' @param atlas a ggseg_atlas object
#' @return a `brain_polygons` data.frame
#' @export
#' @examples
#' polys <- atlas_polygons(dk())
#' @family atlas accessors
atlas_polygons <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas}.")
  }

  geom <- atlas_geom(atlas)
  if (is.null(geom)) {
    cli::cli_abort("Atlas does not contain 2D geometry for rendering.")
  }
  if (inherits(geom, "brain_polygons")) {
    return(geom)
  }
  sf_to_polygons(geom)
}


#' Get atlas vertices for 3D rendering
#'
#' Returns vertices data joined with core region info and palette colours.
#' Used for cortical atlases with vertex-based rendering.
#'
#' @param atlas a ggseg_atlas object
#' @return data.frame with vertices ready for 3D rendering
#' @export
#' @examples
#' verts <- atlas_vertices(dk())
#' head(verts)
#' @family atlas accessors
atlas_vertices <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas}.")
  }

  if (is.null(atlas_slot(atlas, "data")$vertices)) {
    cli::cli_abort("Atlas does not contain vertices for 3D rendering.")
  }

  result <- df_left_join(
    atlas_slot(atlas, "data")$vertices,
    atlas_slot(atlas, "core"),
    by = "label"
  )

  if (!is.null(atlas_slot(atlas, "palette"))) {
    result$colour <- unname(atlas_slot(atlas, "palette")[result$label])
  }

  class(result) <- c("ggseg_vertices", class(result))
  result
}


#' Get atlas tract centerlines
#'
#' Returns the centerline of each tract, joined with core region info and
#' palette colours. Tract atlases represent each pathway as a curve through
#' the bundle rather than as a surface, and render it by sweeping a tube along
#' that curve, so the centerline — not a mesh — is the geometry that defines
#' them.
#'
#' @param atlas a ggseg_atlas object
#' @return A `ggseg_centerlines` data.frame with one row per tract, a `points`
#'   list-column of n x 3 coordinate matrices and a matching `tangents`
#'   list-column
#' @export
#' @examples
#' centerlines <- atlas_centerlines(tracula())
#' nrow(centerlines)
#' dim(centerlines$points[[1]])
#' @family atlas accessors
atlas_centerlines <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas}.")
  }

  if (is.null(atlas_slot(atlas, "data")$centerlines)) {
    cli::cli_abort(c(
      "Atlas does not contain tract centerlines.",
      "i" = "Only tract atlases carry centerlines; this one is \\
             {.val {atlas_type(atlas)}}."
    ))
  }

  result <- df_left_join(
    atlas_slot(atlas, "data")$centerlines,
    atlas_slot(atlas, "core"),
    by = "label"
  )

  if (!is.null(atlas_slot(atlas, "palette"))) {
    result$colour <- unname(atlas_slot(atlas, "palette")[result$label])
  }

  class(result) <- c("ggseg_centerlines", class(result))
  result
}


#' Get atlas meshes for 3D rendering
#'
#' Returns meshes data joined with core region info and palette colours.
#' Used for subcortical and tract atlases.
#'
#' @param atlas a ggseg_atlas object
#' @return data.frame with meshes ready for 3D rendering
#' @export
#' @examples
#' meshes <- atlas_meshes(aseg())
#' head(meshes)
#' @family atlas accessors
atlas_meshes <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas}.")
  }

  if (is.null(atlas_slot(atlas, "data")$meshes)) {
    cli::cli_abort("Atlas does not contain meshes for 3D rendering.")
  }

  result <- df_left_join(
    atlas_slot(atlas, "data")$meshes,
    atlas_slot(atlas, "core"),
    by = "label"
  )

  if (!is.null(atlas_slot(atlas, "palette"))) {
    result$colour <- unname(atlas_slot(atlas, "palette")[result$label])
  }

  class(result) <- c("ggseg_meshes", class(result))
  result
}


#' @export
print.ggseg_sf <- function(x, ...) {
  dims <- paste(nrow(x), "\u00d7", ncol(x)) # nolint [object_usage_linter]
  views <- if ("view" %in% names(x)) {
    toString(unique(x$view))
  }
  cli::cli_rule("{.cls ggseg_sf} data: {dims}")
  if (!is.null(views)) {
    cli::cli_text("Views: {views}")
  }
  NextMethod()
  invisible(x)
}

#' @export
print.ggseg_vertices <- function(x, n = 10, ...) {
  dims <- paste(nrow(x), "\u00d7", ncol(x)) # nolint [object_usage_linter]
  vert_lengths <- if ("vertices" %in% names(x)) {
    vapply(atlas_slot(x, "vertices"), length, integer(1))
  }
  cli::cli_rule("{.cls ggseg_vertices} data: {dims}")
  if (!is.null(vert_lengths) && length(vert_lengths) > 0) {
    cli::cli_text(
      "Vertices per region: {format(min(vert_lengths), big.mark = ',')}
\u2013{format(max(vert_lengths), big.mark = ',')}"
    )
  }
  print_data_head(x, n)
  invisible(x)
}

#' @export
print.ggseg_centerlines <- function(x, n = 10, ...) {
  dims <- paste(nrow(x), "\u00d7", ncol(x)) # nolint [object_usage_linter]
  n_points <- if ("points" %in% names(x)) {
    vapply(x$points, NROW, integer(1))
  }
  cli::cli_rule("{.cls ggseg_centerlines} data: {dims}")
  if (!is.null(n_points) && length(n_points) > 0) {
    cli::cli_text(
      "Points per tract: {format(min(n_points), big.mark = ',')}
\u2013{format(max(n_points), big.mark = ',')}"
    )
  }
  print_data_head(x, n)
  invisible(x)
}

#' @export
print.ggseg_meshes <- function(x, n = 10, ...) {
  dims <- paste(nrow(x), "\u00d7", ncol(x)) # nolint [object_usage_linter]
  cli::cli_rule("{.cls ggseg_meshes} data: {dims}")
  if ("mesh" %in% names(x)) {
    print_mesh_summary(x, n)
  }
  invisible(x)
}

#' How an atlas was built
#'
#' Returns the build record an atlas carries, or `NULL` for an atlas built
#' before provenance existed or by a pipeline that did not record one.
#'
#' Provenance answers a question the rest of the class cannot: not what the
#' atlas contains, but how it came to contain it. Two atlases produced by the
#' same pipeline can differ in view count, polygon simplification or
#' palette source because they were built with different arguments, and
#' without a record the only way to find out is to locate the build script
#' that produced them -- which lives in a different repository and may have
#' changed since.
#'
#' @inheritParams atlas_palette
#'
#' @return A named list, or `NULL`. When present it carries at least
#'   `pipeline` (what built the atlas, including its version) and `created`
#'   (when). Any further fields are the producing pipeline's own, commonly the
#'   source parcellation and the arguments the build was given.
#'
#' @seealso [set_atlas_provenance()] to attach one.
#' @examples
#' atlas_provenance(dk())
#' @export
#' @family atlas accessors
atlas_provenance <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas}.")
  }
  atlas_slot(atlas, "provenance")
}


#' @keywords internal
#' @noRd
geom_from_data <- function(data) {
  if (!is.null(data$geom)) {
    return(data$geom)
  }
  atlas_slot(data, "sf")
}

#' The sf-class geometry of an atlas data object, or NULL if it is polygon-only
#' @keywords internal
#' @noRd
data_sf <- function(data) {
  geom <- geom_from_data(data)
  if (inherits(geom, "sf")) geom else NULL
}

#' The brain_polygons geometry of an atlas data object, or NULL if it is sf
#' @keywords internal
#' @noRd
data_poly <- function(data) {
  geom <- geom_from_data(data)
  if (inherits(geom, "brain_polygons")) geom else NULL
}
