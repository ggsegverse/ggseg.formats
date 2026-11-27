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


# Two labels differing only in case, plus a context outline absent from core,
# each drawn in two views. Case folding is locale-dependent, so a verb that
# cannot be told to match exactly cannot select one of these labels at all.
make_case_atlas <- function(polygons = TRUE) {
  spec <- list(
    ring_square("lh_Area_1", "axial_1", 0, 0),
    ring_square("lh_area_1", "axial_1", 2, 0),
    ring_square("lh_other", "axial_1", 4, 0),
    ring_square("Cortex", "axial_1", 6, 0),
    ring_square("lh_Area_1", "axial_2", 10, 0),
    ring_square("lh_area_1", "axial_2", 12, 0),
    ring_square("lh_other", "axial_2", 14, 0),
    ring_square("Cortex", "axial_2", 16, 0)
  )
  core <- data.frame(
    hemi = c("left", "left", "left"),
    region = c("Area_1", "area_1", "Other_other"),
    label = c("lh_Area_1", "lh_area_1", "lh_other"),
    display = c("Area 1", "area 1", "Other other")
  )
  ggseg_atlas(
    atlas = "test",
    type = "cortical",
    core = core,
    palette = setNames(c("#FF0000", "#00FF00", "#0000FF"), core$label),
    data = ggseg_data_cortical(geom = rings_as_geom(spec, polygons))
  )
}

case_geom_labels <- function(x) {
  geom <- atlas_geom(x)
  if (inherits(geom, "brain_polygons")) {
    polygons_unnest(geom)$label
  } else {
    geom$label
  }
}


# A two-region core plus matching `brain_polygons` geometry, for any atlas
# type. `rings_as_polygons()` needs no sf, so the conversion paths these
# fixtures feed are exercised on an install without sf too.
type_fixture_core <- function() {
  data.frame(
    hemi = c("left", "right"),
    region = c("cst", "cst"),
    label = c("cst_left", "cst_right"),
    display = c("cst_left", "cst_right"),
    stringsAsFactors = FALSE
  )
}

type_fixture_geom <- function() {
  rings_as_polygons(list(
    ring_square("cst_left", "lateral", x_off = 0, y_off = 0),
    ring_square("cst_right", "lateral", x_off = 2, y_off = 0)
  ))
}

wm_geom_atlas <- function() {
  ggseg_atlas(
    atlas = "demo_wm_2d",
    type = "white_matter",
    core = type_fixture_core(),
    data = ggseg_data_white_matter(geom = type_fixture_geom())
  )
}

# The pre-3.0.0 shape: `core` alongside separate `sf`/`vertices`/`meshes`
# slots, which `convert_legacy_structure()` upgrades.
legacy_structure_atlas <- function(type) {
  structure(
    list(
      atlas = paste0("legacy_", type),
      type = type,
      palette = NULL,
      core = type_fixture_core(),
      sf = type_fixture_geom(),
      vertices = NULL,
      meshes = NULL,
      provenance = NULL
    ),
    class = c("brain_atlas", "list")
  )
}
