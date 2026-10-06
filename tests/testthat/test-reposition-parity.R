describe("gather/reorder layout is representation-independent", {
  # Same geometry, two views, two hemispheres, built so each view sits at a
  # distinct x so group centroids are unambiguous.
  mk <- function(x) {
    sf::st_polygon(list(matrix(
      c(x, 0, x + 1, 0, x + 1, 1, x, 1, x, 0),
      ncol = 2,
      byrow = TRUE
    )))
  }
  sf_geom <- sf::st_sf(
    label = c("lh_a", "rh_a", "lh_a", "rh_a"),
    view = c("lateral", "lateral", "medial", "medial"),
    geometry = sf::st_sfc(mk(0), mk(2), mk(10), mk(12))
  )
  core <- data.frame(
    hemi = c("left", "right"),
    region = c("a", "a"),
    label = c("lh_a", "rh_a"),
    names = c("a", "a")
  )
  mk_atlas <- function(geom) {
    ggseg_atlas(
      atlas = "demo",
      type = "cortical",
      palette = c(lh_a = "#f00", rh_a = "#00f"),
      core = core,
      data = ggseg_data_cortical(geom = geom, vertices = NULL)
    )
  }

  sf_atlas <- mk_atlas(sf_geom)
  poly_atlas <- mk_atlas(sf_to_polygons(sf_geom))

  # per (hemi, view) x-range of an atlas's geometry, as a stable-keyed vector
  group_xranges <- function(atlas) {
    flat <- polygons_unnest(atlas_polygons(atlas))
    hemi <- ifelse(grepl("^lh", flat$label), "left", "right")
    key <- paste(hemi, flat$view)
    keys <- sort(unique(key))
    do.call(
      rbind,
      lapply(keys, function(k) {
        idx <- key == k
        data.frame(group = k, xmin = min(flat$x[idx]), xmax = max(flat$x[idx]))
      })
    )
  }

  it("gather packs sf and polygon geom into the same layout", {
    expect_equal(
      group_xranges(atlas_view_gather(sf_atlas)),
      group_xranges(atlas_view_gather(poly_atlas)),
      tolerance = 1e-9
    )
  })

  it("reorder packs sf and polygon geom into the same layout", {
    order <- c("medial", "lateral")
    expect_equal(
      group_xranges(atlas_view_reorder(sf_atlas, order)),
      group_xranges(atlas_view_reorder(poly_atlas, order)),
      tolerance = 1e-9
    )
  })

  # Row order matters as much as coordinates: geom_brain() lays panels out in
  # the order it meets the views, so geometry that moves without its rows
  # moving leaves the plot unchanged.
  view_row_order <- function(atlas) {
    unique(polygons_unnest(atlas_polygons(atlas))$view)
  }

  it("reorder puts the rows in the requested order, both reps agree", {
    order <- c("medial", "lateral")
    expect_identical(view_row_order(atlas_view_reorder(sf_atlas, order)), order)
    expect_identical(
      view_row_order(atlas_view_reorder(poly_atlas, order)),
      order
    )
  })

  it("gather puts the rows in layout order, both reps agree", {
    expect_identical(
      view_row_order(atlas_view_gather(sf_atlas)),
      view_row_order(atlas_view_gather(poly_atlas))
    )
  })

  it("gather orders groups left-to-right by centroid, both reps agree", {
    layout_order <- function(atlas) {
      xr <- group_xranges(atlas_view_gather(atlas))
      xr$group[order(xr$xmin)]
    }
    # lateral sits left of medial in the source, so both halves of lateral
    # precede both halves of medial after gathering.
    expect_identical(
      layout_order(sf_atlas),
      c("left lateral", "right lateral", "left medial", "right medial")
    )
    expect_identical(layout_order(sf_atlas), layout_order(poly_atlas))
  })
})
