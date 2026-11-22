describe("plot.ggseg_atlas", {
  it("plots dk atlas", {
    local_null_pdf()
    expect_no_error(plot(dk()))
  })

  it("forwards ... to the underlying graphics primitives", {
    local_null_pdf()
    expect_no_error(plot(dk(), lwd = 0.5, border = "black"))
  })

  it("plots atlases with holes without warning", {
    local_null_pdf()
    # aseg/tracula carry multi-ring regions exercising the polypath branch
    expect_no_warning(plot(aseg()))
    expect_no_warning(plot(tracula()))
  })

  it("plots a polygon-only (sf-free) atlas without warning", {
    local_null_pdf()
    expect_no_warning(plot(suit()))
  })

  it("errors when atlas has no geometry", {
    k <- dk()
    k@data$geom <- NULL
    k@data$sf <- NULL
    expect_error(plot(k), "2D geometry")
  })

  it("returns the atlas invisibly", {
    local_null_pdf()
    result <- plot(dk())
    expect_s3_class(result, "ggseg_atlas")
  })
})

describe("order_context_behind", {
  it("moves contextual rows ahead of core rows", {
    flat <- data.frame(
      label = c("core1", "ctxA", "core2", "ctxB"),
      x = 1:4
    )
    out <- order_context_behind(flat, core_labels = c("core1", "core2"))
    is_ctx <- !out$label %in% c("core1", "core2")
    # every context row precedes every core row
    expect_lt(max(which(is_ctx)), min(which(!is_ctx)))
    expect_identical(out$label, c("ctxA", "ctxB", "core1", "core2"))
  })

  it("preserves the original within-group order (stable sort)", {
    flat <- data.frame(
      label = c("ctxB", "core2", "ctxA", "core1")
    )
    out <- order_context_behind(flat, core_labels = c("core1", "core2"))
    # context block keeps B-before-A; core block keeps 2-before-1
    expect_identical(out$label, c("ctxB", "ctxA", "core2", "core1"))
  })

  it("is order-preserving when every row is core", {
    flat <- data.frame(label = c("a", "b", "c"))
    out <- order_context_behind(flat, core_labels = c("a", "b", "c"))
    expect_identical(out$label, c("a", "b", "c"))
  })
})

describe("gap_groups", {
  it("keeps densely sampled contiguous values in a single group", {
    vals <- seq(0, 10, by = 0.5)
    expect_identical(gap_groups(vals, 0.2), rep(1L, length(vals)))
  })

  it("splits across an empty band wider than the fraction", {
    # two clusters with a gap of 6 (60% of the span of 10)
    vals <- c(seq(0, 2, by = 0.5), seq(8, 10, by = 0.5))
    expect_identical(gap_groups(vals, 0.2), rep(1:2, each = 5L))
  })

  it("preserves input order, not sorted order", {
    expect_identical(gap_groups(c(100, 1, 101, 2), 0.2), c(2L, 1L, 2L, 1L))
  })

  it("returns one group when all values are equal", {
    expect_identical(gap_groups(c(5, 5, 5), 0.2), c(1L, 1L, 1L))
  })
})

describe("piece_keys", {
  it("distinguishes a region's instances across views", {
    flat <- data.frame(
      label = c("a", "a", "a"),
      view = c("lateral", "medial", "medial"),
      group = c(1L, 1L, 2L)
    )
    expect_length(unique(piece_keys(flat)), 3L)
  })
})

describe("resolve_plot_hemi", {
  it("reads hemisphere from the atlas core", {
    core <- data.frame(label = c("a", "b"), hemi = c("left", "right"))
    expect_identical(
      resolve_plot_hemi(c("b", "a"), core),
      c("right", "left")
    )
  })

  it("falls back to the lh/rh prefix for contextual regions", {
    core <- data.frame(label = "a", hemi = "left")
    expect_identical(
      resolve_plot_hemi(c("lh_unknown", "rh_unknown"), core),
      c("left", "right")
    )
  })

  it("returns NA when neither core nor label resolves a hemisphere", {
    core <- data.frame(label = "a", hemi = "left")
    expect_identical(resolve_plot_hemi("cortex", core), NA_character_)
  })

  it("tolerates a core carrying no hemi column", {
    core <- data.frame(label = "a")
    expect_identical(
      resolve_plot_hemi(c("lh_a", "cortex"), core),
      c("left", NA_character_)
    )
  })
})

describe("contained_in", {
  it("names the extent that wholly contains the span", {
    expect_identical(contained_in(c(1, 2), c(0, 3), c(5, 8)), "left")
    expect_identical(contained_in(c(6, 7), c(0, 3), c(5, 8)), "right")
  })

  it("returns NA for a span that straddles the divide", {
    expect_identical(contained_in(c(2, 6), c(0, 3), c(5, 8)), NA_character_)
  })

  it("returns NA for a span stranded in the gap", {
    expect_identical(contained_in(c(3.5, 4), c(0, 3), c(5, 8)), NA_character_)
  })
})

describe("hemi_cells", {
  bilateral <- function(hemi, x, piece = seq_along(x)) {
    hemi_cells(hemi, x, as.character(piece))
  }

  it("splits a bilateral view into two panels", {
    cells <- bilateral(
      hemi = c("left", "left", "right", "right"),
      x = c(0, 1, 5, 6)
    )
    expect_identical(cells, c(1L, 1L, 2L, 2L))
  })

  it("numbers panels left to right on screen, not by hemisphere name", {
    cells <- bilateral(
      hemi = c("left", "left", "right", "right"),
      x = c(5, 6, 0, 1)
    )
    expect_identical(cells, c(2L, 2L, 1L, 1L))
  })

  it("assigns a midline piece to the hemisphere containing it", {
    cells <- bilateral(
      hemi = c("left", "left", "right", "right", NA),
      x = c(0, 2, 5, 7, 1),
      piece = c("l", "l", "r", "r", "mid")
    )
    expect_identical(cells, c(1L, 1L, 2L, 2L, 1L))
  })

  it("declines when only one hemisphere is present", {
    expect_null(bilateral(hemi = c("left", "left"), x = c(0, 1)))
  })

  it("declines when the hemisphere extents overlap", {
    expect_null(
      bilateral(hemi = c("left", "left", "right", "right"), x = c(0, 6, 5, 9))
    )
  })

  it("declines when a piece spans the divide", {
    expect_null(bilateral(
      hemi = c("left", "right", NA, NA),
      x = c(0, 5, 0, 5),
      piece = c("l", "r", "ctx", "ctx")
    ))
  })

  it("declines when a piece is stranded in the gap", {
    expect_null(bilateral(
      hemi = c("left", "right", NA),
      x = c(0, 5, 3),
      piece = c("l", "r", "mid")
    ))
  })

  it("declines when a single piece carries both hemispheres", {
    expect_null(bilateral(
      hemi = c("left", "right"),
      x = c(0, 5),
      piece = c("both", "both")
    ))
  })
})

describe("plot_cells", {
  it("separates the two hemispheres of each surface view", {
    flat <- polygons_unnest(atlas_polygons(dk()))
    cells <- plot_cells(flat)
    expect_length(cells, nrow(flat))
    # 4 views x 2 hemispheres
    expect_length(unique(cells), 8L)
  })

  it("keeps each slice view as a single cell for a subcortical atlas", {
    flat <- polygons_unnest(atlas_polygons(aseg()))
    cells <- plot_cells(flat)
    expect_length(unique(cells), length(unique(flat$view)))
  })

  it("splits hemispheres whose gap falls under the fallback threshold", {
    # Mirrors ggsegChen's chenTh: a 1.06-wide gap across a 9.14-wide view is
    # 11.6% of the span, just under the 12% the gap heuristic needs. Both
    # hemispheres are sampled densely, as real polygon outlines are, so the
    # inter-hemisphere gap is the widest band in the view.
    hemisphere <- function(from, to) {
      data.frame(
        x = seq(from, to, length.out = 41L),
        y = seq(0, 2.7, length.out = 41L)
      )
    }
    flat <- rbind(
      cbind(label = "lh_a", hemisphere(0, 4.04)),
      cbind(label = "rh_a", hemisphere(5.1, 9.14))
    )
    flat$view <- "medial"
    flat$group <- 1L
    core <- data.frame(
      label = c("lh_a", "rh_a"),
      hemi = c("left", "right")
    )
    expect_length(unique(plot_cells(flat)), 1L)
    expect_length(
      unique(plot_cells(flat, resolve_plot_hemi(flat$label, core))),
      2L
    )
  })

  it("falls back to gap splitting when hemisphere is unresolvable", {
    flat <- polygons_unnest(atlas_polygons(dk()))
    hemi <- rep(NA_character_, nrow(flat))
    expect_identical(plot_cells(flat, hemi), plot_cells(flat))
  })

  it("keeps a bridged view whole even with hemispheres supplied", {
    flat <- polygons_unnest(atlas_polygons(aseg()))
    hemi <- resolve_plot_hemi(flat$label, atlas_core(aseg()))
    expect_identical(plot_cells(flat, hemi), plot_cells(flat))
  })
})

describe("resolve_fill_colors", {
  it("uses palette entries where present", {
    palette <- c(a = "#FF0000", b = "#00FF00")
    cols <- resolve_fill_colors(c("a", "b"), palette)
    expect_identical(cols, c(a = "#FF0000", b = "#00FF00"))
  })

  it("falls back to grey for labels missing from the palette", {
    cols <- resolve_fill_colors(c("a", "missing"), c(a = "#FF0000"))
    expect_identical(unname(cols["missing"]), "#CCCCCC")
  })

  it("falls back to grey for NA palette entries", {
    cols <- resolve_fill_colors(
      c("a", "b"),
      c(a = "#FF0000", b = NA_character_)
    )
    expect_identical(unname(cols["b"]), "#CCCCCC")
  })

  it("deduplicates labels", {
    cols <- resolve_fill_colors(
      c("a", "a", "b"),
      c(a = "#FF0000", b = "#00FF00")
    )
    expect_named(cols, c("a", "b"))
  })

  it("generates one valid hcl colour per label when no palette", {
    cols <- resolve_fill_colors(c("a", "b", "c"), NULL)
    expect_length(cols, 3L)
    expect_named(cols, c("a", "b", "c"))
    expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", cols)))
  })

  it("is deterministic without a seed", {
    expect_identical(
      resolve_fill_colors(c("a", "b", "c"), NULL),
      resolve_fill_colors(c("a", "b", "c"), NULL)
    )
  })

  it("greys context even when the palette colours it", {
    cols <- resolve_fill_colors(
      c("a", "cortex_"),
      c(a = "#FF0000", cortex_ = "#00FF00"),
      core_labels = "a"
    )
    expect_identical(unname(cols["cortex_"]), "#CCCCCC")
    expect_identical(unname(cols[["a"]]), "#FF0000")
  })

  it("greys context when there is no palette to spread", {
    cols <- resolve_fill_colors(
      c("a", "b", "cortex_"),
      NULL,
      core_labels = c("a", "b")
    )
    expect_identical(unname(cols["cortex_"]), "#CCCCCC")
    # The two regions still get distinct generated colours.
    expect_length(unique(cols[c("a", "b")]), 2L)
  })

  it("treats every label as a region when core is unknown", {
    cols <- resolve_fill_colors(c("a", "b"), NULL)
    expect_false(any(cols == "#CCCCCC"))
  })
})
