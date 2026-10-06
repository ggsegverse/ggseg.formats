describe("validate_sf", {
  it("errors when sf is not a data.frame", {
    withr::local_options(lifecycle_verbosity = "quiet")
    expect_error(
      ggseg_data_cortical(sf = "not a dataframe"),
      "must be a data.frame"
    )
  })

  it("errors when sf is missing required columns", {
    withr::local_options(lifecycle_verbosity = "quiet")
    sf_bad <- data.frame(label = "test", view = "lateral")
    expect_error(
      ggseg_data_cortical(sf = sf_bad),
      "must contain columns.*geometry"
    )
  })

  it("errors when geometry is not sfc", {
    withr::local_options(lifecycle_verbosity = "quiet")
    sf_bad <- data.frame(label = "test", view = "lateral", geometry = "not sfc")
    expect_error(
      ggseg_data_cortical(sf = sf_bad),
      "must be an sf geometry column"
    )
  })

  it("stores sfc-backed sf geometry as the geom slot", {
    geom <- sf::st_sfc(
      make_polygon()
    )
    df <- sf::st_sf(label = "test", view = "lateral", geometry = geom)

    data <- ggseg_data_cortical(geom = df)

    expect_s3_class(geom_from_data(data), "sf")
  })

  it("coerces a data.frame with sfc geometry to sf", {
    geom <- sf::st_sfc(make_polygon())
    df <- as.data.frame(
      sf::st_sf(label = "test", view = "lateral", geometry = geom)
    )
    expect_false(inherits(df, "sf"))

    out <- validate_sf(df)

    expect_s3_class(out, "sf")
  })

  it("errors when geometry is empty", {
    withr::local_options(lifecycle_verbosity = "quiet")
    sf_bad <- sf::st_sf(
      label = c("region1", "region2"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(
        sf::st_polygon(),
        make_polygon()
      )
    )

    expect_error(
      ggseg_data_cortical(sf = sf_bad),
      "Empty geometry for.*region1"
    )
  })
})


describe("validate_vertices", {
  it("errors when vertices is missing required columns", {
    vertices <- data.frame(region = "test")
    vertices$vertices <- list(1L:3L)

    expect_error(
      ggseg_data_cortical(vertices = vertices),
      "must contain columns.*label"
    )
  })
})


describe("validate_meshes", {
  it("errors when meshes is not a data.frame", {
    expect_error(
      ggseg_data_subcortical(meshes = "not a dataframe"),
      "must be a data.frame"
    )
  })

  it("errors when meshes is missing required columns", {
    meshes <- data.frame(region = "test")
    meshes$mesh <- list(NULL)

    expect_error(
      ggseg_data_subcortical(meshes = meshes),
      "must contain columns.*label"
    )
  })

  it("errors when mesh column is not a list", {
    meshes <- data.frame(label = "test", mesh = "not a list")

    expect_error(
      ggseg_data_subcortical(meshes = meshes),
      "must be a list-column"
    )
  })

  it("errors when mesh vertices are missing xyz columns", {
    meshes <- data.frame(label = "bad_mesh")
    meshes$mesh <- list(list(
      vertices = data.frame(a = 1:10, b = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))

    expect_error(
      ggseg_data_subcortical(meshes = meshes),
      "Mesh vertices.*must be a data.frame"
    )
  })

  it("errors when mesh faces are missing ijk columns", {
    meshes <- data.frame(label = "bad_mesh")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(a = 1:3, b = 2:4)
    ))

    expect_error(
      ggseg_data_subcortical(meshes = meshes),
      "Mesh faces.*must be a data.frame"
    )
  })

  it("errors when mesh entries are NULL", {
    meshes <- data.frame(label = c("region1", "region2"))
    meshes$mesh <- list(
      NULL,
      list(
        vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
        faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
      )
    )

    expect_error(
      ggseg_data_subcortical(meshes = meshes),
      "Empty mesh for.*region1"
    )
  })

  it("errors when mesh vertices are empty", {
    meshes <- data.frame(label = "region1")
    meshes$mesh <- list(list(
      vertices = data.frame(x = numeric(0), y = numeric(0), z = numeric(0)),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))

    expect_error(
      ggseg_data_subcortical(meshes = meshes),
      "Empty mesh for.*region1"
    )
  })

  it("errors when mesh faces are empty", {
    meshes <- data.frame(label = "region1")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = integer(0), j = integer(0), k = integer(0))
    ))

    expect_error(
      ggseg_data_subcortical(meshes = meshes),
      "Empty mesh for.*region1"
    )
  })
})


describe("validate_tract_metadata", {
  it("errors when mesh metadata is not a list", {
    meshes <- data.frame(label = "cst_left")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5),
      metadata = "not a list"
    ))

    expect_error(ggseg_data_tract(meshes = meshes))
  })
})


describe("validate_palette", {
  it("errors when palette is not a named character vector", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    expect_error(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        palette = c("red", "blue"),
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      "must be a named character vector"
    )
  })

  it("warns about unknown labels in palette", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    expect_warning(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        palette = c(lh_frontal = "#FF0000", unknown = "#00FF00"),
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      "not found in.*core"
    )
  })
})


describe("validate_data_labels", {
  it("allows context-only labels in vertices (not in core)", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    vertices <- data.frame(label = c("lh_frontal", "lh_unknown"))
    vertices$vertices <- list(1L:3L, 4L:6L)

    expect_no_warning(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      )
    )
  })

  it("allows context-only labels in sf (not in core)", {
    sf_geom <- sf::st_sf(
      label = c("lh_frontal", "lh_medialwall"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2()
      )
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )

    expect_no_warning(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(geom = sf_geom)
      )
    )
  })

  it("allows context-only labels in meshes (not in core)", {
    meshes <- data.frame(label = c("hippocampus", "unknown_structure"))
    meshes$mesh <- list(
      list(
        vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
        faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
      ),
      list(
        vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
        faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
      )
    )
    core <- data.frame(
      hemi = NA,
      region = "hippocampus",
      label = "hippocampus",
      names = "hippocampus"
    )

    expect_no_warning(
      ggseg_atlas(
        atlas = "test",
        type = "subcortical",
        core = core,
        data = ggseg_data_subcortical(meshes = meshes)
      )
    )
  })

  it("errors when core labels are missing from 3D data", {
    core <- data.frame(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      names = c("frontal", "frontal"),
      names = c("frontal", "frontal")
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    expect_error(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      "Missing from vertices.*rh_frontal"
    )
  })

  it("accepts partial sf coverage when vertices are complete", {
    labels <- paste0(
      "lh_",
      c(
        "frontal",
        "parietal",
        "temporal",
        "occipital",
        "insula"
      )
    )
    sf_geom <- sf::st_sf(
      label = labels[1:4],
      view = rep("lateral", 4),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon(c(1, 0, 2, 0, 2, 1, 1, 0)),
        make_polygon(c(2, 0, 3, 0, 3, 1, 2, 0)),
        make_polygon(c(3, 0, 4, 0, 4, 1, 3, 0))
      )
    )
    vertices <- data.frame(label = labels)
    vertices$vertices <- list(1:3, 4:6, 7:9, 10:12, 13:15)
    core <- data.frame(
      hemi = rep("left", 5),
      region = c("frontal", "parietal", "temporal", "occipital", "insula"),
      label = labels,
      names = c("frontal", "parietal", "temporal", "occipital", "insula")
    )

    expect_warning(
      atlas <- ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(geom = sf_geom, vertices = vertices)
      ),
      "sf covers only 80%"
    )
    expect_s3_class(atlas, "ggseg_atlas")
  })

  it("errors when sf coverage is below 80%", {
    labels <- paste0(
      "lh_",
      c(
        "frontal",
        "parietal",
        "temporal",
        "occipital",
        "insula",
        "cingulate",
        "precuneus",
        "cuneus",
        "lingual",
        "fusiform"
      )
    )
    sf_geom <- sf::st_sf(
      label = labels[1],
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    vertices <- data.frame(label = labels)
    vertices$vertices <- lapply(seq_along(labels), function(i) {
      as.integer((i * 3 - 2):(i * 3))
    })
    core <- data.frame(
      hemi = rep("left", 10),
      region = gsub("lh_", "", labels, fixed = TRUE),
      label = labels,
      names = gsub("lh_", "", labels, fixed = TRUE)
    )

    expect_error(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(geom = sf_geom, vertices = vertices)
      ),
      "minimum 80%"
    )
  })
})


describe("validate_tract_metadata", {
  it("warns when metadata has partial fields", {
    metadata <- list(
      n_centerline_points = 10,
      centerline = matrix(1:30, ncol = 3)
    )
    expect_warning(
      validate_tract_metadata(metadata, "cst_left"),
      "missing"
    )
  })

  it("warns when metadata is not a list", {
    expect_warning(
      validate_tract_metadata("not a list", "bad_tract"),
      "should be a list"
    )
  })
})


describe("validate_meshes calls validate_tract_metadata", {
  it("validates tract mesh metadata when tract = TRUE", {
    meshes <- data.frame(label = "cst_left")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5),
      metadata = list(
        n_centerline_points = 10,
        centerline = matrix(rnorm(30), ncol = 3),
        tangents = matrix(rnorm(30), ncol = 3)
      )
    ))

    result <- validate_meshes(meshes, tract = TRUE)
    expect_identical(nrow(result), 1L)
  })
})
