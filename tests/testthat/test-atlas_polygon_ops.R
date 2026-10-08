polys <- atlas_polygons(as_polygon_atlas(dk()))

describe("polygons_unnest() / polygons_renest()", {
  it("flattens a brain_polygons table into canonical columns", {
    flat <- polygons_unnest(polys)
    expect_s3_class(flat, "data.frame")
    expect_true(all(
      c("label", "view", "x", "y", "group", "subgroup") %in% names(flat)
    ))
  })

  it("round-trips a brain_polygons table unchanged", {
    renested <- polygons_renest(polygons_unnest(polys))
    expect_s3_class(renested, "brain_polygons")
    expect_setequal(renested$label, polys$label)
  })

  it("returns NULL when re-nesting an empty table", {
    empty <- polygons_unnest(polys)[0, , drop = FALSE]
    expect_null(polygons_renest(empty))
  })
})

describe("polygons_keep_labels()", {
  it("keeps only the requested labels", {
    keep <- polys$label[1:2]
    out <- polygons_keep_labels(polys, keep)
    expect_setequal(out$label, keep)
  })
})

describe("polygons_drop_pattern()", {
  it("drops labels matching the pattern", {
    target <- polys$label[1]
    out <- polygons_drop_pattern(polys, paste0("^", target, "$"))
    expect_false(target %in% out$label)
  })
})

describe("geom_drop_pattern()", {
  it("drops a region from a brain_polygons geom", {
    out <- atlas_region_remove(
      as_polygon_atlas(dk()),
      "bankssts",
      match_on = "label"
    )
    expect_false(any(grepl("bankssts", atlas_labels(out), ignore.case = TRUE)))
    expect_true(is_atlas_polygon(out))
  })
})

describe("polygons_remove_region()", {
  it("scopes removal to the requested views", {
    target <- polygons_unnest(polys)$label[1]
    flat <- polygons_unnest(polys)
    view <- flat$view[flat$label == target][1]
    out <- polygons_remove_region(polys, target, views = view)
    kept <- polygons_unnest(out)
    expect_false(any(kept$label == target & kept$view == view))
  })

  it("removes scoped geometry via atlas_view_remove_region()", {
    atlas <- as_polygon_atlas(dk())
    view <- unique(polygons_unnest(atlas_polygons(atlas))$view)[1]
    out <- atlas_view_remove_region(atlas, "bankssts", views = view)
    expect_true(is_atlas_polygon(out))
  })
})

describe("polygons_remove_small()", {
  it("scopes small-geometry removal to the requested views", {
    flat <- polygons_unnest(polys)
    view <- unique(flat$view)[1]
    res <- polygons_remove_small(
      polys,
      min_area = Inf,
      core_labels = unique(flat$label),
      views = view
    )
    kept <- polygons_unnest(res$polygons)
    expect_false(any(kept$view == view))
    expect_gt(res$n_removed, 0L)
  })

  it("removes scoped small geometry via atlas_view_remove_small()", {
    atlas <- as_polygon_atlas(dk())
    view <- unique(polygons_unnest(atlas_polygons(atlas))$view)[1]
    expect_message(
      out <- atlas_view_remove_small(atlas, min_area = Inf, views = view),
      "Removed"
    )
    expect_true(is_atlas_polygon(out))
  })
})

describe("reposition_polygons()", {
  it("returns an empty polygon set unchanged", {
    empty <- polygons_keep_labels(polys, character(0))
    expect_null(empty)
    flat <- polygons_unnest(polys)[0, , drop = FALSE]
    empty_poly <- structure(
      df_nest(
        as_tbl(flat[, c(
          "label",
          "view",
          "x",
          "y",
          "group",
          "subgroup"
        )]),
        "label",
        "geometry"
      ),
      class = unique(c("brain_polygons", class(as_tbl(flat))))
    )
    expect_identical(reposition_polygons(empty_poly), empty_poly)
  })
})

describe("reorder_polygons()", {
  it("reorders views on a non-cortical polygon atlas", {
    poly_aseg <- atlas_polygons(as_polygon_atlas(aseg()))
    views <- unique(polygons_unnest(poly_aseg)$view)
    out <- reorder_polygons(poly_aseg, rev(views), type = NULL)
    expect_s3_class(out, "brain_polygons")
    expect_setequal(
      unique(polygons_unnest(out)$view),
      views
    )
  })

  it("orders views left to right to match the requested order", {
    poly_aseg <- atlas_polygons(as_polygon_atlas(aseg()))
    views <- unique(polygons_unnest(poly_aseg)$view)
    wanted <- rev(views)

    out <- polygons_unnest(reorder_polygons(poly_aseg, wanted, type = NULL))
    centres <- vapply(
      wanted,
      function(v) mean(range(out$x[out$view == v])),
      numeric(1)
    )

    expect_false(is.unsorted(centres))
  })
})

describe("polygon_ring_area()", {
  it("computes the unit-square area as 1", {
    expect_identical(polygon_ring_area(c(0, 1, 1, 0), c(0, 0, 1, 1)), 1)
  })

  it("is independent of vertex orientation", {
    ccw <- polygon_ring_area(c(0, 1, 1, 0), c(0, 0, 1, 1))
    cw <- polygon_ring_area(c(0, 0, 1, 1), c(0, 1, 1, 0))
    expect_identical(ccw, cw)
  })

  it("returns 0 for a degenerate ring", {
    expect_identical(polygon_ring_area(c(0, 1), c(0, 1)), 0)
  })
})


describe("order_cells_spatially()", {
  it("orders panels left to right, not by cell id", {
    # Cell 1 sits to the right of cell 2, so the drawing order must be 2 then 1.
    cell <- c(1L, 1L, 2L, 2L)
    x <- c(100, 110, 0, 10)
    expect_identical(order_cells_spatially(cell, x), c(2L, 1L))
  })

  it("keeps already left-to-right cells in their existing order", {
    cell <- c(1L, 1L, 2L, 2L)
    x <- c(0, 10, 100, 110)
    expect_identical(order_cells_spatially(cell, x), c(1L, 2L))
  })

  it("breaks ties on cell id so the order is deterministic", {
    cell <- c(2L, 1L)
    x <- c(5, 5)
    expect_identical(order_cells_spatially(cell, x), c(1L, 2L))
  })

  it("ignores NA coordinates when locating a cell", {
    cell <- c(1L, 1L, 2L)
    x <- c(NA, 100, 0)
    expect_identical(order_cells_spatially(cell, x), c(2L, 1L))
  })
})


describe("polygons_renest()", {
  it("keeps non-canonical columns and puts the canonical ones first", {
    sf0 <- dk_sf_geom()
    sf0$myannot <- paste0("ann_", seq_len(nrow(sf0)))
    polys <- sf_to_polygons(sf0)

    kept <- polygons_filter_view(polys, "lateral", keep = TRUE)

    expect_named(
      kept$geometry[[1]],
      c("view", "x", "y", "group", "subgroup", "myannot")
    )
  })
})
