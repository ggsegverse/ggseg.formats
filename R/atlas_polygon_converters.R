# Top-level atlas-format converters ----

#' Convert a ggseg atlas to the sf-optional polygon representation
#'
#' Sets the single `geom` slot to the `brain_polygons` representation,
#' converting from sf if needed. The result renders identically via the
#' `geom_polygon`-based path in ggseg, but no longer depends on the sf class
#' machinery in `$data` — useful for wasm builds and air-gapped installs.
#'
#' A single representation is kept (no redundant sf alongside polygons). To
#' rehydrate sf for geometric operations later, use [as_sf_atlas()]. Extra
#' geometry columns are carried over; only columns named `x`, `y`, `group` or
#' `subgroup` cannot be, since the nested coordinate table reserves those
#' names, and they are dropped with a warning.
#'
#' This doubles as the backward-compatible path for sf-optional installs: a
#' lite-only ggseg that meets a still-sf-backed atlas converts it on the fly.
#' The conversion reads the geometry through sfheaders, so sf itself is never
#' needed.
#'
#' @param atlas A `ggseg_atlas` (or legacy `brain_atlas`) object.
#'
#' @return A `ggseg_atlas` whose `$data$geom` is a `brain_polygons` object.
#' @export
#' @examples
#' poly <- as_polygon_atlas(dk())
#' is_atlas_polygon(poly) # TRUE
as_polygon_atlas <- function(atlas) {
  convert_atlas_geom(atlas, to_sf = FALSE)
}


#' Rehydrate a ggseg atlas into sf-backed form
#'
#' Inverse of [as_polygon_atlas()]. Sets the single `geom` slot to an sf-class
#' geometry table, converting from polygons via [sfheaders::sf_multipolygon()]
#' if needed — sfheaders is pure Rcpp with no GDAL/GEOS/PROJ dependencies, so
#' the conversion itself does not require a full sf installation. Use this when
#' you want to run sf operations (buffers, intersections, CRS transforms) on
#' atlas geometry; those sf operations themselves still require sf.
#'
#' A single representation is kept (no redundant polygons alongside sf). Extra
#' geometry columns are carried over; because an sf row covers a whole
#' label×view feature, a column that varies within one feature keeps only its
#' first value there.
#'
#' @param atlas A `ggseg_atlas` (or legacy `brain_atlas`) object.
#'
#' @return A `ggseg_atlas` whose `$data$geom` is an sf object.
#' @export
#' @examplesIf requireNamespace("sf", quietly = TRUE)
#' atlas <- as_sf_atlas(as_polygon_atlas(dk()))
#' sf::st_buffer(atlas_geom(atlas)$geometry[[1]], dist = 2)
as_sf_atlas <- function(atlas) {
  convert_atlas_geom(atlas, to_sf = TRUE)
}


#' Swap an atlas's 2D geometry to one representation or the other
#' @noRd
#' @keywords internal
convert_atlas_geom <- function(atlas, to_sf) {
  assert_ggseg_atlas(atlas)

  geom <- geom_from_data(atlas_slot(atlas, "data"))
  if (is.null(geom)) {
    cli::cli_abort(c(
      "Atlas has no 2D geometry to convert.",
      "i" = "Need {.field geom} in the atlas payload; see {.fn atlas_data}."
    ))
  }
  is_poly <- inherits(geom, "brain_polygons")
  if (to_sf && is_poly) {
    geom <- polygons_to_sf(geom)
  } else if (!to_sf && !is_poly) {
    geom <- sf_to_polygons(geom)
  }
  set_atlas_geom_slot(atlas, geom)
}


#' Put `geom` in the single geometry slot and drop the legacy ones
#' @noRd
#' @keywords internal
set_atlas_geom_slot <- function(atlas, geom) {
  data <- atlas_slot(atlas, "data")
  data$geom <- geom
  data$sf <- NULL
  data$polygons <- NULL
  set_atlas_slot(atlas, "data", data)
}
