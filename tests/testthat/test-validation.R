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
    skip_if_not_installed("sf")
    geom <- sf::st_sfc(
      make_polygon()
    )
    df <- sf::st_sf(label = "test", view = "lateral", geometry = geom)

    data <- ggseg_data_cortical(geom = df)

    expect_s3_class(geom_from_data(data), "sf")
  })

  it("coerces a data.frame with sfc geometry to sf", {
    skip_if_not_installed("sf")
    geom <- sf::st_sfc(make_polygon())
    df <- as.data.frame(
      sf::st_sf(label = "test", view = "lateral", geometry = geom)
    )
    expect_false(inherits(df, "sf"))

    out <- validate_sf(df)

    expect_s3_class(out, "sf")
  })

  it("errors when geometry is empty", {
    skip_if_not_installed("sf")
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
    withr::local_options(lifecycle_verbosity = "quiet")
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
      display = "frontal"
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
      display = "frontal"
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
      display = "frontal"
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

  it("allows context-only labels in 2D geometry (not in core)", {
    geom <- rings_as_geom(
      list(
        ring_square("lh_frontal", "lateral", 0, 0),
        ring_square("lh_medialwall", "lateral", 2, 0)
      ),
      polygons = TRUE
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )

    expect_no_warning(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(geom = geom)
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
      display = "hippocampus"
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
      display = c("frontal", "frontal")
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

  it("warns, and stays valid, on partial 2D coverage", {
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
    geom <- rings_as_geom(
      lapply(seq_len(4), function(i) {
        ring_square(labels[i], "lateral", i - 1, 0)
      }),
      polygons = TRUE
    )
    vertices <- data.frame(label = labels)
    vertices$vertices <- list(1:3, 4:6, 7:9, 10:12, 13:15)
    core <- data.frame(
      hemi = rep("left", 5),
      region = c("frontal", "parietal", "temporal", "occipital", "insula"),
      label = labels,
      display = c("frontal", "parietal", "temporal", "occipital", "insula")
    )

    expect_warning(
      atlas <- ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(geom = geom, vertices = vertices)
      ),
      class = "ggseg.formats_partial_2d_coverage"
    )
    expect_s3_class(atlas, "ggseg_atlas")
    expect_true(is_ggseg_atlas(atlas))
  })

  it("no longer gates construction on a 2D coverage percentage", {
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
    geom <- rings_as_polygons(list(
      ring_square(labels[1], "lateral", 0, 0)
    ))
    vertices <- data.frame(label = labels)
    vertices$vertices <- lapply(seq_along(labels), function(i) {
      as.integer((i * 3 - 2):(i * 3))
    })
    core <- data.frame(
      hemi = rep("left", 10),
      region = gsub("lh_", "", labels, fixed = TRUE),
      label = labels,
      display = gsub("lh_", "", labels, fixed = TRUE)
    )

    expect_warning(
      atlas <- ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(geom = geom, vertices = vertices)
      ),
      class = "ggseg.formats_partial_2d_coverage"
    )
    expect_true(is_ggseg_atlas(atlas))
  })

  it("is silent on complete 2D coverage", {
    geom <- rings_as_polygons(list(
      ring_square("lh_a", "lateral", 0, 0),
      ring_square("lh_b", "lateral", 2, 0)
    ))
    vertices <- data.frame(label = c("lh_a", "lh_b"))
    vertices$vertices <- list(1:3, 4:6)
    core <- data.frame(
      hemi = c("left", "left"),
      region = c("a", "b"),
      label = c("lh_a", "lh_b"),
      display = c("a", "b")
    )
    expect_no_condition(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(geom = geom, vertices = vertices)
      ),
      class = "ggseg.formats_partial_2d_coverage"
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


describe("single-view atlases", {
  it("stay valid and plottable for every view of aseg()", {
    local_null_pdf()
    full <- suppressWarnings(aseg())
    for (view in atlas_views(full)) {
      sub <- suppressWarnings(atlas_view_keep(full, view))
      expect_true(is_ggseg_atlas(sub), info = view)
      expect_true(is_subcortical_atlas(sub), info = view)
      expect_identical(
        sort(unique(sub$core$label)),
        sort(unique(full$core$label)),
        info = view
      )
      expect_silent(plot(sub))
    }
  })
})

describe("validate_provenance()", {
  good <- list(pipeline = "p 1.0", created = "2026-10-29")

  it("passes NULL, because most of the library predates provenance", {
    expect_null(validate_provenance(NULL))
  })

  it("passes a record naming what built the atlas and when", {
    expect_identical(validate_provenance(good), good)
  })

  it("accepts a Date for created", {
    rec <- list(pipeline = "p 1.0", created = as.Date("2026-10-29"))
    expect_identical(validate_provenance(rec), rec)
  })

  it("keeps any further fields the pipeline recorded", {
    rec <- c(good, list(parameters = list(keep = 0.25)))
    expect_identical(validate_provenance(rec)$parameters$keep, 0.25)
  })

  it("rejects something that is not a named list", {
    expect_error(validate_provenance("p 1.0"), "named list")
    expect_error(validate_provenance(list("p 1.0")), "named list")
    expect_error(validate_provenance(setNames(list(1), "")), "named list")
  })

  it("rejects a record that does not say what built the atlas, or when", {
    expect_error(validate_provenance(good["pipeline"]), "created")
    expect_error(validate_provenance(good["created"]), "pipeline")
  })

  it("rejects a pipeline or created that cannot be read as one value", {
    expect_error(
      validate_provenance(list(pipeline = c("a", "b"), created = "2026-10-29")),
      "single string"
    )
    expect_error(
      validate_provenance(list(pipeline = "p 1.0", created = 20261029)),
      "single string or a"
    )
  })
})
