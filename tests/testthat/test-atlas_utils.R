make_test_atlas <- function() {
  sf_geom <- sf::st_sf(
    label = c("lh_frontal", "lh_parietal", "rh_frontal", "lh_unknown"),
    view = c("lateral", "lateral", "medial", "lateral"),
    geometry = sf::st_sfc(
      # nolint next: object_usage_linter. Defined in helper-polygons.R.
      make_polygon(),
      sf::st_polygon(list(matrix(
        c(2, 2, 4, 2, 4, 4, 2, 2),
        ncol = 2,
        byrow = TRUE
      ))),
      sf::st_polygon(list(matrix(
        c(5, 5, 8, 5, 8, 8, 5, 5),
        ncol = 2,
        byrow = TRUE
      ))),
      sf::st_polygon(list(matrix(
        c(0, 0, 10, 0, 10, 10, 0, 0),
        ncol = 2,
        byrow = TRUE
      )))
    )
  )
  core <- data.frame(
    hemi = c("left", "left", "right"),
    region = c("frontal", "parietal", "frontal"),
    label = c("lh_frontal", "lh_parietal", "rh_frontal")
  )
  palette <- c(
    lh_frontal = "#FF0000",
    lh_parietal = "#00FF00",
    rh_frontal = "#0000FF"
  )
  vertices <- data.frame(
    label = c("lh_frontal", "lh_parietal", "rh_frontal")
  )
  vertices$vertices <- list(1L:3L, 4L:6L, 7L:9L)

  ggseg_atlas(
    atlas = "test",
    type = "cortical",
    core = core,
    palette = palette,
    data = ggseg_data_cortical(geom = sf_geom, vertices = vertices)
  )
}

make_multiview_atlas <- function() {
  make_view_poly <- function(x_off, y_off, size = 1) {
    sf::st_polygon(list(matrix(
      c(
        x_off,
        y_off,
        x_off + size,
        y_off,
        x_off + size,
        y_off + size,
        x_off,
        y_off
      ),
      ncol = 2,
      byrow = TRUE
    )))
  }

  core_labels <- c(
    "lh_frontal",
    "lh_parietal",
    "lh_temporal",
    "lh_occipital",
    "lh_insula",
    "rh_frontal",
    "rh_parietal",
    "rh_temporal",
    "rh_occipital",
    "rh_insula"
  )
  small_labels <- c("lh_insula", "rh_insula")
  ctx <- c("ctx_left", "ctx_left", "ctx_right")
  views <- c("axial_1", "axial_2", "sagittal")

  sf_labels <- character(0)
  sf_views <- character(0)
  geoms <- list()

  for (v_idx in seq_along(views)) {
    x_base <- (v_idx - 1) * 40
    for (i in seq_along(core_labels)) {
      sz <- if (core_labels[i] %in% small_labels) 0.5 else 2
      sf_labels <- c(sf_labels, core_labels[i])
      sf_views <- c(sf_views, views[v_idx])
      geoms <- c(geoms, list(make_view_poly(x_base + (i - 1) * 3, 0, sz)))
    }
    sf_labels <- c(sf_labels, ctx[v_idx])
    sf_views <- c(sf_views, views[v_idx])
    geoms <- c(geoms, list(make_view_poly(x_base, 5, 4)))
  }

  sf_geom <- sf::st_sf(
    label = sf_labels,
    view = sf_views,
    geometry = sf::st_sfc(geoms)
  )

  core <- data.frame(
    hemi = c(rep("left", 5), rep("right", 5)),
    region = rep(
      c("frontal", "parietal", "temporal", "occipital", "insula"),
      2
    ),
    label = core_labels
  )

  palette <- setNames(
    c(
      "#FF0000",
      "#00FF00",
      "#0000FF",
      "#FFFF00",
      "#FF00FF",
      "#00FFFF",
      "#800000",
      "#008000",
      "#000080",
      "#808000"
    ),
    core_labels
  )

  ggseg_atlas(
    atlas = "test",
    type = "cortical",
    core = core,
    palette = palette,
    data = ggseg_data_cortical(geom = sf_geom)
  )
}

make_cortical_hemi_atlas <- function() {
  make_view_poly <- function(x_off, y_off, size = 1) {
    sf::st_polygon(list(matrix(
      c(
        x_off,
        y_off,
        x_off + size,
        y_off,
        x_off + size,
        y_off + size,
        x_off,
        y_off
      ),
      ncol = 2,
      byrow = TRUE
    )))
  }

  lh_labels <- c("lh_frontal", "lh_parietal")
  rh_labels <- c("rh_frontal", "rh_parietal")
  views <- c("lateral", "medial")

  sf_labels <- character(0)
  sf_views <- character(0)
  geoms <- list()

  for (v in views) {
    for (i in seq_along(lh_labels)) {
      sf_labels <- c(sf_labels, lh_labels[i])
      sf_views <- c(sf_views, v)
      x <- (match(v, views) - 1) * 20 + (i - 1) * 3
      geoms <- c(geoms, list(make_view_poly(x, 0, 2)))
    }
    for (i in seq_along(rh_labels)) {
      sf_labels <- c(sf_labels, rh_labels[i])
      sf_views <- c(sf_views, v)
      x <- (match(v, views) - 1) * 20 + 10 + (i - 1) * 3
      geoms <- c(geoms, list(make_view_poly(x, 0, 2)))
    }
  }

  sf_geom <- sf::st_sf(
    label = sf_labels,
    view = sf_views,
    geometry = sf::st_sfc(geoms)
  )

  core <- data.frame(
    hemi = c("left", "left", "right", "right"),
    region = c("frontal", "parietal", "frontal", "parietal"),
    label = c(lh_labels, rh_labels)
  )

  palette <- c(
    lh_frontal = "#FF0000",
    lh_parietal = "#00FF00",
    rh_frontal = "#0000FF",
    rh_parietal = "#FFFF00"
  )

  ggseg_atlas(
    atlas = "test_cortical",
    type = "cortical",
    core = core,
    palette = palette,
    data = ggseg_data_cortical(geom = sf_geom)
  )
}


# atlas_regions ----

describe("atlas_regions", {
  it("extracts sorted unique regions from brain_atlas", {
    atlas <- make_test_atlas()
    result <- atlas_regions(atlas)
    expect_identical(result, c("frontal", "parietal"))
  })

  it("excludes context-only geometry (labels in sf but not in core)", {
    atlas <- make_test_atlas()
    result <- atlas_regions(atlas)
    expect_false("unknown" %in% result)
  })

  it("works with data.frame", {
    df <- data.frame(region = c("frontal", "parietal", "frontal"))
    result <- atlas_regions(df)
    expect_identical(result, c("frontal", "parietal"))
  })

  it("works with ggseg_atlas", {
    atlas <- make_test_atlas()
    result <- atlas_regions(atlas)
    expect_true("frontal" %in% result)
    expect_true("parietal" %in% result)
  })
})


# atlas_labels ----

describe("atlas_labels", {
  it("extracts sorted unique labels from brain_atlas", {
    atlas <- make_test_atlas()
    result <- atlas_labels(atlas)
    expect_identical(result, c("lh_frontal", "lh_parietal", "rh_frontal"))
  })

  it("excludes NA labels", {
    core <- data.frame(
      hemi = c("left", "left"),
      region = c("frontal", "unknown"),
      label = c("lh_frontal", NA)
    )
    vertices <- data.frame(label = c("lh_frontal", NA))
    vertices$vertices <- list(1L:3L, 4L:6L)
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )
    expect_identical(atlas_labels(atlas), "lh_frontal")
  })
})


# atlas_views ----

describe("atlas_views", {
  it("returns unique view names", {
    atlas <- make_multiview_atlas()
    result <- atlas_views(atlas)
    expect_identical(result, c("axial_1", "axial_2", "sagittal"))
  })

  it("reads views from polygons when sf is absent", {
    atlas <- make_test_atlas()
    atlas$data$sf <- NULL
    expect_identical(atlas_views(atlas), c("lateral", "medial"))
  })

  it("returns NULL when no 2D data", {
    atlas <- make_test_atlas()
    atlas$data$geom <- NULL
    expect_null(atlas_views(atlas))
  })
})


# atlas_type ----

describe("atlas_type", {
  it("returns type from brain_atlas", {
    atlas <- make_test_atlas()
    expect_identical(atlas_type(atlas), "cortical")
  })
})


# get_uniq ----

describe("get_uniq", {
  it("returns sorted unique values excluding NA", {
    df <- data.frame(region = c("c", "a", "b", NA, "a"), label = 1:5)
    expect_identical(get_uniq(df, "region"), c("a", "b", "c"))
  })

  it("errors with invalid type", {
    expect_error(get_uniq(data.frame(), "invalid"))
  })
})


# guess_type ----

describe("guess_type", {
  it("guesses cortical from medial/lateral views", {
    df <- data.frame(type = NA, view = c("medial", "lateral"))
    expect_warning(
      result <- guess_type(df),
      "attempting to guess"
    )
    expect_identical(result, "cortical")
  })

  it("guesses subcortical when no medial/lateral views", {
    df <- data.frame(type = NA, view = c("axial", "sagittal"))
    expect_warning(
      result <- guess_type(df),
      "attempting to guess"
    )
    expect_identical(result, "subcortical")
  })
})


# atlas_region_remove ----

describe("atlas_region_remove", {
  it("removes matching regions from core, palette, sf, and vertices", {
    atlas <- make_test_atlas()
    result <- atlas_region_remove(atlas, "parietal")

    expect_false("lh_parietal" %in% result$core$label)
    expect_false("lh_parietal" %in% names(result$palette))
    expect_false("lh_parietal" %in% result$data$geom$label)
    expect_false("lh_parietal" %in% result$data$vertices$label)
  })

  it("matches on label when specified", {
    atlas <- make_test_atlas()
    result <- atlas_region_remove(atlas, "^lh_f", match_on = "label")

    expect_false("lh_frontal" %in% result$core$label)
    expect_identical(nrow(result$core), 2L)
  })

  it("preserves NA regions in core", {
    atlas <- make_test_atlas()
    atlas$core$region[1] <- NA
    result <- atlas_region_remove(atlas, "nonexistent")
    expect_identical(nrow(result$core), 3L)
  })
})


# cerebellar region ops (vertices + meshes) ----

make_cerebellar_atlas <- function() {
  sf_geom <- sf::st_sf(
    label = c("lobule_I", "dentate"),
    view = c("flatmap", "nuclei"),
    geometry = sf::st_sfc(
      # nolint next: object_usage_linter. Defined in helper-polygons.R.
      make_polygon(),
      sf::st_polygon(list(matrix(
        c(2, 2, 4, 2, 4, 4, 2, 2),
        ncol = 2,
        byrow = TRUE
      )))
    )
  )
  core <- data.frame(
    hemi = c(NA, NA),
    region = c("lobule I", "dentate"),
    label = c("lobule_I", "dentate")
  )
  vertices <- data.frame(label = "lobule_I")
  vertices$vertices <- list(1L:3L)
  meshes <- data.frame(label = "dentate")
  meshes$mesh <- list(list(
    vertices = data.frame(x = 1:4, y = 1:4, z = 1:4),
    faces = data.frame(i = 1L, j = 2L, k = 3L)
  ))

  ggseg_atlas(
    atlas = "cb",
    type = "cerebellar",
    core = core,
    data = ggseg_data_cerebellar(
      geom = sf_geom,
      vertices = vertices,
      meshes = meshes
    )
  )
}

describe("cerebellar region ops preserve vertices + meshes", {
  it("atlas_region_remove keeps deep-nuclei meshes and cerebellar type", {
    cb <- make_cerebellar_atlas()
    result <- atlas_region_remove(cb, "nonexistent")

    expect_identical(atlas_type(result), "cerebellar")
    expect_s3_class(result$data, "ggseg_data_cerebellar")
    expect_true("dentate" %in% result$data$meshes$label)
    expect_true("lobule_I" %in% result$data$vertices$label)
  })

  it("atlas_region_remove drops a removed structure from both 3D payloads", {
    cb <- make_cerebellar_atlas()
    result <- atlas_region_remove(cb, "dentate", match_on = "label")

    expect_identical(atlas_type(result), "cerebellar")
    expect_false("dentate" %in% result$data$meshes$label)
    expect_true("lobule_I" %in% result$data$vertices$label)
  })

  it("atlas_region_keep keeps cerebellar type and the kept structure", {
    cb <- make_cerebellar_atlas()
    result <- atlas_region_keep(cb, "dentate", match_on = "label")

    expect_identical(atlas_type(result), "cerebellar")
    expect_true("dentate" %in% result$data$meshes$label)
    expect_false("lobule_I" %in% result$data$vertices$label)
  })
})


# atlas_region_contextual ----

describe("atlas_region_contextual", {
  it("removes from core and palette but keeps sf geometry", {
    atlas <- make_test_atlas()
    result <- atlas_region_contextual(atlas, "parietal")

    expect_false("lh_parietal" %in% result$core$label)
    expect_false("lh_parietal" %in% names(result$palette))
    expect_true("lh_parietal" %in% result$data$geom$label)
  })

  it("removes from 3D data", {
    atlas <- make_test_atlas()
    result <- atlas_region_contextual(atlas, "parietal")
    expect_false("lh_parietal" %in% result$data$vertices$label)
  })

  it("matches on label when specified", {
    atlas <- make_test_atlas()
    result <- atlas_region_contextual(atlas, "^lh_f", match_on = "label")
    expect_identical(nrow(result$core), 2L)
    expect_identical(result$core$label, c("lh_parietal", "rh_frontal"))
  })

  it("draws contextual sf rows before remaining core rows", {
    atlas <- make_test_atlas()
    result <- atlas_region_contextual(atlas, "parietal")
    sf <- result$data$geom
    is_core <- sf$label %in% result$core$label
    # the demoted region (lh_parietal) was in the middle; it must now lead
    expect_identical(sf$label[1], "lh_parietal")
    expect_lt(max(which(!is_core)), min(which(is_core)))
  })

  it("matches case-insensitively by default", {
    atlas <- make_test_atlas()
    result <- atlas_region_contextual(atlas, "FRONTAL")
    expect_false(any(grepl("frontal", result$core$region, fixed = TRUE)))
  })

  it("respects ignore.case = FALSE", {
    atlas <- make_test_atlas()
    result <- atlas_region_contextual(atlas, "FRONTAL", ignore.case = FALSE)
    # no region matches the upper-case pattern, so nothing is demoted
    expect_identical(nrow(result$core), nrow(atlas$core))
  })

  it("retains every geometry row after demoting a region", {
    atlas <- make_test_atlas()
    result <- atlas_region_contextual(atlas, "parietal")
    # demoting only moves rows behind core; no geometry is dropped or added
    expect_setequal(result$data$geom$label, atlas$data$geom$label)
    expect_identical(nrow(result$data$geom), nrow(atlas$data$geom))
    # the demoted region keeps its geometry
    expect_true("lh_parietal" %in% result$data$geom$label)
  })

  it("operates on a polygon-only atlas without sf", {
    poly <- as_polygon_atlas(make_test_atlas())
    expect_null(poly$data$sf)

    result <- atlas_region_contextual(poly, "parietal")
    expect_null(result$data$sf)
    expect_s3_class(result$data$geom, "brain_polygons")
    # demoted geometry retained, dropped from core, drawn first (behind core)
    expect_true("lh_parietal" %in% result$data$geom$label)
    expect_false("lh_parietal" %in% result$core$label)
    is_core <- result$data$geom$label %in% result$core$label
    expect_lt(max(which(!is_core)), min(which(is_core)))
  })
})


# atlas_region_op ----

describe("atlas_region_op", {
  make_op_atlas <- function() {
    outer <- sf::st_polygon(list(matrix(
      c(0, 0, 10, 0, 10, 10, 0, 10, 0, 0),
      ncol = 2,
      byrow = TRUE
    )))
    inner <- sf::st_polygon(list(matrix(
      c(3, 3, 7, 3, 7, 7, 3, 7, 3, 3),
      ncol = 2,
      byrow = TRUE
    )))
    sf_geom <- sf::st_sf(
      label = c("cortex", "wm"),
      view = c("v1", "v1"),
      geometry = sf::st_sfc(outer, inner)
    )
    core <- data.frame(
      hemi = c(NA, NA),
      region = c("cortex", "wm"),
      label = c("cortex", "wm")
    )
    ggseg_atlas(
      atlas = "op",
      type = "subcortical",
      palette = c(cortex = "#aaaaaa", wm = "#bbbbbb"),
      core = core,
      data = ggseg_data_subcortical(geom = sf_geom, meshes = NULL)
    )
  }

  area_of <- function(atlas, lbl) {
    g <- atlas$data$geom$geometry[atlas$data$geom$label == lbl]
    as.numeric(sum(sf::st_area(g)))
  }
  holes_of <- function(atlas, lbl) {
    g <- atlas$data$geom$geometry[[which(atlas$data$geom$label == lbl)[1]]]
    if (inherits(g, "MULTIPOLYGON")) {
      sum(vapply(g, length, integer(1))) - length(g)
    } else if (inherits(g, "POLYGON")) {
      length(g) - 1
    } else {
      NA_integer_
    }
  }

  it("difference punches y out of x as a hole", {
    r <- atlas_region_op(
      make_op_atlas(),
      "cortex",
      "wm",
      action = "difference",
      into = "ribbon"
    )
    expect_identical(holes_of(r, "ribbon"), 1)
    expect_identical(area_of(r, "ribbon"), 100 - 16)
  })

  it("intersection keeps only the overlap", {
    r <- atlas_region_op(
      make_op_atlas(),
      "cortex",
      "wm",
      action = "intersection",
      into = "ov"
    )
    expect_identical(area_of(r, "ov"), 16)
  })

  it("union merges both operands", {
    r <- atlas_region_op(
      make_op_atlas(),
      "cortex",
      "wm",
      action = "union",
      into = "both"
    )
    expect_identical(area_of(r, "both"), 100)
  })

  it("leaves the input regions in place", {
    r <- atlas_region_op(
      make_op_atlas(),
      "cortex",
      "wm",
      action = "difference",
      into = "ribbon"
    )
    expect_true(all(c("cortex", "wm") %in% r$data$geom$label))
  })

  it("result is contextual without a colour", {
    r <- atlas_region_op(
      make_op_atlas(),
      "cortex",
      "wm",
      action = "difference",
      into = "ribbon"
    )
    expect_false("ribbon" %in% r$core$label)
    expect_false("ribbon" %in% names(r$palette))
    expect_true("ribbon" %in% r$data$geom$label)
  })

  it("colour registers the result in core and palette", {
    r <- atlas_region_op(
      make_op_atlas(),
      "cortex",
      "wm",
      action = "difference",
      into = "ribbon",
      colour = "#123456"
    )
    expect_true("ribbon" %in% r$core$label)
    expect_identical(r$palette[["ribbon"]], "#123456")
  })

  it("draws a contextual result behind core regions", {
    r <- atlas_region_op(
      make_op_atlas(),
      "cortex",
      "wm",
      action = "difference",
      into = "ribbon"
    )
    sf <- r$data$geom
    is_core <- sf$label %in% r$core$label
    expect_lt(max(which(!is_core)), min(which(is_core)))
  })

  it("writes the result into the polygons slot too", {
    r <- atlas_region_op(
      make_op_atlas(),
      "cortex",
      "wm",
      action = "difference",
      into = "ribbon"
    )
    # the result region is added alongside the untouched operands
    expect_setequal(r$data$geom$label, c("cortex", "wm", "ribbon"))
  })

  it("operates on a polygon-only atlas and stays polygon-only", {
    poly <- as_polygon_atlas(make_op_atlas())
    expect_null(poly$data$sf)

    r <- atlas_region_op(
      poly,
      "cortex",
      "wm",
      action = "difference",
      into = "ribbon"
    )
    expect_null(r$data$sf)
    expect_true("ribbon" %in% r$data$geom$label)

    rehydrated <- as_sf_atlas(r)
    g <- rehydrated$data$geom$geometry[rehydrated$data$geom$label == "ribbon"]
    expect_identical(as.numeric(sum(sf::st_area(g))), 100 - 16)
  })

  it("matches sf-backed and polygon-only results", {
    sf_res <- atlas_region_op(
      make_op_atlas(),
      "cortex",
      "wm",
      action = "intersection",
      into = "ov"
    )
    poly_res <- atlas_region_op(
      as_polygon_atlas(make_op_atlas()),
      "cortex",
      "wm",
      action = "intersection",
      into = "ov"
    )
    poly_sf <- as_sf_atlas(poly_res)$data$geom
    sf_area <- as.numeric(sum(sf::st_area(
      sf_res$data$geom$geometry[sf_res$data$geom$label == "ov"]
    )))
    poly_area <- as.numeric(sum(sf::st_area(
      poly_sf$geometry[poly_sf$label == "ov"]
    )))
    expect_identical(sf_area, poly_area)
  })
})


# atlas_region_rename ----

describe("atlas_region_rename", {
  it("renames matching regions with string replacement", {
    atlas <- make_test_atlas()
    result <- atlas_region_rename(atlas, "frontal", "prefrontal")
    non_parietal <- result$core$region != "parietal"
    expect_true(all(result$core$region[non_parietal] == "prefrontal"))
  })

  it("renames matching regions with function", {
    atlas <- make_test_atlas()
    result <- atlas_region_rename(atlas, ".*", toupper)
    expect_true(all(result$core$region %in% c("FRONTAL", "PARIETAL")))
  })

  it("does not modify labels", {
    atlas <- make_test_atlas()
    result <- atlas_region_rename(atlas, "frontal", "prefrontal")
    expect_identical(result$core$label, atlas$core$label)
  })

  it("preserves NA regions", {
    atlas <- make_test_atlas()
    atlas$core$region[1] <- NA
    result <- atlas_region_rename(atlas, "parietal", "PARIETAL")
    expect_true(is.na(result$core$region[1]))
  })

  it("derives regions from labels when matching on label", {
    atlas <- make_test_atlas()
    result <- atlas_region_rename(atlas, "^lh_", "left ", match_on = "label")
    lh <- grepl("^lh_", atlas$core$label)
    expect_identical(
      result$core$region[lh],
      sub("^lh_", "left ", atlas$core$label[lh])
    )
  })

  it("leaves regions whose label does not match", {
    atlas <- make_test_atlas()
    result <- atlas_region_rename(atlas, "^lh_", "left ", match_on = "label")
    rh <- !grepl("^lh_", atlas$core$label)
    expect_identical(result$core$region[rh], atlas$core$region[rh])
  })

  it("passes label values to a replacement function when matching on label", {
    atlas <- make_test_atlas()
    result <- atlas_region_rename(atlas, ".*", toupper, match_on = "label")
    expect_identical(result$core$region, toupper(atlas$core$label))
  })

  it("never writes to label when matching on label", {
    atlas <- make_test_atlas()
    result <- atlas_region_rename(atlas, "^lh_", "", match_on = "label")
    expect_identical(result$core$label, atlas$core$label)
  })

  it("rejects an unknown match_on", {
    atlas <- make_test_atlas()
    expect_error(atlas_region_rename(atlas, "frontal", "f", match_on = "nope"))
  })
})


# atlas_region_keep ----

describe("atlas_region_keep", {
  it("keeps only matching regions in core and palette", {
    atlas <- make_test_atlas()
    result <- atlas_region_keep(atlas, "frontal")

    expect_identical(nrow(result$core), 2L)
    expect_true(all(result$core$region == "frontal"))
    expect_length(result$palette, 2)
  })

  it("preserves sf geometry for surface continuity", {
    atlas <- make_test_atlas()
    result <- atlas_region_keep(atlas, "frontal")
    expect_identical(nrow(result$data$geom), nrow(atlas$data$geom))
  })

  it("filters 3D data", {
    atlas <- make_test_atlas()
    result <- atlas_region_keep(atlas, "frontal")
    expect_identical(nrow(result$data$vertices), 2L)
  })

  it("matches on label", {
    atlas <- make_test_atlas()
    result <- atlas_region_keep(atlas, "^lh_", match_on = "label")
    expect_identical(nrow(result$core), 2L)
  })
})


# atlas_core_add ----

describe("atlas_core_add", {
  it("joins metadata columns to core", {
    atlas <- make_test_atlas()
    meta <- data.frame(
      region = c("frontal", "parietal"),
      lobe = c("frontal", "parietal")
    )
    result <- atlas_core_add(atlas, meta)
    expect_true("lobe" %in% names(result$core))
    expect_identical(result$core$lobe, c("frontal", "parietal", "frontal"))
  })

  it("joins by custom column", {
    atlas <- make_test_atlas()
    meta <- data.frame(
      label = "lh_frontal",
      network = "DMN"
    )
    result <- atlas_core_add(atlas, meta, by = "label")
    expect_true("network" %in% names(result$core))
    expect_identical(result$core$network[1], "DMN")
    expect_true(is.na(result$core$network[2]))
  })

  it("never adds rows to core", {
    atlas <- make_test_atlas()
    meta <- data.frame(
      region = c("frontal", "parietal"),
      lobe = c("frontal", "parietal")
    )
    result <- atlas_core_add(atlas, meta)
    expect_identical(nrow(result$core), nrow(atlas$core))
  })

  it("errors when data has duplicate join keys", {
    atlas <- make_test_atlas()
    meta <- data.frame(
      region = c("frontal", "frontal"),
      lobe = c("a", "b")
    )
    expect_error(atlas_core_add(atlas, meta), "unique")
  })
})


# atlas_view_remove ----

describe("atlas_view_remove", {
  it("removes matching views from sf", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_remove(atlas, "axial_1")
    expect_false("axial_1" %in% result$data$geom$view)
    expect_true("axial_2" %in% result$data$geom$view)
  })

  it("removes multiple views with vector", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_remove(atlas, c("axial_1", "axial_2"))
    expect_identical(unique(result$data$geom$view), "sagittal")
  })

  it("warns when no 2D data", {
    atlas <- make_test_atlas()
    atlas$data$geom <- NULL
    expect_warning(atlas_view_remove(atlas, "lateral"), "no 2D geometry")
  })

  it("removes views from a polygon-only atlas without sf", {
    atlas <- make_test_atlas()
    atlas$data$sf <- NULL
    result <- atlas_view_remove(atlas, "medial")
    expect_null(result$data$sf)
    expect_false("medial" %in% atlas_views(result))
    expect_true("lateral" %in% atlas_views(result))
  })

  it("warns when all views removed", {
    atlas <- make_multiview_atlas()
    expect_warning(
      expect_warning(atlas_view_remove(atlas, ".*"), "All views removed"),
      "no 2D geometry"
    )
  })
})


# atlas_view_keep ----

describe("atlas_view_keep", {
  it("keeps only matching views", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_keep(atlas, "sagittal")
    expect_identical(unique(result$data$geom$view), "sagittal")
  })

  it("keeps multiple views with vector", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_keep(atlas, c("axial_1", "sagittal"))
    expect_identical(
      sort(unique(result$data$geom$view)),
      c("axial_1", "sagittal")
    )
  })

  it("warns when no views match", {
    atlas <- make_multiview_atlas()
    expect_warning(atlas_view_keep(atlas, "nonexistent"), "No views matched")
  })
})


# atlas_view_remove_region ----

describe("atlas_view_remove_region", {
  it("removes region from sf only, keeps core and palette", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_remove_region(atlas, "lh_frontal")

    expect_false("lh_frontal" %in% result$data$geom$label)
    expect_true("lh_frontal" %in% result$core$label)
    expect_true("lh_frontal" %in% names(result$palette))
  })

  it("matches on region via core lookup", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_remove_region(atlas, "frontal", match_on = "region")

    expect_false("lh_frontal" %in% result$data$geom$label)
    expect_false("rh_frontal" %in% result$data$geom$label)
    expect_true("lh_parietal" %in% result$data$geom$label)
  })

  it("preserves NA-label rows", {
    atlas <- make_multiview_atlas()
    atlas$data$geom$label[1] <- NA
    n_na <- sum(is.na(atlas$data$geom$label))
    result <- atlas_view_remove_region(atlas, "insula")
    expect_identical(sum(is.na(result$data$geom$label)), n_na)
  })

  it("preserves context geometry labels", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_remove_region(atlas, "ctx_left")
    expect_false("ctx_left" %in% result$data$geom$label)
  })
})


# atlas_view_select ----

# Three views over two bilateral regions. `frontal` is drawn large in axial_1
# and as a sliver in axial_2; `temporal` is the other way round. The sagittal
# view holds left labels only, at the same size as the large drawings, so it
# is only competitive once single-hemisphere views are weighted up.
make_view_select_atlas <- function() {
  square <- function(x_off, size) {
    sf::st_polygon(list(matrix(
      c(
        x_off,
        0,
        x_off + size,
        0,
        x_off + size,
        size,
        x_off,
        size,
        x_off,
        0
      ),
      ncol = 2,
      byrow = TRUE
    )))
  }

  spec <- rbind(
    data.frame(label = "lh_frontal", view = "axial_1", size = 4),
    data.frame(label = "rh_frontal", view = "axial_1", size = 4),
    data.frame(label = "lh_frontal", view = "axial_2", size = 1),
    data.frame(label = "rh_frontal", view = "axial_2", size = 1),
    data.frame(label = "lh_temporal", view = "axial_1", size = 1),
    data.frame(label = "rh_temporal", view = "axial_1", size = 1),
    data.frame(label = "lh_temporal", view = "axial_2", size = 4),
    data.frame(label = "rh_temporal", view = "axial_2", size = 4),
    data.frame(label = "lh_frontal", view = "sagittal", size = 4),
    data.frame(label = "lh_temporal", view = "sagittal", size = 4),
    data.frame(label = "outline", view = "axial_1", size = 9),
    data.frame(label = "outline", view = "axial_2", size = 9),
    data.frame(label = "outline", view = "sagittal", size = 9)
  )

  x_off <- (match(spec$view, c("axial_1", "axial_2", "sagittal")) - 1) *
    40 +
    seq_len(nrow(spec)) * 0.01
  geoms <- Map(square, x_off, spec$size)

  sf_geom <- sf::st_sf(
    label = spec$label,
    view = spec$view,
    geometry = sf::st_sfc(geoms)
  )

  core <- data.frame(
    hemi = c("left", "right", "left", "right"),
    region = c("frontal", "frontal", "temporal", "temporal"),
    label = c("lh_frontal", "rh_frontal", "lh_temporal", "rh_temporal")
  )

  ggseg_atlas(
    atlas = "test",
    type = "cortical",
    core = core,
    palette = setNames(
      c("#FF0000", "#00FF00", "#0000FF", "#FFFF00"),
      core$label
    ),
    data = ggseg_data_cortical(geom = sf_geom)
  )
}

describe("atlas_view_select", {
  views_of <- function(atlas, label) {
    flat <- polygons_unnest(atlas_polygons(atlas))
    sort(unique(flat$view[flat$label == label]))
  }

  it("drops a region from views where it is only a sliver", {
    atlas <- make_view_select_atlas()
    expect_message(result <- atlas_view_select(atlas), "Regions drawn per view")

    expect_false("axial_2" %in% views_of(result, "rh_frontal"))
    expect_true("axial_1" %in% views_of(result, "rh_frontal"))
    expect_false("axial_1" %in% views_of(result, "rh_temporal"))
    expect_true("axial_2" %in% views_of(result, "rh_temporal"))
  })

  it("keeps left and right of a region in the same views", {
    atlas <- make_view_select_atlas()
    expect_message(result <- atlas_view_select(atlas))

    for (region in c("frontal", "temporal")) {
      expect_identical(
        setdiff(views_of(result, paste0("lh_", region)), "sagittal"),
        views_of(result, paste0("rh_", region))
      )
    }
  })

  it("keeps a single-hemisphere view competitive", {
    # Untouched, sagittal holds half the area of a bilateral view and would
    # lose every region at any threshold above 0.5.
    atlas <- make_view_select_atlas()
    expect_message(result <- atlas_view_select(atlas, threshold = 0.9))

    expect_true("sagittal" %in% views_of(result, "lh_frontal"))
    expect_true("sagittal" %in% views_of(result, "lh_temporal"))
  })

  it("honours explicit weights over the automatic ones", {
    atlas <- make_view_select_atlas()
    expect_message(
      result <- atlas_view_select(
        atlas,
        threshold = 0.9,
        weights = c(sagittal = 0.1)
      )
    )

    expect_false("sagittal" %in% views_of(result, "lh_frontal"))
  })

  it("never drops a region from every view", {
    atlas <- make_view_select_atlas()
    expect_message(result <- atlas_view_select(atlas, threshold = 1))

    for (label in atlas_labels(result)) {
      expect_gt(length(views_of(result, label)), 0)
    }
  })

  it("leaves context geometry alone", {
    atlas <- make_view_select_atlas()
    expect_message(result <- atlas_view_select(atlas, threshold = 1))

    expect_setequal(views_of(result, "outline"), views_of(atlas, "outline"))
  })

  it("preserves core and palette", {
    atlas <- make_view_select_atlas()
    expect_message(result <- atlas_view_select(atlas))

    expect_identical(result$core, atlas$core)
    expect_identical(atlas_palette(result), atlas_palette(atlas))
  })

  it("rejects an out-of-range threshold", {
    atlas <- make_view_select_atlas()
    expect_error(atlas_view_select(atlas, threshold = 1.5), "between 0 and 1")
    expect_error(atlas_view_select(atlas, threshold = -1), "between 0 and 1")
  })

  it("rejects weights naming an unknown view", {
    atlas <- make_view_select_atlas()
    expect_error(
      atlas_view_select(atlas, weights = c(coronal = 2)),
      "Unknown view"
    )
  })
})


# atlas_view_remove_small ----

describe("atlas_view_remove_small", {
  it("removes small polygons below threshold", {
    atlas <- make_multiview_atlas()
    n_before <- nrow(atlas$data$geom)
    expect_message(
      result <- atlas_view_remove_small(atlas, min_area = 2),
      "Removed"
    )
    n_after <- nrow(result$data$geom)
    expect_lt(n_after, n_before)
  })

  it("never removes context geometries", {
    atlas <- make_multiview_atlas()
    ctx_labels <- setdiff(atlas$data$geom$label, c(atlas$core$label, NA))
    expect_message(
      result <- atlas_view_remove_small(atlas, min_area = 2),
      "Removed"
    )
    remaining_labels <- unique(result$data$geom$label)
    expect_true(all(ctx_labels %in% remaining_labels))
  })

  it("scopes to specific views", {
    atlas <- make_multiview_atlas()
    expect_message(
      result_all <- atlas_view_remove_small(atlas, min_area = 2),
      "Removed"
    )
    expect_message(
      result_axial <- atlas_view_remove_small(
        atlas,
        min_area = 2,
        views = "axial"
      ),
      "Removed"
    )

    expect_gte(nrow(result_axial$data$geom), nrow(result_all$data$geom))
  })

  it("preserves core and palette", {
    atlas <- make_multiview_atlas()
    expect_message(
      result <- atlas_view_remove_small(atlas, min_area = 2),
      "Removed"
    )
    expect_identical(result$core, atlas$core)
    expect_identical(result$palette, atlas$palette)
  })

  it("warns when no 2D data", {
    atlas <- make_test_atlas()
    atlas$data$geom <- NULL
    expect_warning(
      atlas_view_remove_small(atlas, min_area = 1),
      "no 2D geometry"
    )
  })

  it("removes small geometries from a polygon-only atlas", {
    atlas <- make_multiview_atlas()
    poly <- as_polygon_atlas(atlas)
    expect_message(
      result <- atlas_view_remove_small(poly, min_area = 2),
      "Removed"
    )
    expect_null(result$data$sf)

    n_geoms <- function(p) {
      flat <- polygons_unnest(p)
      length(unique(paste(flat$label, flat$view)))
    }
    expect_lt(n_geoms(result$data$geom), nrow(atlas$data$geom))
  })
})


# atlas_view_gather ----

describe("atlas_view_gather", {
  it("repositions views without gaps", {
    atlas <- make_multiview_atlas()
    trimmed <- atlas_view_remove(atlas, "axial_2")
    result <- atlas_view_gather(trimmed)

    expect_s3_class(result$data$geom, "sf")
    expect_identical(
      sort(unique(result$data$geom$view)),
      sort(unique(trimmed$data$geom$view))
    )
  })

  it("warns when no 2D data", {
    atlas <- make_test_atlas()
    atlas$data$geom <- NULL
    expect_warning(atlas_view_gather(atlas), "no 2D geometry")
  })

  it("repositions a polygon-only atlas without sf", {
    atlas <- make_multiview_atlas()
    poly <- as_polygon_atlas(atlas)
    result <- atlas_view_gather(poly)

    expect_null(result$data$sf)
    expect_s3_class(result$data$geom, "brain_polygons")

    # each hemi+view group occupies a disjoint horizontal band (packed left
    # to right with gaps); the exact ordering is representation-dependent.
    flat <- polygons_unnest(result$data$geom)
    hemi <- rep("", nrow(flat))
    hemi[grepl("^lh", flat$label)] <- "left"
    hemi[grepl("^rh", flat$label)] <- "right"
    groups <- split(seq_len(nrow(flat)), paste(hemi, flat$view))
    ranges <- lapply(groups, function(idx) range(flat$x[idx]))
    ordered <- ranges[order(vapply(ranges, `[`, numeric(1), 1))]
    for (i in seq_len(length(ordered) - 1)) {
      expect_lte(ordered[[i]][2], ordered[[i + 1]][1])
    }
  })

  it("keeps cortical hemi+view groups spatially coherent", {
    atlas <- make_cortical_hemi_atlas()
    result <- atlas_view_gather(atlas)

    sf <- result$data$geom
    for (v in unique(sf$view)) {
      lh_rows <- sf[sf$view == v & grepl("^lh_", sf$label), ]
      rh_rows <- sf[sf$view == v & grepl("^rh_", sf$label), ]
      if (nrow(lh_rows) > 0 && nrow(rh_rows) > 0) {
        lh_bbox <- sf::st_bbox(lh_rows)
        rh_bbox <- sf::st_bbox(rh_rows)
        expect_true(
          lh_bbox["xmax"] < rh_bbox["xmin"] ||
            rh_bbox["xmax"] < lh_bbox["xmin"]
        )
      }
    }
  })
})


# atlas_view_reorder ----

describe("atlas_view_reorder", {
  it("reorders views as specified", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_reorder(atlas, c("sagittal", "axial_2", "axial_1"))

    views_in_order <- unique(result$data$geom$view)
    expect_identical(views_in_order, c("sagittal", "axial_2", "axial_1"))
  })

  it("appends unspecified views at end", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_reorder(atlas, "sagittal")

    views_in_order <- unique(result$data$geom$view)
    expect_identical(views_in_order[1], "sagittal")
    expect_length(views_in_order, 3)
  })

  it("appends all current views when given only nonexistent ones", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_reorder(atlas, "nonexistent")
    expect_length(unique(result$data$geom$view), 3)
  })

  it("reorders cortical views with hemi sub-groups", {
    atlas <- make_cortical_hemi_atlas()
    result <- atlas_view_reorder(atlas, c("medial", "lateral"))

    views_in_order <- unique(result$data$geom$view)
    expect_identical(views_in_order, c("medial", "lateral"))

    sf <- result$data$geom
    medial_bbox <- sf::st_bbox(sf[sf$view == "medial", ])
    lateral_bbox <- sf::st_bbox(sf[sf$view == "lateral", ])
    expect_lt(medial_bbox["xmax"], lateral_bbox["xmin"])
  })
})


# polygon-only view operations ----

describe("view operations on polygon-only atlases", {
  poly_views <- function(atlas) {
    unique(polygons_unnest(atlas$data$geom)$view)
  }

  it("atlas_context_remove drops context geometry without sf", {
    poly <- as_polygon_atlas(make_test_atlas())
    result <- atlas_context_remove(poly)
    expect_null(result$data$sf)
    expect_false("lh_unknown" %in% result$data$geom$label)
    expect_setequal(result$data$geom$label, result$core$label)
  })

  it("atlas_view_keep keeps only matching views without sf", {
    poly <- as_polygon_atlas(make_multiview_atlas())
    result <- atlas_view_keep(poly, "axial_1")
    expect_null(result$data$sf)
    expect_identical(poly_views(result), "axial_1")
  })

  it("atlas_view_remove_region drops a region's geometry without sf", {
    poly <- as_polygon_atlas(make_test_atlas())
    result <- atlas_view_remove_region(poly, "lh_frontal", match_on = "label")
    expect_null(result$data$sf)
    expect_false("lh_frontal" %in% result$data$geom$label)
    # core is untouched by a view-only removal
    expect_true("lh_frontal" %in% result$core$label)
  })

  it("atlas_view_remove_region by region matches sf-path geometry", {
    atlas <- make_multiview_atlas()
    sf_res <- atlas_view_remove_region(atlas, "frontal", match_on = "region")
    poly_res <- atlas_view_remove_region(
      as_polygon_atlas(atlas),
      "frontal",
      match_on = "region"
    )
    expect_setequal(
      unique(sf_res$data$geom$label),
      poly_res$data$geom$label
    )
  })

  it("atlas_view_reorder lays views out in the requested order", {
    poly <- as_polygon_atlas(make_cortical_hemi_atlas())
    result <- atlas_view_reorder(poly, c("medial", "lateral"))
    expect_null(result$data$sf)

    flat <- polygons_unnest(result$data$geom)
    medial_xmax <- max(flat$x[flat$view == "medial"])
    lateral_xmin <- min(flat$x[flat$view == "lateral"])
    expect_lte(medial_xmax, lateral_xmin)
  })
})


# context ordering in as.data.frame ----

describe("as.data.frame context ordering", {
  it("places context geometries before non-context", {
    atlas <- make_test_atlas()
    df <- as.data.frame(atlas)

    is_ctx <- !df$label %in% atlas$core$label | is.na(df$label)
    ctx_positions <- which(is_ctx)
    non_ctx_positions <- which(!is_ctx)

    if (length(ctx_positions) > 0 && length(non_ctx_positions) > 0) {
      expect_lt(max(ctx_positions), min(non_ctx_positions))
    }
  })

  it("works with atlas that has no context geometry", {
    atlas <- make_test_atlas()
    keep <- atlas$data$geom$label %in% atlas$core$label
    atlas$data$geom <- atlas$data$geom[keep, ]
    df <- as.data.frame(atlas)
    expect_s3_class(df, "sf")
    expect_identical(nrow(df), 3L)
  })
})


describe("subclass preservation", {
  it("manipulation functions preserve cortical_atlas subclass", {
    atlas <- make_test_atlas()
    expect_s3_class(atlas, "cortical_atlas")

    expect_s3_class(
      atlas_region_remove(atlas, "parietal"),
      "cortical_atlas"
    )
    expect_s3_class(
      atlas_region_keep(atlas, "frontal"),
      "cortical_atlas"
    )
    expect_s3_class(
      atlas_region_contextual(atlas, "parietal"),
      "cortical_atlas"
    )
    expect_s3_class(
      atlas_region_rename(atlas, "frontal", "front"),
      "cortical_atlas"
    )
    expect_s3_class(
      atlas_core_add(atlas, data.frame(region = "frontal", x = 1)),
      "cortical_atlas"
    )
  })

  it("view functions preserve cortical_atlas subclass", {
    atlas <- make_multiview_atlas()
    expect_s3_class(atlas, "cortical_atlas")

    expect_s3_class(
      atlas_view_remove(atlas, "sagittal"),
      "cortical_atlas"
    )
    expect_s3_class(
      atlas_view_keep(atlas, "axial"),
      "cortical_atlas"
    )
    expect_s3_class(
      atlas_view_remove_region(atlas, "lh_frontal"),
      "cortical_atlas"
    )
    expect_message(
      removed <- atlas_view_remove_small(atlas, min_area = 2),
      "Removed"
    )
    expect_s3_class(removed, "cortical_atlas")
    expect_s3_class(atlas_view_gather(atlas), "cortical_atlas")
    expect_s3_class(
      atlas_view_reorder(atlas, c("sagittal", "axial_1", "coronal_2")),
      "cortical_atlas"
    )
  })

  it("bundled atlases have correct subclasses", {
    expect_s3_class(
      dk(),
      c("cortical_atlas", "ggseg_atlas", "list"),
      exact = TRUE
    )
    expect_s3_class(
      aseg(),
      c("subcortical_atlas", "ggseg_atlas", "list"),
      exact = TRUE
    )
    expect_s3_class(
      tracula(),
      c("tract_atlas", "ggseg_atlas", "list"),
      exact = TRUE
    )
  })
})


describe("deprecated wrappers", {
  it("brain_regions() warns and returns regions", {
    lifecycle::expect_deprecated(
      result <- brain_regions(dk())
    )
    expect_type(result, "character")
    expect_gt(length(result), 0)
  })

  it("brain_labels() warns and returns labels", {
    lifecycle::expect_deprecated(
      result <- brain_labels(dk())
    )
    expect_type(result, "character")
    expect_gt(length(result), 0)
  })

  it("brain_views() warns and returns views", {
    lifecycle::expect_deprecated(
      result <- brain_views(dk())
    )
    expect_type(result, "character")
  })
})


describe("atlas_region_remove", {
  it("removes region from cortical atlas with vertices", {
    atlas <- make_test_atlas()
    result <- atlas_region_remove(atlas, "frontal")
    expect_false("frontal" %in% atlas_regions(result))
    expect_true("parietal" %in% atlas_regions(result))
  })

  it("removes region by label pattern", {
    atlas <- make_test_atlas()
    result <- atlas_region_remove(atlas, "lh_frontal", match_on = "label")
    labels <- atlas_labels(result)
    expect_false("lh_frontal" %in% labels)
    expect_true("rh_frontal" %in% labels)
  })
})


describe("atlas_region_contextual", {
  it("removes from core but keeps sf geometry", {
    atlas <- make_test_atlas()
    result <- atlas_region_contextual(atlas, "parietal")
    expect_false("parietal" %in% atlas_regions(result))
    sf_labels <- atlas_sf(result)$label
    expect_true("lh_parietal" %in% sf_labels)
  })
})


describe("atlas_view_remove_region", {
  it("removes region geometry from specific views", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_remove_region(
      atlas,
      "frontal",
      match_on = "region",
      views = "axial_1"
    )
    sf_data <- atlas_sf(result)
    axial1 <- sf_data[sf_data$view == "axial_1", ]
    expect_false(any(grepl("frontal", axial1$region, ignore.case = TRUE)))
  })

  it("removes by label pattern", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_remove_region(atlas, "lh_frontal", match_on = "label")
    sf_data <- atlas_sf(result)
    expect_false("lh_frontal" %in% sf_data$label)
  })

  it("warns when atlas has no 2D data", {
    core <- data.frame(hemi = "left", region = "frontal", label = "lh_frontal")
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )
    expect_warning(
      atlas_view_remove_region(atlas, "frontal"),
      "no 2D geometry"
    )
  })
})


describe("atlas_view_keep", {
  it("keeps only specified views", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_keep(atlas, "axial_1")
    views <- atlas_views(result)
    expect_identical(views, "axial_1")
  })

  it("warns when no views match", {
    atlas <- make_multiview_atlas()
    expect_warning(
      result <- atlas_view_keep(atlas, "nonexistent"),
      "No views matched"
    )
  })

  it("warns when atlas has no 2D data", {
    core <- data.frame(hemi = "left", region = "frontal", label = "lh_frontal")
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )
    expect_warning(atlas_view_keep(atlas, "lateral"), "no 2D geometry")
  })
})


describe("atlas_view_reorder", {
  it("warns when atlas has no 2D data", {
    core <- data.frame(hemi = "left", region = "frontal", label = "lh_frontal")
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )
    expect_warning(atlas_view_reorder(atlas, "lateral"), "no 2D geometry")
  })

  it("appends unmentioned views to end of order", {
    atlas <- make_multiview_atlas()
    result <- atlas_view_reorder(atlas, "sagittal")
    views <- atlas_views(result)
    expect_identical(views[1], "sagittal")
  })

  it("warns when sf has no rows (empty views)", {
    atlas <- make_multiview_atlas()
    atlas$data$geom <- atlas$data$geom[0, ]
    expect_warning(
      atlas_view_reorder(atlas, "lateral"),
      "No matching views"
    )
  })
})


describe("rebuild_atlas_data", {
  it("works with subcortical atlas sf", {
    result <- atlas_view_keep(aseg(), "axial")
    expect_s3_class(result, "ggseg_atlas")
    expect_s3_class(result$data, "ggseg_data_subcortical")
  })

  it("works with tract atlas sf", {
    result <- atlas_view_keep(tracula(), "sagittal")
    expect_s3_class(result, "ggseg_atlas")
    expect_s3_class(result$data, "ggseg_data_tract")
  })
})


describe("atlas_region_remove with subcortical atlas", {
  it("removes matching regions from subcortical core, palette, and meshes", {
    result <- atlas_region_remove(aseg(), "Thalamus")
    expect_false(any(grepl("Thalamus", result$core$region, ignore.case = TRUE)))
    expect_false(any(grepl(
      "Thalamus",
      names(result$palette),
      ignore.case = TRUE
    )))
    expect_false(any(grepl(
      "Thalamus",
      result$data$meshes$label,
      ignore.case = TRUE
    )))
  })
})


describe("atlas_region_contextual with subcortical atlas", {
  it("removes region from core/palette but keeps sf geometry", {
    result <- atlas_region_contextual(aseg(), "Thalamus")
    expect_false(any(grepl(
      "Thalamus",
      result$core$region,
      ignore.case = TRUE
    )))
    expect_false(any(grepl(
      "Thalamus",
      names(result$palette),
      ignore.case = TRUE
    )))
    expect_s3_class(result$data, "ggseg_data_subcortical")
  })
})


describe("atlas_region_keep with subcortical atlas", {
  it("keeps only matching regions", {
    result <- atlas_region_keep(aseg(), "hippocampus")
    expect_true(all(grepl(
      "hippocampus",
      result$core$region,
      ignore.case = TRUE
    )))
    expect_s3_class(result$data, "ggseg_data_subcortical")
  })
})


describe("atlas_view_remove_region matching by region", {
  it("removes region geometry via region column match", {
    atlas <- make_test_atlas()
    result <- atlas_view_remove_region(atlas, "frontal", match_on = "region")
    remaining_labels <- result$data$geom$label
    expect_false("lh_frontal" %in% remaining_labels)
    expect_false("rh_frontal" %in% remaining_labels)
    expect_true("lh_parietal" %in% remaining_labels)
  })

  it("warns and returns NULL sf when all geometries removed", {
    atlas <- make_test_atlas()
    expect_warning(
      expect_warning(
        atlas_view_remove_region(atlas, ".*", match_on = "label"),
        "All region geometries removed"
      ),
      "no 2D geometry"
    )
  })
})


describe("atlas_view_reorder with nonexistent views", {
  it("appends unmatched order entries but still reorders", {
    atlas <- make_test_atlas()
    result <- atlas_view_reorder(atlas, "nonexistent")
    expect_s3_class(result, "ggseg_atlas")
  })
})


describe("atlas_region_remove with tract atlas", {
  it("removes matching regions from tract core and palette", {
    result <- atlas_region_remove(tracula(), "corticospinal")
    expect_false(any(grepl(
      "corticospinal",
      result$core$region,
      ignore.case = TRUE
    )))
    expect_s3_class(result$data, "ggseg_data_tract")
  })

  it("removes sf labels matching the pattern directly", {
    result <- atlas_region_remove(tracula(), "cst")
    remaining_sf <- result$data$geom$label
    expect_false(any(grepl(
      "cst",
      remaining_sf,
      ignore.case = TRUE
    )))
  })
})


describe("atlas_region_contextual with tract atlas", {
  it("keeps sf but removes from core/palette", {
    result <- atlas_region_contextual(tracula(), "corticospinal")
    expect_false(any(grepl(
      "corticospinal",
      result$core$region,
      ignore.case = TRUE
    )))
    expect_s3_class(result$data, "ggseg_data_tract")
  })
})


describe("atlas_region_keep with tract atlas", {
  it("keeps only matching regions", {
    result <- atlas_region_keep(tracula(), "corticospinal")
    expect_true(all(grepl(
      "corticospinal",
      result$core$region,
      ignore.case = TRUE
    )))
    expect_s3_class(result$data, "ggseg_data_tract")
  })
})


describe("guess_type edge cases", {
  it("returns subcortical when view column has no medial/lateral", {
    x <- data.frame(view = c("axial", "coronal"))
    expect_warning(
      result <- guess_type(x),
      "Atlas type not set"
    )
    expect_identical(result, "subcortical")
  })

  it("returns subcortical when no view info at all", {
    x <- data.frame(a = 1)
    expect_warning(
      result <- guess_type(x),
      "Atlas type not set"
    )
    expect_identical(result, "subcortical")
  })

  it("reads views from the modern $data$geom slot for a ggseg_atlas", {
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal"
    )
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(geom = sf_geom)
    )
    # no legacy $sf slot: the view must be read from $data$geom
    atlas$type <- NULL
    expect_warning(
      result <- guess_type(atlas),
      "Atlas type not set"
    )
    expect_identical(result, "cortical")
  })

  it("falls back to the legacy bare $sf slot when $data is not unified", {
    legacy <- structure(
      list(
        atlas = "old",
        sf = sf::st_sf(
          label = "lh_frontal",
          view = "lateral",
          geometry = sf::st_sfc(make_polygon())
        )
      ),
      class = "brain_atlas"
    )
    expect_warning(
      result <- guess_type(legacy),
      "Atlas type not set"
    )
    expect_identical(result, "cortical")
  })
})


describe("brain_atlas S3 method dispatch", {
  it("atlas_regions works on brain_atlas class", {
    atlas <- dk()
    class(atlas) <- c("brain_atlas", "list")
    result <- atlas_regions(atlas)
    expect_type(result, "character")
    expect_gt(length(result), 0)
  })

  it("atlas_labels works on brain_atlas class", {
    atlas <- dk()
    class(atlas) <- c("brain_atlas", "list")
    result <- atlas_labels(atlas)
    expect_type(result, "character")
    expect_gt(length(result), 0)
  })

  it("atlas_type works on brain_atlas class", {
    atlas <- dk()
    class(atlas) <- c("brain_atlas", "list")
    result <- atlas_type(atlas)
    expect_identical(result, "cortical")
  })
})


describe("atlas_region_remove with no sf data", {
  it("returns NULL sf when atlas has no sf", {
    core <- data.frame(
      hemi = c("left", "right"),
      region = c("frontal", "parietal"),
      label = c("lh_frontal", "rh_parietal")
    )
    vertices <- data.frame(
      label = c("lh_frontal", "rh_parietal")
    )
    vertices$vertices <- list(1L:3L, 4L:6L)
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )
    result <- atlas_region_remove(atlas, "frontal")
    expect_null(result$data$sf)
    expect_identical(nrow(result$core), 1L)
  })
})


# coverage backfill for atlas_utils.R ----

describe("atlas_region_op edge cases", {
  make_sq <- function(x, y, s = 2) {
    sf::st_polygon(list(matrix(
      c(x, y, x + s, y, x + s, y + s, x, y + s, x, y),
      ncol = 2,
      byrow = TRUE
    )))
  }

  make_simple_op_atlas <- function() {
    sf_geom <- sf::st_sf(
      label = c("cortex", "wm"),
      view = c("v1", "v1"),
      geometry = sf::st_sfc(make_sq(0, 0, 10), make_sq(3, 3, 4))
    )
    core <- data.frame(
      hemi = c(NA, NA),
      region = c("cortex", "wm"),
      label = c("cortex", "wm")
    )
    ggseg_atlas(
      atlas = "op",
      type = "subcortical",
      palette = c(cortex = "#aaaaaa", wm = "#bbbbbb"),
      core = core,
      data = ggseg_data_subcortical(geom = sf_geom, meshes = NULL)
    )
  }

  it("errors when into is not a single label", {
    expect_error(
      atlas_region_op(
        make_simple_op_atlas(),
        "cortex",
        "wm",
        action = "union",
        into = c("a", "b")
      ),
      "must be a single label",
      fixed = TRUE
    )
  })

  it("errors when the op produces no geometry", {
    expect_error(
      atlas_region_op(
        make_simple_op_atlas(),
        "cortex",
        "cortex",
        action = "difference",
        into = "empty"
      ),
      "produced no geometry",
      fixed = TRUE
    )
  })

  it("computes a symmetric difference", {
    r <- atlas_region_op(
      make_simple_op_atlas(),
      "cortex",
      "wm",
      action = "symdifference",
      into = "sd"
    )
    expect_true("sd" %in% r$data$geom$label)
  })

  it("matches operands on the region column", {
    r <- atlas_region_op(
      make_simple_op_atlas(),
      "cortex",
      "wm",
      action = "union",
      into = "u",
      match_on = "region"
    )
    expect_true("u" %in% r$data$geom$label)
  })

  it("errors when an atlas has no 2D geometry to operate on", {
    atlas <- make_simple_op_atlas()
    atlas$data$geom <- NULL
    expect_error(
      atlas_region_op(atlas, "cortex", "wm", action = "union", into = "u"),
      "no 2D geometry",
      fixed = TRUE
    )
  })

  it("skips views with no x geometry but keeps views with both", {
    sf_geom <- sf::st_sf(
      label = c("a", "b", "b"),
      view = c("v1", "v1", "v2"),
      geometry = sf::st_sfc(make_sq(0, 0), make_sq(1, 1), make_sq(0, 0))
    )
    core <- data.frame(
      hemi = c(NA, NA),
      region = c("a", "b"),
      label = c("a", "b")
    )
    atlas <- ggseg_atlas(
      atlas = "op",
      type = "subcortical",
      palette = c(a = "#aaaaaa", b = "#bbbbbb"),
      core = core,
      data = ggseg_data_subcortical(geom = sf_geom, meshes = NULL)
    )
    r <- atlas_region_op(atlas, "a", "b", action = "union", into = "u")
    expect_identical(unique(r$data$geom$view[r$data$geom$label == "u"]), "v1")
  })

  it("intersects per view, dropping views with only x", {
    sf_geom <- sf::st_sf(
      label = c("a", "b", "a"),
      view = c("v1", "v1", "v2"),
      geometry = sf::st_sfc(make_sq(0, 0), make_sq(1, 1), make_sq(0, 0))
    )
    core <- data.frame(
      hemi = c(NA, NA),
      region = c("a", "b"),
      label = c("a", "b")
    )
    atlas <- ggseg_atlas(
      atlas = "op",
      type = "subcortical",
      palette = c(a = "#aaaaaa", b = "#bbbbbb"),
      core = core,
      data = ggseg_data_subcortical(geom = sf_geom, meshes = NULL)
    )
    r <- atlas_region_op(atlas, "a", "b", action = "intersection", into = "ix")
    expect_identical(unique(r$data$geom$view[r$data$geom$label == "ix"]), "v1")
  })
})


describe("atlas_context_remove edge cases", {
  make_sq <- function(x, y, s = 2) {
    sf::st_polygon(list(matrix(
      c(x, y, x + s, y, x + s, y + s, x, y + s, x, y),
      ncol = 2,
      byrow = TRUE
    )))
  }

  it("returns the atlas unchanged when there is no 2D geometry", {
    core <- data.frame(hemi = NA, region = "a", label = "a")
    vertices <- data.frame(label = "a")
    vertices$vertices <- list(1L:3L)
    atlas <- ggseg_atlas(
      atlas = "t",
      type = "cortical",
      palette = c(a = "#aaaaaa"),
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )
    expect_identical(atlas_context_remove(atlas), atlas)
  })

  it("drops contextual sf rows whose label is not in core", {
    sf_geom <- sf::st_sf(
      label = c("a", "b", "ctx"),
      view = c("v1", "v1", "v1"),
      geometry = sf::st_sfc(make_sq(0, 0), make_sq(3, 3), make_sq(6, 6))
    )
    core <- data.frame(
      hemi = c(NA, NA, NA),
      region = c("a", "b", "c"),
      label = c("a", "b", "ctx")
    )
    atlas <- ggseg_atlas(
      atlas = "t",
      type = "subcortical",
      palette = c(a = "#aaaaaa", b = "#bbbbbb", ctx = "#cccccc"),
      core = core,
      data = ggseg_data_subcortical(geom = sf_geom, meshes = NULL)
    )
    contextual <- atlas_region_contextual(atlas, "c")
    expect_true("ctx" %in% contextual$data$geom$label)
    expect_false("ctx" %in% contextual$core$label)

    result <- atlas_context_remove(contextual)
    expect_false("ctx" %in% result$data$geom$label)
    expect_setequal(unique(result$data$geom$label), result$core$label)
  })
})


describe("atlas_views on a polygon atlas", {
  it("returns view names from polygon geometry", {
    poly <- as_polygon_atlas(dk())
    expect_setequal(atlas_views(poly), atlas_views(dk()))
  })
})


describe("polygon-only view removal and keeping", {
  it("removes views and warns when all views removed", {
    poly <- as_polygon_atlas(dk())
    result <- atlas_view_remove(poly, "lateral")
    expect_null(result$data$sf)
    expect_false("lateral" %in% atlas_views(result))
    expect_true("medial" %in% atlas_views(result))

    expect_warning(
      expect_warning(
        atlas_view_remove(poly, ".*"),
        "All views removed",
        fixed = TRUE
      ),
      "no 2D geometry",
      fixed = TRUE
    )
  })

  it("warns when no views match on keep", {
    poly <- as_polygon_atlas(dk())
    expect_warning(
      atlas_view_keep(poly, "zzz_nope"),
      "No views matched",
      fixed = TRUE
    )
  })
})


describe("atlas_region_contextual on a polygon atlas", {
  it("keeps brain_polygons geometry and reorders context behind core", {
    poly <- as_polygon_atlas(dk())
    region <- unique(dk()$core$region)[1]
    result <- atlas_region_contextual(poly, region)
    expect_null(result$data$sf)
    expect_s3_class(result$data$geom, "brain_polygons")
    expect_false(region %in% result$core$region)
  })
})


describe("atlas_view_gather sf early returns", {
  make_sq <- function(x, y, s = 2) {
    sf::st_polygon(list(matrix(
      c(x, y, x + s, y, x + s, y + s, x, y + s, x, y),
      ncol = 2,
      byrow = TRUE
    )))
  }

  it("returns the atlas unchanged when sf data has zero rows", {
    sf_geom <- sf::st_sf(
      label = "a",
      view = "v1",
      geometry = sf::st_sfc(make_sq(0, 0))
    )
    core <- data.frame(hemi = NA, region = "a", label = "a")
    atlas <- ggseg_atlas(
      atlas = "x",
      type = "subcortical",
      palette = c(a = "#aaaaaa"),
      core = core,
      data = ggseg_data_subcortical(geom = sf_geom, meshes = NULL)
    )
    atlas$data$geom <- atlas$data$geom[0, , drop = FALSE]
    expect_identical(atlas_view_gather(atlas), atlas)
  })

  it("casts a mixed-geometry sfc to multipolygon before packing", {
    geom <- sf::st_sfc(
      make_sq(0, 0),
      sf::st_multipolygon(list(list(matrix(
        c(2, 2, 3, 2, 3, 3, 2, 2),
        ncol = 2,
        byrow = TRUE
      ))))
    )
    expect_s3_class(geom, "sfc_GEOMETRY")
    sf_geom <- sf::st_sf(
      label = c("a", "b"),
      view = c("v1", "v2"),
      geometry = geom
    )
    core <- data.frame(
      hemi = c(NA, NA),
      region = c("a", "b"),
      label = c("a", "b")
    )
    atlas <- ggseg_atlas(
      atlas = "x",
      type = "subcortical",
      palette = c(a = "#aaaaaa", b = "#bbbbbb"),
      core = core,
      data = ggseg_data_subcortical(geom = sf_geom, meshes = NULL)
    )
    result <- atlas_view_gather(atlas)
    expect_s3_class(result$data$geom, "sf")
  })
})


describe("reposition_views early returns", {
  it("returns the input when it is neither sf nor data.frame", {
    expect_identical(reposition_views(1L:5L), 1L:5L)
  })

  it("returns the input when it has zero rows", {
    empty <- data.frame(label = character(0), view = character(0))
    expect_identical(reposition_views(empty), empty)
  })
})


describe("rebuild_data_with_geom on a cerebellar atlas", {
  it("preserves vertices and meshes after region removal", {
    result <- atlas_region_remove(suit(), "I_IV")
    expect_s3_class(result$data, "ggseg_data_cerebellar")
    expect_false("I_IV" %in% result$core$region)
    expect_false(is.null(result$data$vertices))
    expect_false(is.null(result$data$meshes))
  })
})


describe("view_remove_region_poly removing all geometry", {
  it("warns when all region geometries are removed", {
    poly <- as_polygon_atlas(dk())
    expect_warning(
      expect_warning(
        atlas_view_remove_region(poly, ".*", match_on = "label"),
        "All region geometries removed",
        fixed = TRUE
      ),
      "no 2D geometry",
      fixed = TRUE
    )
  })
})


describe("view_reorder_poly with no matching views", {
  it("warns and still returns a polygon atlas", {
    poly <- as_polygon_atlas(dk())
    expect_warning(
      result <- atlas_view_reorder(poly, "zzz_nope"),
      "No matching views",
      fixed = TRUE
    )
    expect_null(result$data$sf)
  })
})


describe("view_reorder_group_order across atlas types", {
  it("returns the order unchanged for a non-cortical sf atlas", {
    atlas <- as_sf_atlas(aseg())
    views <- atlas_views(atlas)
    result <- atlas_view_reorder(atlas, views[2])
    expect_s3_class(result$data, "ggseg_data_subcortical")
    expect_identical(unique(result$data$geom$view)[1], views[2])
  })

  it("expands a partial order into hemi groups for a cortical sf atlas", {
    result <- atlas_view_reorder(as_sf_atlas(dk()), "lateral")
    expect_identical(unique(result$data$geom$view)[1], "lateral")
  })
})

describe("order_context_behind()", {
  it("returns the geometry unchanged when it is NULL or empty", {
    expect_null(order_context_behind(NULL, character(0)))
    poly <- atlas_polygons(as_polygon_atlas(dk()))
    empty <- poly[0, , drop = FALSE]
    expect_identical(nrow(order_context_behind(empty, "lh_x")), 0L)
  })

  it("restores the brain_polygons class after reordering", {
    poly <- atlas_polygons(as_polygon_atlas(dk()))
    out <- order_context_behind(poly, poly$label[1:2])
    expect_s3_class(out, "brain_polygons")
  })

  it("restores the class when a plain-data.frame backing drops it", {
    plain <- structure(
      data.frame(label = c("a", "b"), x = c(0, 1)),
      class = c("brain_polygons", "data.frame")
    )
    out <- order_context_behind(plain, "a")
    expect_s3_class(out, "brain_polygons")
  })
})

describe("atlas_region_op() difference with no second operand", {
  it("returns the first operand's geometry when y matches nothing", {
    region <- unique(dk()$core$region)[1]
    res <- atlas_region_op(
      dk(),
      x = region,
      y = "zzz_no_such_region",
      action = "difference",
      into = "op_result",
      match_on = "region"
    )
    expect_s3_class(res, "ggseg_atlas")
    expect_true("op_result" %in% atlas_sf(res)$label)
  })
})

describe("rebuild_data_with_geom() cerebellar vertices-only branch", {
  it("rebuilds a cerebellar atlas that has vertices but no meshes", {
    sf_geom <- sf::st_sf(
      label = c("left_lobule", "right_lobule"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(make_polygon(), make_polygon2())
    )
    core <- data.frame(
      hemi = c("left", "right"),
      region = c("lobule", "lobule"),
      label = c("left_lobule", "right_lobule")
    )
    vertices <- data.frame(label = c("left_lobule", "right_lobule"))
    vertices$vertices <- list(1:3, 4:6)

    cb <- ggseg_atlas(
      atlas = "mini_cb",
      type = "cerebellar",
      core = core,
      data = ggseg_data_cerebellar(geom = sf_geom, vertices = vertices)
    )

    res <- atlas_region_remove(cb, "left", match_on = "label")
    expect_s3_class(res$data, "ggseg_data_cerebellar")
    expect_null(res$data$meshes)
    expect_false("left_lobule" %in% atlas_labels(res))
  })
})


describe("atlas_view_remove_small(scope = 'piece')", {
  # One region drawn as a big square plus a detached speck, in one view.
  speck_atlas <- function() {
    sq <- function(x0, y0, w) {
      list(cbind(
        c(x0, x0 + w, x0 + w, x0, x0),
        c(y0, y0, y0 + w, y0 + w, y0)
      ))
    }
    geom <- sf::st_sf(
      label = "a",
      view = "axial",
      geometry = sf::st_sfc(sf::st_multipolygon(list(
        sq(0, 0, 20),
        sq(100, 100, 2)
      )))
    )
    ggseg.formats::ggseg_atlas(
      atlas = "t",
      type = "subcortical",
      core = data.frame(
        hemi = "mid",
        region = "a",
        label = "a",
        stringsAsFactors = FALSE
      ),
      data = ggseg.formats::ggseg_data_subcortical(geom = geom)
    )
  }
  total_area <- function(x) {
    sum(as.numeric(sf::st_area(atlas_geom(as_sf_atlas(x)))))
  }

  it("drops the speck and keeps the main piece", {
    result <- atlas_view_remove_small(speck_atlas(), 10, scope = "piece")
    # 20x20 kept, 2x2 speck dropped
    expect_identical(total_area(result), 400)
  })

  it("keeps the region present rather than removing it wholesale", {
    result <- atlas_view_remove_small(speck_atlas(), 10, scope = "piece")
    expect_identical(nrow(result$core), 1L)
    expect_true("a" %in% atlas_labels(result))
  })

  it("never removes a region's largest piece, even below min_area", {
    # min_area far above everything: the biggest piece must still survive.
    result <- atlas_view_remove_small(speck_atlas(), 1e6, scope = "piece")
    expect_identical(total_area(result), 400)
  })

  it("leaves geometry untouched when nothing is small enough", {
    result <- atlas_view_remove_small(speck_atlas(), 1, scope = "piece")
    expect_identical(total_area(result), 404)
  })

  it("defaults to region scope", {
    expect_identical(
      atlas_view_remove_small(speck_atlas(), 10),
      atlas_view_remove_small(speck_atlas(), 10, scope = "region")
    )
  })
})
