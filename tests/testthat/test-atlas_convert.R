describe("convert_legacy_brain_atlas", {
  it("errors when both atlases are NULL", {
    expect_error(
      convert_legacy_brain_atlas(atlas_2d = NULL, atlas_3d = NULL),
      "At least one"
    )
  })

  it("errors when atlas_2d is wrong class", {
    expect_error(
      convert_legacy_brain_atlas(atlas_2d = "not_an_atlas"),
      "ggseg_atlas"
    )
  })

  it("errors when atlas_3d lacks ggseg_3d column", {
    bad_3d <- data.frame(hemi = "left", surf = "inflated")

    expect_error(
      convert_legacy_brain_atlas(atlas_3d = bad_3d),
      "ggseg_3d"
    )
  })

  it("runs successfully with valid 2D atlas", {
    mock_2d <- structure(
      list(
        atlas = "test",
        type = "cortical",
        core = data.frame(
          hemi = "left",
          region = "test",
          label = "lh_test",
          names = "test"
        ),
        palette = c(lh_test = "#FF0000"),
        data = list(
          sf = NULL,
          vertices = data.frame(
            label = "lh_test"
          )
        )
      ),
      class = "brain_atlas"
    )
    mock_2d$data$vertices$vertices <- list(1:5)

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )

    expect_message(
      result <- convert_legacy_brain_atlas(atlas_2d = mock_2d),
      "Using existing vertex data"
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_identical(result$atlas, "test")
  })

  it("runs successfully with valid 3D atlas containing vertices", {
    mock_3d <- data.frame(
      atlas = "test_3d",
      hemi = c("left", "right"),
      surf = c("inflated", "inflated")
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        region = "motor",
        label = "lh_motor",
        colour = "#FF0000"
      ),
      data.frame(
        region = "motor",
        label = "rh_motor",
        colour = "#0000FF"
      )
    )
    mock_3d$ggseg_3d[[1]]$vertices <- list(1:10)
    mock_3d$ggseg_3d[[2]]$vertices <- list(11:20)

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )

    expect_message(
      result <- convert_legacy_brain_atlas(atlas_3d = mock_3d),
      "Using existing vertex indices"
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_identical(result$atlas, "test")
    expect_true("vertices" %in% names(result$data$vertices))
  })

  it("uses custom atlas_name when provided", {
    mock_2d <- structure(
      list(
        atlas = "original_name",
        type = "cortical",
        core = data.frame(
          hemi = "left",
          region = "test",
          label = "lh_test",
          names = "test"
        ),
        palette = c(lh_test = "#FF0000"),
        data = list(sf = NULL, vertices = data.frame(label = "lh_test"))
      ),
      class = "brain_atlas"
    )
    mock_2d$data$vertices$vertices <- list(1:5)

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )

    expect_message(
      result <- convert_legacy_brain_atlas(
        atlas_2d = mock_2d,
        atlas_name = "custom_name"
      ),
      "Using existing vertex data"
    )

    expect_identical(result$atlas, "custom_name")
  })

  it("handles subcortical type with mesh data", {
    mock_3d <- data.frame(
      atlas = "test_3d",
      hemi = c("subcort", "subcort"),
      surf = c("LCBC", "LCBC")
    )
    mock_mesh <- list(
      vertices = data.frame(x = 1:3, y = 1:3, z = 1:3),
      faces = data.frame(i = 1, j = 2, k = 3)
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        region = "thalamus",
        label = "Left-Thalamus",
        colour = "#FF0000"
      ),
      data.frame(
        region = "thalamus",
        label = "Right-Thalamus",
        colour = "#0000FF"
      )
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(mock_mesh)
    mock_3d$ggseg_3d[[2]]$mesh <- list(mock_mesh)

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )

    expect_message(
      result <- convert_legacy_brain_atlas(
        atlas_3d = mock_3d,
        type = "subcortical"
      ),
      "Extracted meshes"
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_identical(result$type, "subcortical")
  })

  it("converts legacy 2D atlas without core", {
    mock_2d <- structure(
      list(
        atlas = "old_atlas",
        type = "cortical",
        core = NULL,
        palette = c(lh_test = "#FF0000"),
        data = list(sf = NULL, vertices = NULL),
        sf = NULL
      ),
      class = "brain_atlas"
    )

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )
    local_mocked_bindings(
      convert_legacy_brain_data = function(atlas) {
        atlas$core <- data.frame(
          hemi = "left",
          region = "test",
          label = "lh_test",
          names = "test"
        )
        vdf <- data.frame(label = "lh_test")
        vdf$vertices <- list(1:10)
        atlas$data$vertices <- vdf
        atlas
      }
    )

    expect_message(
      result <- convert_legacy_brain_atlas(atlas_2d = mock_2d),
      "Using existing vertex data"
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_identical(result$atlas, "old_atlas")
  })

  it("extracts sf from data$sf when available", {
    skip_if_not_installed("sf")
    mock_sf <- sf::st_sf(
      label = "lh_test",
      view = "lateral",
      geometry = sf::st_sfc(
        sf::st_polygon(list(matrix(
          c(0, 0, 1, 0, 1, 1, 0, 0),
          ncol = 2,
          byrow = TRUE
        )))
      )
    )
    vdf <- data.frame(label = "lh_test")
    vdf$vertices <- list(1:10)
    mock_2d <- structure(
      list(
        atlas = "test",
        type = "cortical",
        core = data.frame(
          hemi = "left",
          region = "test",
          label = "lh_test",
          names = "test"
        ),
        palette = c(lh_test = "#FF0000"),
        data = ggseg_data_cortical(geom = mock_sf, vertices = vdf)
      ),
      class = "brain_atlas"
    )

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )

    expect_message(
      result <- convert_legacy_brain_atlas(atlas_2d = mock_2d),
      "Using existing vertex data"
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_false(is.null(atlas_geom(result)))
  })

  it("warns when vertex inference fails for cortical 3D atlas", {
    mock_3d <- data.frame(
      atlas = "test_3d",
      hemi = c("left", "right"),
      surf = c("inflated", "inflated")
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        region = "motor",
        label = "lh_motor",
        colour = "#FF0000"
      ),
      data.frame(
        region = "motor",
        label = "rh_motor",
        colour = "#0000FF"
      )
    )
    mock_3d$ggseg_3d[[1]]$vertices <- list(integer(0))
    mock_3d$ggseg_3d[[2]]$vertices <- list(integer(0))

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )
    local_mocked_bindings(
      infer_vertices_from_meshes = function(...) NULL
    )

    expect_warning(
      tryCatch(
        convert_legacy_brain_atlas(atlas_3d = mock_3d),
        error = function(e) NULL
      ),
      "Could not infer",
      fixed = TRUE
    )
  })

  it("extracts rgl-style meshes with vb/it columns", {
    mock_3d <- data.frame(
      atlas = "test_3d",
      hemi = "subcort",
      surf = "LCBC"
    )
    rgl_mesh <- list(
      vb = matrix(c(1, 2, 3, 4, 5, 6, 7, 8, 9), nrow = 3),
      it = matrix(c(1, 2, 3), nrow = 3)
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        region = "thalamus",
        label = "Left-Thalamus",
        colour = "#FF0000"
      )
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(rgl_mesh)

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )

    expect_message(
      result <- convert_legacy_brain_atlas(
        atlas_3d = mock_3d,
        type = "subcortical"
      ),
      "Extracted meshes"
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_false(is.null(result$data$meshes))
    mesh <- result$data$meshes$mesh[[1]]
    expect_identical(mesh$vertices$x, c(1, 4, 7))
  })
})


describe("infer_atlas_type", {
  it("returns atlas_2d type when has_2d is TRUE", {
    mock_2d <- list(type = "cortical")
    result <- infer_atlas_type(TRUE, mock_2d, NULL)
    expect_identical(result, "cortical")
  })

  it("returns subcortical when atlas_3d has subcort hemi", {
    mock_3d <- data.frame(hemi = c("subcort", "subcort"))
    result <- infer_atlas_type(FALSE, NULL, mock_3d)
    expect_identical(result, "subcortical")
  })

  it("defaults to cortical when no subcort hemi", {
    mock_3d <- data.frame(hemi = c("left", "right"))
    result <- infer_atlas_type(FALSE, NULL, mock_3d)
    expect_identical(result, "cortical")
  })
})


describe("has_vertex_data", {
  it("returns FALSE when no vertices column", {
    dt <- data.frame(label = "test")
    expect_false(has_vertex_data(dt))
  })

  it("returns FALSE when all vertices are empty", {
    dt <- data.frame(label = c("a", "b"))
    dt$vertices <- list(integer(0), integer(0))
    expect_false(has_vertex_data(dt))
  })

  it("returns TRUE when some vertices have data", {
    dt <- data.frame(label = c("a", "b"))
    dt$vertices <- list(1:5, integer(0))
    expect_true(has_vertex_data(dt))
  })
})


describe("remap_palette_to_labels", {
  it("remaps region-keyed palette to label-keyed", {
    palette <- c("motor" = "#FF0000", "visual" = "#0000FF")
    core <- data.frame(
      region = c("motor", "motor", "visual"),
      label = c("lh_motor", "rh_motor", "lh_visual")
    )

    result <- remap_palette_to_labels(palette, core)

    expect_identical(result[["lh_motor"]], "#FF0000")
    expect_identical(result[["rh_motor"]], "#FF0000")
    expect_identical(result[["lh_visual"]], "#0000FF")
  })

  it("returns NULL for NULL palette", {
    core <- data.frame(region = "test", label = "lh_test")
    expect_null(remap_palette_to_labels(NULL, core))
  })

  it("returns NULL when no regions match", {
    palette <- c("unknown" = "#FF0000")
    core <- data.frame(region = "motor", label = "lh_motor")
    expect_null(remap_palette_to_labels(palette, core))
  })

  it("skips NA regions in core", {
    palette <- c("motor" = "#FF0000")
    core <- data.frame(
      region = c("motor", NA),
      label = c("lh_motor", "lh_medialwall")
    )

    result <- remap_palette_to_labels(palette, core)

    expect_named(result, "lh_motor")
  })
})


describe("convert_legacy_brain_atlas 2D-only path", {
  it("creates atlas from 2D sf without vertex data", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    mock_2d <- structure(
      list(
        atlas = "test",
        type = "cortical",
        palette = c(lh_frontal = "#FF0000"),
        core = core,
        data = ggseg_data_cortical(geom = sf_geom)
      ),
      class = "brain_atlas"
    )

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )

    expect_message(
      result <- convert_legacy_brain_atlas(atlas_2d = mock_2d),
      "Created atlas from 2D only"
    )
    expect_s3_class(result, "ggseg_atlas")
    expect_null(result$data$vertices)
  })

  it("extracts meshes with non-rgl format", {
    mock_3d <- data.frame(
      atlas = "test_3d",
      hemi = "subcort",
      surf = "LCBC"
    )
    mesh_data <- list(
      vertices = data.frame(x = 1:5, y = 1:5, z = 1:5),
      faces = data.frame(i = 1:2, j = 2:3, k = 3:4)
    )
    mock_3d$ggseg_3d <- list(data.frame(
      region = "thalamus",
      label = "Left-Thalamus",
      colour = "#FF0000"
    ))
    mock_3d$ggseg_3d[[1]]$mesh <- list(mesh_data)

    local_mocked_bindings(
      signal_stage = function(...) invisible(NULL),
      .package = "lifecycle"
    )

    expect_message(
      result <- convert_legacy_brain_atlas(
        atlas_3d = mock_3d,
        type = "subcortical"
      ),
      "Extracted meshes"
    )
    mesh <- result$data$meshes$mesh[[1]]
    expect_identical(mesh$vertices$x, 1:5)
    expect_identical(mesh$faces$i, 1:2)
  })
})


describe("unify_legacy_atlases (deprecated)", {
  it("warns and delegates to convert_legacy_brain_atlas", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    mock_2d <- structure(
      list(
        atlas = "test",
        type = "cortical",
        palette = c(lh_frontal = "#FF0000"),
        core = core,
        data = ggseg_data_cortical(geom = sf_geom)
      ),
      class = "brain_atlas"
    )

    expect_message(
      lifecycle::expect_deprecated(
        result <- unify_legacy_atlases(atlas_2d = mock_2d)
      ),
      "Created atlas from 2D only"
    )
    expect_s3_class(result, "ggseg_atlas")
  })
})


describe("infer_vertices_from_meshes", {
  it("returns correct 0-based indices with matching coordinates", {
    brain_verts <- data.frame(
      x = c(1.0, 2.0, 3.0, 4.0, 5.0),
      y = c(10.0, 20.0, 30.0, 40.0, 50.0),
      z = c(100.0, 200.0, 300.0, 400.0, 500.0)
    )
    mock_brain_meshes <- list(
      lh_inflated = list(vertices = brain_verts)
    )

    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "inflated"
    )
    region_mesh <- list(
      vertices = data.frame(
        x = c(1.0, 3.0, 5.0),
        y = c(10.0, 30.0, 50.0),
        z = c(100.0, 300.0, 500.0)
      )
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = "lh_motor",
        region = "motor"
      )
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(region_mesh)

    result <- infer_vertices_from_meshes(
      mock_3d,
      surface = "inflated",
      brain_meshes = mock_brain_meshes
    )

    expect_type(result, "list")
    expect_true("lh_motor" %in% names(result))
    expect_identical(sort(result[["lh_motor"]]), c(0L, 2L, 4L))
  })

  it("returns NULL when brain_meshes is NULL and surface not inflated", {
    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "pial"
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = "lh_motor",
        region = "motor"
      )
    )

    expect_error(
      infer_vertices_from_meshes(
        mock_3d,
        surface = "pial",
        brain_meshes = NULL
      ),
      "not available"
    )
  })

  it("uses internal inflated mesh when brain_meshes is NULL", {
    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "inflated"
    )

    lh_mesh <- get_brain_mesh("lh", "inflated")
    v1 <- lh_mesh$vertices[1, ]

    region_mesh <- list(
      vertices = data.frame(x = v1$x, y = v1$y, z = v1$z)
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = "lh_test",
        region = "test"
      )
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(region_mesh)

    result <- infer_vertices_from_meshes(mock_3d, surface = "inflated")

    expect_type(result, "list")
    expect_true("lh_test" %in% names(result))
    expect_identical(result[["lh_test"]], 0L)
  })

  it("skips regions with no mesh column", {
    mock_brain_meshes <- list(
      lh_inflated = list(
        vertices = data.frame(x = 1:3, y = 1:3, z = 1:3)
      )
    )
    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "inflated"
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = "lh_motor",
        region = "motor"
      )
    )

    result <- infer_vertices_from_meshes(
      mock_3d,
      surface = "inflated",
      brain_meshes = mock_brain_meshes
    )

    expect_null(result)
  })

  it("handles rgl-style vb mesh format", {
    brain_verts <- data.frame(
      x = c(1.0, 2.0, 3.0),
      y = c(10.0, 20.0, 30.0),
      z = c(100.0, 200.0, 300.0)
    )
    mock_brain_meshes <- list(
      lh_inflated = list(vertices = brain_verts)
    )

    vb_mesh <- list(
      vb = matrix(
        c(1.0, 10.0, 100.0, 1, 3.0, 30.0, 300.0, 1),
        nrow = 4,
        ncol = 2
      )
    )

    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "inflated"
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = "lh_motor",
        region = "motor"
      )
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(vb_mesh)

    result <- infer_vertices_from_meshes(
      mock_3d,
      surface = "inflated",
      brain_meshes = mock_brain_meshes
    )

    expect_type(result, "list")
    expect_true("lh_motor" %in% names(result))
    expect_identical(sort(result[["lh_motor"]]), c(0L, 2L))
  })

  it("skips NULL mesh entries", {
    brain_verts <- data.frame(
      x = c(1.0, 2.0, 3.0),
      y = c(10.0, 20.0, 30.0),
      z = c(100.0, 200.0, 300.0)
    )
    mock_brain_meshes <- list(
      lh_inflated = list(vertices = brain_verts)
    )

    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "inflated"
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = c("lh_motor", "lh_visual"),
        region = c("motor", "visual")
      )
    )
    region_mesh <- list(
      vertices = data.frame(x = 1.0, y = 10.0, z = 100.0)
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(region_mesh, NULL)

    result <- infer_vertices_from_meshes(
      mock_3d,
      surface = "inflated",
      brain_meshes = mock_brain_meshes
    )

    expect_type(result, "list")
    expect_true("lh_motor" %in% names(result))
    expect_false("lh_visual" %in% names(result))
  })

  it("skips mesh entries with neither vb nor vertices", {
    brain_verts <- data.frame(
      x = c(1.0, 2.0),
      y = c(10.0, 20.0),
      z = c(100.0, 200.0)
    )
    mock_brain_meshes <- list(
      lh_inflated = list(vertices = brain_verts)
    )

    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "inflated"
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = "lh_motor",
        region = "motor"
      )
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(list(something = "else"))

    result <- infer_vertices_from_meshes(
      mock_3d,
      surface = "inflated",
      brain_meshes = mock_brain_meshes
    )

    expect_null(result)
  })

  it("omits labels with no matching vertices", {
    brain_verts <- data.frame(
      x = c(1.0, 2.0, 3.0),
      y = c(10.0, 20.0, 30.0),
      z = c(100.0, 200.0, 300.0)
    )
    mock_brain_meshes <- list(
      lh_inflated = list(vertices = brain_verts)
    )

    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "inflated"
    )
    region_mesh <- list(
      vertices = data.frame(x = 999, y = 999, z = 999)
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = "lh_nowhere",
        region = "nowhere"
      )
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(region_mesh)

    result <- infer_vertices_from_meshes(
      mock_3d,
      surface = "inflated",
      brain_meshes = mock_brain_meshes
    )

    expect_null(result)
  })
})


describe("convert_legacy_brain_atlas palette remap", {
  it("remaps palette when no label keys match core", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = c("lh_frontal", "lh_parietal"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(make_polygon(), make_polygon2())
    )
    core <- data.frame(
      hemi = c("left", "left"),
      region = c("frontal", "parietal"),
      label = c("lh_frontal", "lh_parietal"),
      names = c("frontal", "parietal")
    )
    old_palette <- c(frontal = "#FF0000", parietal = "#00FF00")
    old_atlas <- structure(
      list(
        atlas = "test",
        type = "cortical",
        core = core,
        palette = old_palette,
        data = ggseg_data_cortical(
          geom = sf_geom,
          vertices = data.frame(
            label = c("lh_frontal", "lh_parietal"),
            vertices = I(list(1L:3L, 4L:6L))
          )
        )
      ),
      class = c("cortical_atlas", "ggseg_atlas", "list")
    )

    expect_message(
      result <- convert_legacy_brain_atlas(atlas_2d = old_atlas),
      "Using existing vertex data from 2D atlas"
    )
    expect_true("lh_frontal" %in% names(result$palette))
    expect_true("lh_parietal" %in% names(result$palette))
  })
})


describe("build_atlas_data for tract type", {
  it("builds tract atlas data from meshes", {
    withr::local_options(lifecycle_verbosity = "quiet")
    centerline <- matrix(rnorm(30), ncol = 3)
    tangents <- matrix(rnorm(30), ncol = 3)
    meshes_df <- data.frame(label = "cst_left")
    meshes_df$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5),
      metadata = list(
        centerline = centerline,
        tangents = tangents,
        n_centerline_points = 10
      )
    ))

    result <- build_atlas_data("tract", NULL, NULL, meshes_df)
    expect_s3_class(result, "ggseg_data_tract")
  })
})


describe("extract_meshes_from_rgl", {
  it("extracts meshes from rgl-style vb format", {
    dt <- data.frame(
      label = c("Left-Hippocampus", "Right-Hippocampus")
    )
    m1 <- list(
      vb = matrix(c(1:3, 4:6, 7:9, 10:12), nrow = 4),
      it = matrix(1:3, nrow = 3)
    )
    m2 <- list(
      vb = matrix(c(1:3, 4:6, 7:9, 10:12), nrow = 4),
      it = matrix(1:3, nrow = 3)
    )
    dt$mesh <- list(m1, m2)

    result <- extract_meshes_from_rgl(dt)
    expect_identical(nrow(result), 2L)
    expect_true(all(c("label", "mesh") %in% names(result)))
    expect_s3_class(result$mesh[[1]]$vertices, "data.frame")
    expect_s3_class(result$mesh[[1]]$faces, "data.frame")
  })

  it("handles NULL mesh entries", {
    dt <- data.frame(
      label = c("region1", "region2")
    )
    m1 <- list(
      vb = matrix(c(1:3, 4:6, 7:9, 10:12), nrow = 4),
      it = matrix(1:3, nrow = 3)
    )
    dt$mesh <- list(NULL, m1)

    result <- extract_meshes_from_rgl(dt)
    expect_null(result$mesh[[1]])
    expect_s3_class(result$mesh[[2]]$vertices, "data.frame")
  })
})


describe("try_infer_vertices", {
  it("returns vertices when inference succeeds", {
    brain_verts <- data.frame(
      x = c(1.0, 2.0, 3.0, 4.0, 5.0),
      y = c(10.0, 20.0, 30.0, 40.0, 50.0),
      z = c(100.0, 200.0, 300.0, 400.0, 500.0)
    )
    mock_brain_meshes <- list(
      lh_inflated = list(vertices = brain_verts)
    )

    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "inflated"
    )
    region_mesh <- list(
      vertices = data.frame(
        x = c(1.0, 2.0),
        y = c(10.0, 20.0),
        z = c(100.0, 200.0)
      )
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = "lh_frontal",
        region = "frontal"
      )
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(region_mesh)

    expect_message(
      result <- try_infer_vertices(
        mock_3d,
        surface = "inflated",
        brain_meshes = mock_brain_meshes,
        sf_data = NULL
      ),
      "Inferred vertex indices"
    )
    expect_s3_class(result, "data.frame")
    expect_identical(result$label, "lh_frontal")
    expect_type(result$vertices, "list")
  })

  it("returns NULL when inference fails but sf_data exists", {
    skip_if_not_installed("sf")
    mock_3d <- data.frame(
      atlas = "test",
      hemi = "left",
      surf = "inflated"
    )
    mock_3d$ggseg_3d <- list(
      data.frame(
        label = "lh_frontal",
        region = "frontal"
      )
    )
    mock_3d$ggseg_3d[[1]]$mesh <- list(NULL)

    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )

    expect_warning(
      result <- try_infer_vertices(
        mock_3d,
        "inflated",
        NULL,
        sf_data = sf_geom
      ),
      "Could not infer"
    )
    expect_null(result)
  })
})


describe("build_atlas_data default branch", {
  it("falls through to default for unknown type", {
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)
    result <- build_atlas_data("unknown_type", NULL, vertices, NULL)
    expect_s3_class(result, "ggseg_data_cortical")
  })
})
