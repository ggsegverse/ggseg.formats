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

  it("removes scoped geometry via atlas_prune_region()", {
    atlas <- as_polygon_atlas(dk())
    view <- unique(polygons_unnest(atlas_polygons(atlas))$view)[1]
    out <- atlas_prune_region(atlas, "bankssts", views = view)
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

  it("removes scoped small geometry via atlas_prune_small()", {
    atlas <- as_polygon_atlas(dk())
    view <- unique(polygons_unnest(atlas_polygons(atlas))$view)[1]
    expect_message(
      out <- atlas_prune_small(atlas, min_area = Inf, views = view),
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
    flat <- polygons_unnest(polys)
    flat$myannot <- paste0("ann_", seq_len(nrow(flat)))
    annotated <- polygons_renest(flat)

    kept <- polygons_filter_view(annotated, "lateral", keep = TRUE)

    expect_named(
      kept$geometry[[1]],
      c("view", "x", "y", "group", "subgroup", "myannot")
    )
  })
})


describe("polygon_geometry_areas()", {
  # A square with a square hole, a second disjoint piece, and a second label
  # in a second view: enough shape to tell a scaled, hole-blind, mis-keyed or
  # first-piece-only implementation from a correct one.
  square <- function(x0, y0, side) {
    data.frame(
      x = c(x0, x0 + side, x0 + side, x0),
      y = c(y0, y0, y0 + side, y0 + side)
    )
  }
  ring <- function(x0, y0, side, label, view, group, subgroup) {
    cbind(
      square(x0, y0, side),
      label = label,
      view = view,
      group = group,
      subgroup = subgroup
    )
  }

  flat <- rbind(
    ring(0, 0, 4, "lh_a", "view_a", 1L, 1L),
    ring(1, 1, 2, "lh_a", "view_a", 1L, 2L),
    ring(10, 0, 3, "lh_a", "view_a", 2L, 1L),
    ring(0, 0, 1, "lh_b", "view_b", 1L, 1L)
  )

  it("sums exterior minus holes over disjoint pieces", {
    areas <- polygon_geometry_areas(flat)

    # 4x4 square minus its 2x2 hole, plus a disjoint 3x3 square.
    expect_identical(areas$area[areas$label == "lh_a"], (16 - 4) + 9)
    expect_identical(areas$area[areas$label == "lh_b"], 1)
  })

  it("keys each area to its own label and view", {
    areas <- polygon_geometry_areas(flat)

    expect_identical(areas$label, c("lh_a", "lh_b"))
    expect_identical(areas$view, c("view_a", "view_b"))
  })

  it("keeps an NA label distinct from one spelled \"NA\"", {
    na_flat <- rbind(
      ring(0, 0, 2, NA_character_, "view_a", 1L, 1L),
      ring(0, 0, 1, "NA", "view_a", 2L, 1L)
    )

    areas <- polygon_geometry_areas(na_flat)

    expect_identical(areas$area[is.na(areas$label)], 4)
    expect_identical(areas$area[!is.na(areas$label)], 1)
  })
})


# The NA label and one spelled "NA" ----
#
# All three area-keyed helpers key label x view on match() indices rather than
# pasted text, because paste() renders NA as the string "NA" and so merges an
# NA label with one literally spelled "NA".
describe("area-keyed helpers with an NA label", {
  square <- function(x0, side, label, group) {
    data.frame(
      label = label,
      view = "view_a",
      x = c(x0, x0 + side, x0 + side, x0),
      y = c(0, 0, side, side),
      group = group,
      subgroup = 1L
    )
  }
  # Nested by hand: `polygons_renest()` keys with `==`, which cannot select an
  # NA label, so it is the one input the normal constructor cannot build.
  nest_by_label <- function(flat) {
    labels <- unique(flat$label)
    out <- as_tbl(data.frame(label = labels))
    out$geometry <- lapply(labels, function(l) {
      rows <- if (is.na(l)) {
        is.na(flat$label)
      } else {
        !is.na(flat$label) &
          flat$label == l
      }
      as_tbl(flat[rows, setdiff(names(flat), "label"), drop = FALSE])
    })
    structure(out, class = unique(c("brain_polygons", class(out))))
  }

  it("polygons_remove_small() keeps the NA label's own geometry", {
    polys <- nest_by_label(rbind(
      square(0, 2, NA_character_, 1L),
      square(10, 1, "NA", 1L)
    ))

    res <- polygons_remove_small(
      polys,
      min_area = 2,
      core_labels = c(NA_character_, "NA")
    )

    # The 1x1 "NA" geometry goes; the 2x2 NA-labelled one is not small.
    expect_identical(res$n_removed, 1L)
    expect_identical(res$polygons$label, NA_character_)
  })

  it("polygons_remove_small_pieces() scores the NA label on its own", {
    polys <- nest_by_label(rbind(
      square(0, 1, NA_character_, 1L),
      square(10, 10, "NA", 1L)
    ))

    res <- polygons_remove_small_pieces(polys, min_area = 10)

    # The NA label's only piece is its largest, so it survives being small.
    expect_identical(res$n_removed, 0L)
    expect_setequal(res$polygons$label, c(NA_character_, "NA"))
  })
})


describe("polygons_remove_small_pieces() row alignment", {
  # `areas` is re-indexed by `rows_by_key[pieces_key]` so element i belongs to
  # pieces[i, ]. Everything downstream -- the `ave()` grouping, `pieces$view`,
  # `pieces$label` -- indexes against that. Dropping the re-index leaves the
  # areas in split()'s sorted key order, which is NOT pieces order once there
  # are enough pieces, and the wrong ones get pruned.
  many_piece_flat <- function() {
    # Ten pieces whose keys sort out of row order: group 10 sorts before
    # group 2 as a string, so the mis-indexed form picks different pieces.
    sizes <- c(10, 1, 9, 1, 8, 1, 7, 1, 6, 1)
    do.call(
      rbind,
      lapply(seq_along(sizes), function(g) {
        side <- sizes[g]
        data.frame(
          label = "lh_a",
          view = "lateral",
          x = c(0, side, side, 0) + g * 100,
          y = c(0, 0, side, side),
          group = g,
          subgroup = 1L,
          stringsAsFactors = FALSE
        )
      })
    )
  }

  it("scopes piece pruning to the requested views", {
    # The old code read the view back out of the key with strsplit(); the
    # rewrite takes it from `pieces$view`, and nothing exercised that.
    flat <- many_piece_flat()
    other <- flat
    other$view <- "medial"
    polygons <- polygons_renest(rbind(flat, other))

    scoped <- polygons_remove_small_pieces(
      polygons,
      min_area = 5,
      views = "lateral"
    )
    kept <- polygons_unnest(scoped$polygons)

    expect_identical(scoped$n_removed, 5L)
    expect_setequal(
      unique(kept$group[kept$view == "lateral"]),
      c(1L, 3L, 5L, 7L, 9L)
    )
    expect_setequal(unique(kept$group[kept$view == "medial"]), 1:10)
  })

  it("prunes the pieces that are actually small", {
    flat <- many_piece_flat()
    polygons <- polygons_renest(flat)

    result <- polygons_remove_small_pieces(polygons, min_area = 5)
    kept <- polygons_unnest(result$polygons)

    # The five 1x1 pieces go; the five larger ones stay, largest kept always.
    expect_identical(result$n_removed, 5L)
    expect_setequal(unique(kept$group), c(1L, 3L, 5L, 7L, 9L))
  })
})
