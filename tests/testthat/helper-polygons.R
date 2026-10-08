make_polygon <- function(coords = c(0, 0, 1, 0, 1, 1, 0, 0)) {
  testthat::skip_if_not_installed("sf")
  sf::st_polygon(list(matrix(coords, ncol = 2, byrow = TRUE)))
}

make_polygon2 <- function() {
  testthat::skip_if_not_installed("sf")
  coords <- c(2, 0, 3, 0, 3, 1, 2, 0)
  sf::st_polygon(list(matrix(coords, ncol = 2, byrow = TRUE)))
}

# The bundled atlases (dk, aseg, tracula) now ship in the sf-optional
# brain_polygons format. Tests that need to exercise the sf path rebuild sf
# geometry on the fly from the polygon atlas.
dk_sf_atlas <- function() {
  testthat::skip_if_not_installed("sf")
  as_sf_atlas(dk())
}

dk_sf_geom <- function() atlas_geom(dk_sf_atlas())


# Representation-agnostic fixture geometry --------------------------------
#
# A spec is a list of ring entries. Materialising it as sf needs sf;
# materialising it as `brain_polygons` does not. Fixtures that take
# `polygons = TRUE` therefore let the tests of the sf-optional path run on an
# install without sf, instead of skipping the very path they exist to cover.
ring <- function(label, view, coords) {
  list(label = label, view = view, coords = coords)
}

ring_square <- function(label, view, x_off, y_off, size = 1) {
  ring(
    label,
    view,
    c(
      x_off,
      y_off,
      x_off + size,
      y_off,
      x_off + size,
      y_off + size,
      x_off,
      y_off
    )
  )
}

rings_as_sf <- function(spec) {
  testthat::skip_if_not_installed("sf")
  sf::st_sf(
    label = vapply(spec, `[[`, character(1), "label"),
    view = vapply(spec, `[[`, character(1), "view"),
    geometry = sf::st_sfc(lapply(spec, function(r) {
      sf::st_polygon(list(matrix(r$coords, ncol = 2, byrow = TRUE)))
    }))
  )
}

rings_as_polygons <- function(spec) {
  flat <- do.call(
    rbind,
    lapply(spec, function(r) {
      m <- matrix(r$coords, ncol = 2, byrow = TRUE)
      data.frame(
        label = r$label,
        view = r$view,
        x = m[, 1],
        y = m[, 2],
        group = 1,
        subgroup = 1
      )
    })
  )
  polygons_renest(as_tbl(flat))
}

rings_as_geom <- function(spec, polygons = FALSE) {
  if (polygons) rings_as_polygons(spec) else rings_as_sf(spec)
}
