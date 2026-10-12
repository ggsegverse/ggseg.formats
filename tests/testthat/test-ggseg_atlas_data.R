describe("ggseg_data_cortical", {
  it("creates ggseg_data_cortical with vertices", {
    vertices <- data.frame(label = c("region1", "region2"))
    vertices$vertices <- list(1L:5L, 6L:10L)

    data <- ggseg_data_cortical(vertices = vertices)

    expect_s3_class(data, "ggseg_data_cortical")
    expect_s3_class(data, "ggseg_atlas_data")
    expect_identical(nrow(data$vertices), 2L)
  })

  it("errors when vertices is missing", {
    expect_error(ggseg_data_cortical(), "vertices.*is required")
  })

  it("errors when vertices is not a data.frame", {
    expect_error(ggseg_data_cortical(vertices = list()), "must be a data.frame")
  })

  it("errors when vertices is missing label column", {
    vertices <- data.frame(region = c("region1", "region2"))
    vertices$vertices <- list(1L:5L, 6L:10L)

    expect_error(
      ggseg_data_cortical(vertices = vertices),
      "must contain columns"
    )
  })

  it("errors when vertices column is not a list", {
    vertices <- data.frame(label = "region1", vertices = 1)

    expect_error(
      ggseg_data_cortical(vertices = vertices),
      "must be a list-column"
    )
  })

  it("errors when vertices entries are empty", {
    vertices <- data.frame(label = c("region1", "region2"))
    vertices$vertices <- list(integer(0), 1L:5L)

    expect_error(
      ggseg_data_cortical(vertices = vertices),
      "Empty vertices for.*region1"
    )
  })

  it("creates ggseg_data_cortical with both sf and vertices", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(
        make_polygon()
      )
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    data <- ggseg_data_cortical(geom = sf_geom, vertices = vertices)

    expect_s3_class(data, "ggseg_data_cortical")
    expect_false(is.null(geom_from_data(data)))
    expect_false(is.null(data$vertices))
  })
})


describe("ggseg_data_subcortical", {
  it("creates ggseg_data_subcortical with meshes", {
    meshes <- data.frame(label = "hippocampus")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))

    data <- ggseg_data_subcortical(meshes = meshes)

    expect_s3_class(data, "ggseg_data_subcortical")
    expect_s3_class(data, "ggseg_atlas_data")
    expect_identical(nrow(data$meshes), 1L)
  })

  it("errors when meshes is missing", {
    expect_error(ggseg_data_subcortical(), "meshes.*is required")
  })

  it("validates mesh structure", {
    meshes <- data.frame(label = "region1")
    meshes$mesh <- list(list(vertices = 1))

    expect_error(
      ggseg_data_subcortical(meshes = meshes),
      "needs.*vertices.*faces"
    )
  })

  it("creates ggseg_data_subcortical with both sf and meshes", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "hippocampus",
      view = "axial",
      geometry = sf::st_sfc(
        make_polygon()
      )
    )
    meshes <- data.frame(label = "hippocampus")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))

    data <- ggseg_data_subcortical(geom = sf_geom, meshes = meshes)

    expect_s3_class(data, "ggseg_data_subcortical")
    expect_false(is.null(geom_from_data(data)))
    expect_false(is.null(data$meshes))
  })
})


describe("ggseg_data_tract", {
  it("creates ggseg_data_tract from meshes with centerline metadata", {
    meshes <- data.frame(label = "cst_left")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5),
      metadata = list(
        n_centerline_points = 10,
        centerline = matrix(1:30, ncol = 3),
        tangents = matrix(1:30, ncol = 3)
      )
    ))

    data <- withr::with_options(
      list(lifecycle_verbosity = "quiet"),
      ggseg_data_tract(meshes = meshes)
    )

    expect_s3_class(data, "ggseg_data_tract")
    expect_s3_class(data, "ggseg_atlas_data")
    expect_identical(nrow(data$centerlines), 1L)
  })

  it("signals the deprecation of the meshes argument", {
    meshes <- data.frame(label = "cst_left")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5),
      metadata = list(
        n_centerline_points = 10,
        centerline = matrix(1:30, ncol = 3),
        tangents = matrix(1:30, ncol = 3)
      )
    ))
    withr::local_options(lifecycle_verbosity = "warning")
    expect_warning(
      ggseg_data_tract(meshes = meshes),
      class = "lifecycle_warning_deprecated"
    )
  })

  it("errors when no geom or centerlines provided", {
    expect_error(ggseg_data_tract(), "geom.*centerlines")
  })

  it("errors when all meshes lack centerline metadata", {
    meshes <- data.frame(label = "cst_left")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5),
      metadata = list(n_centerline_points = 10)
    ))

    withr::local_options(lifecycle_verbosity = "quiet")
    expect_warning(
      expect_error(ggseg_data_tract(meshes = meshes), "No valid centerlines"),
      "missing centerline metadata"
    )
  })

  it("creates ggseg_data_tract with sf geometry", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "cst_left",
      view = "sagittal",
      geometry = sf::st_sfc(
        make_polygon()
      )
    )

    data <- ggseg_data_tract(geom = sf_geom)

    expect_s3_class(data, "ggseg_data_tract")
    expect_false(is.null(geom_from_data(data)))
  })

  it("creates ggseg_data_tract with centerlines directly", {
    pts <- matrix(rnorm(30), ncol = 3)
    tangents <- matrix(rnorm(30), ncol = 3)
    centerlines <- data.frame(label = "cst_left")
    centerlines$points <- list(pts)
    centerlines$tangents <- list(tangents)

    data <- ggseg_data_tract(centerlines = centerlines)

    expect_s3_class(data, "ggseg_data_tract")
    expect_identical(nrow(data$centerlines), 1L)
  })

  it("computes tangents when not provided", {
    pts <- matrix(c(0, 0, 0, 1, 0, 0, 2, 0, 0), ncol = 3, byrow = TRUE)
    centerlines <- data.frame(label = "cst_left")
    centerlines$points <- list(pts)

    data <- ggseg_data_tract(centerlines = centerlines)

    expect_true("tangents" %in% names(data$centerlines))
    expect_true(is.matrix(data$centerlines$tangents[[1]]))
    expect_identical(ncol(data$centerlines$tangents[[1]]), 3L)
  })
})


describe("validate_centerlines", {
  it("errors when missing required columns", {
    bad <- data.frame(trajectory = "a")
    bad$points <- list(matrix(1:9, ncol = 3))
    expect_error(
      ggseg_data_tract(centerlines = bad),
      "missing required columns"
    )
  })

  it("errors when points is not a list", {
    bad <- data.frame(label = "a", points = 1)
    expect_error(
      ggseg_data_tract(centerlines = bad),
      "list-column"
    )
  })

  it("errors when points entry is not an n x 3 matrix", {
    bad <- data.frame(label = "a")
    bad$points <- list(matrix(1:6, ncol = 2))
    expect_error(
      ggseg_data_tract(centerlines = bad),
      "n x 3 matrix"
    )
  })
})


describe("compute_tangents", {
  it("handles single-segment centerline", {
    pts <- matrix(c(0, 0, 0, 1, 0, 0), ncol = 3, byrow = TRUE)
    centerlines <- data.frame(label = "a")
    centerlines$points <- list(pts)

    data <- ggseg_data_tract(centerlines = centerlines)
    tangents <- data$centerlines$tangents[[1]]

    expect_identical(nrow(tangents), 2L)
  })

  it("handles zero-length tangent vectors", {
    pts <- matrix(c(0, 0, 0, 0, 0, 0, 1, 0, 0), ncol = 3, byrow = TRUE)
    centerlines <- data.frame(label = "a")
    centerlines$points <- list(pts)

    data <- ggseg_data_tract(centerlines = centerlines)
    tangents <- data$centerlines$tangents[[1]]

    expect_identical(tangents[1, ], c(1, 0, 0))
    expect_identical(nrow(tangents), 3L)
  })
})


describe("print methods", {
  it("prints ggseg_data_cortical with sf and vertices", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    data <- ggseg_data_cortical(geom = sf_geom, vertices = vertices)
    expect_s3_class(data, "ggseg_atlas_data")
    expect_snapshot(print(data))
  })

  it("prints ggseg_data_subcortical with sf and meshes", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "hippocampus",
      view = "axial",
      geometry = sf::st_sfc(make_polygon())
    )
    meshes <- data.frame(label = "hippocampus")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))

    data <- ggseg_data_subcortical(geom = sf_geom, meshes = meshes)
    expect_s3_class(data, "ggseg_atlas_data")
    expect_snapshot(print(data))
  })

  it("prints ggseg_data_tract with centerlines", {
    pts <- matrix(rnorm(30), ncol = 3)
    tangents <- matrix(rnorm(30), ncol = 3)
    centerlines <- data.frame(label = "cst_left")
    centerlines$points <- list(pts)
    centerlines$tangents <- list(tangents)

    data <- ggseg_data_tract(centerlines = centerlines)
    expect_s3_class(data, "ggseg_atlas_data")
    expect_snapshot(print(data))
  })

  it("prints ggseg_data_cortical without sf", {
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    data <- ggseg_data_cortical(vertices = vertices)
    expect_s3_class(data, "ggseg_atlas_data")
    expect_snapshot(print(data))
  })

  it("summarises brain_polygons geometry in the 2D view listing", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    polygons <- sf_to_polygons(sf_geom)
    expect_s3_class(polygons, "brain_polygons")

    data <- ggseg_data_cortical(geom = polygons)
    expect_s3_class(geom_from_data(data), "brain_polygons")
    expect_match(summarise_2d(data), "polygons")
    expect_match(summarise_2d(data), "lateral")
    expect_snapshot(print(data))
  })

  it("prints ggseg_data_subcortical without sf", {
    meshes <- data.frame(label = "hippocampus")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))

    data <- ggseg_data_subcortical(meshes = meshes)
    expect_s3_class(data, "ggseg_atlas_data")
    expect_snapshot(print(data))
  })

  it("prints ggseg_data_cerebellar with sf and vertices", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "left_I-IV",
      view = "flatmap",
      geometry = sf::st_sfc(make_polygon())
    )
    vertices <- data.frame(label = "left_I-IV")
    vertices$vertices <- list(0L:9L)

    data <- ggseg_data_cerebellar(
      geom = sf_geom,
      vertices = vertices
    )
    expect_s3_class(data, "ggseg_atlas_data")
    expect_snapshot(print(data))
  })

  it("prints ggseg_data_cerebellar without vertices", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "left_I-IV",
      view = "flatmap",
      geometry = sf::st_sfc(make_polygon())
    )

    data <- ggseg_data_cerebellar(geom = sf_geom)
    expect_s3_class(data, "ggseg_atlas_data")
    expect_snapshot(print(data))
  })

  it("prints ggseg_data_tract with sf and centerlines", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "cst_left",
      view = "sagittal",
      geometry = sf::st_sfc(make_polygon())
    )
    pts <- matrix(rnorm(30), ncol = 3)
    tangents <- matrix(rnorm(30), ncol = 3)
    centerlines <- data.frame(label = "cst_left")
    centerlines$points <- list(pts)
    centerlines$tangents <- list(tangents)

    data <- ggseg_data_tract(geom = sf_geom, centerlines = centerlines)
    expect_s3_class(data, "ggseg_atlas_data")
    expect_snapshot(print(data))
  })
})


describe("ggseg_data_cerebellar", {
  it("creates ggseg_data_cerebellar with vertices", {
    vertices <- data.frame(label = "left_I-IV")
    vertices$vertices <- list(0L:9L)

    data <- ggseg_data_cerebellar(vertices = vertices)

    expect_s3_class(data, "ggseg_data_cerebellar")
    expect_s3_class(data, "ggseg_atlas_data")
    expect_identical(nrow(data$vertices), 1L)
  })

  it("creates ggseg_data_cerebellar with sf", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "left_I-IV",
      view = "flatmap",
      geometry = sf::st_sfc(make_polygon())
    )

    data <- ggseg_data_cerebellar(geom = sf_geom)

    expect_s3_class(data, "ggseg_data_cerebellar")
    expect_false(is.null(geom_from_data(data)))
    expect_null(data$vertices)
  })

  it("creates ggseg_data_cerebellar with both sf and vertices", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "left_I-IV",
      view = "flatmap",
      geometry = sf::st_sfc(make_polygon())
    )
    vertices <- data.frame(label = "left_I-IV")
    vertices$vertices <- list(0L:9L)

    data <- ggseg_data_cerebellar(
      geom = sf_geom,
      vertices = vertices
    )

    expect_s3_class(data, "ggseg_data_cerebellar")
    expect_false(is.null(geom_from_data(data)))
    expect_false(is.null(data$vertices))
  })

  it("errors when neither geom nor vertices provided", {
    expect_error(
      ggseg_data_cerebellar(),
      "geom.*vertices.*is required"
    )
  })

  it("validates vertices structure", {
    vertices <- data.frame(label = "region1")
    vertices$vertices <- list(integer(0))

    expect_error(
      ggseg_data_cerebellar(vertices = vertices),
      "Empty vertices"
    )
  })
})


describe("deprecated brain_data wrappers", {
  it("brain_data_cortical warns and returns correct class", {
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    lifecycle::expect_deprecated(
      result <- brain_data_cortical(vertices = vertices)
    )
    expect_s3_class(result, "ggseg_data_cortical")
  })

  it("brain_data_subcortical warns and returns correct class", {
    meshes <- data.frame(label = "hippocampus")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))

    lifecycle::expect_deprecated(
      result <- brain_data_subcortical(meshes = meshes)
    )
    expect_s3_class(result, "ggseg_data_subcortical")
  })

  it("brain_data_tract warns and returns correct class", {
    centerlines <- data.frame(label = "cst_left")
    centerlines$points <- list(matrix(rnorm(30), ncol = 3))
    centerlines$tangents <- list(matrix(rnorm(30), ncol = 3))

    lifecycle::expect_deprecated(
      result <- brain_data_tract(centerlines = centerlines)
    )
    expect_s3_class(result, "ggseg_data_tract")
  })
})


describe("meshes_to_centerlines", {
  it("returns NULL for NULL input", {
    expect_null(meshes_to_centerlines(NULL))
  })
})


describe("print_mesh_summary with NULL mesh entries", {
  it("handles NULL mesh in vapply without error", {
    meshes <- data.frame(label = c("region1", "region2"))
    meshes$mesh <- list(
      NULL,
      list(
        vertices = data.frame(x = 1:5, y = 1:5, z = 1:5),
        faces = data.frame(i = 1:2, j = 2:3, k = 3:4)
      )
    )
    expect_output(
      print_mesh_summary(meshes),
      "region1"
    )
  })
})
