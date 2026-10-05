describe("as_ggseg_atlas", {
  it("converts list to ggseg_atlas", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    lst <- as.list(atlas)
    result <- as_ggseg_atlas(lst)

    expect_s3_class(result, "ggseg_atlas")
    expect_identical(result$atlas, "test")
  })

  it("errors for unsupported object types", {
    expect_error(as_ggseg_atlas(~age), "Cannot convert.*to.*ggseg_atlas")
  })

  it("errors for empty list", {
    expect_error(as_ggseg_atlas(list()), "Cannot convert list")
  })
})


describe("as_ggseg_atlas.ggseg_atlas", {
  it("converts legacy structure with separate sf/vertices fields", {
    sf_geom <- sf::st_sf(
      label = c("lh_frontal", "rh_frontal"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2()
      )
    )
    core <- data.frame(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      names = c("frontal", "frontal")
    )

    legacy <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        palette = NULL,
        core = core,
        sf = sf_geom,
        vertices = NULL
      ),
      class = "ggseg_atlas"
    )

    result <- as_ggseg_atlas(legacy)

    expect_s3_class(result, "ggseg_atlas")
    expect_s3_class(result$data, "ggseg_atlas_data")
    expect_identical(result$atlas, "legacy")
  })

  it("returns unchanged if already has proper data structure", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    result <- as_ggseg_atlas(atlas)
    expect_identical(result, atlas)
  })

  it("errors for unrecognized ggseg_atlas structure", {
    bad_atlas <- structure(
      list(atlas = "bad", type = "cortical"),
      class = "ggseg_atlas"
    )

    expect_error(as_ggseg_atlas(bad_atlas), "unrecognized structure")
  })
})


describe("as_ggseg_atlas.brain_atlas (legacy auto-conversion)", {
  it("auto-converts old brain_atlas with proper data to ggseg_atlas", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    old_atlas <- structure(
      list(
        atlas = "old",
        type = "cortical",
        palette = NULL,
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      class = c("cortical_atlas", "brain_atlas", "list")
    )

    lifecycle::expect_deprecated(
      result <- as_ggseg_atlas(old_atlas)
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_identical(result$atlas, "old")
  })

  it("auto-converts old brain_atlas with sf-in-data to ggseg_atlas", {
    sf_geom <- sf::st_sf(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      names = c("frontal", "frontal"),
      view = c("lateral", "lateral"),
      colour = c("#FF0000", "#00FF00"),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2()
      )
    )

    old_atlas <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        data = sf_geom
      ),
      class = "brain_atlas"
    )

    lifecycle::expect_deprecated(
      result <- as_ggseg_atlas(old_atlas)
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_false(is.null(result$core))
    expect_s3_class(result$data, "ggseg_atlas_data")
  })
})


describe("as_ggseg_atlas.list", {
  it("converts legacy list with separate sf field", {
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(
        make_polygon()
      )
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )

    legacy_list <- list(
      atlas = "legacy",
      type = "cortical",
      palette = NULL,
      core = core,
      sf = sf_geom,
      vertices = NULL
    )

    result <- as_ggseg_atlas(legacy_list)

    expect_s3_class(result, "ggseg_atlas")
    expect_s3_class(result$data, "ggseg_atlas_data")
  })
})


describe("convert_legacy_brain_data", {
  it("errors for non-brain_atlas input", {
    expect_error(
      convert_legacy_brain_data(list()),
      "must be a.*brain_atlas.*ggseg_atlas"
    )
  })

  it("returns atlas unchanged if already has core", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    result <- convert_legacy_brain_data(atlas)
    expect_s3_class(result, "ggseg_atlas")
  })

  it("converts legacy atlas without core", {
    sf_geom <- sf::st_sf(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      names = c("frontal", "frontal"),
      view = c("lateral", "lateral"),
      colour = c("#FF0000", "#00FF00"),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2()
      )
    )

    legacy <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        data = sf_geom
      ),
      class = "brain_atlas"
    )

    result <- convert_legacy_brain_data(legacy)

    expect_s3_class(result, "ggseg_atlas")
    expect_false(is.null(result$core))
    expect_s3_class(result$data, "ggseg_atlas_data")
    expect_identical(result$atlas, "legacy")
  })

  it("renames side column to view", {
    sf_geom <- sf::st_sf(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      names = c("frontal", "frontal"),
      side = c("lateral", "lateral"),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2()
      )
    )

    legacy <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        data = sf_geom
      ),
      class = "brain_atlas"
    )

    result <- convert_legacy_brain_data(legacy)

    expect_s3_class(result, "ggseg_atlas")
    expect_true("view" %in% names(atlas_geom(result)))
  })

  it("handles legacy atlas without colour column", {
    sf_geom <- sf::st_sf(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(
        make_polygon()
      )
    )

    legacy <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        data = sf_geom
      ),
      class = "brain_atlas"
    )

    result <- convert_legacy_brain_data(legacy)

    expect_s3_class(result, "ggseg_atlas")
    expect_null(result$palette)
  })
})


describe("as_brain_atlas (deprecated)", {
  it("warns and delegates to as_ggseg_atlas", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )
    lifecycle::expect_deprecated(
      result <- as_brain_atlas(atlas)
    )
    expect_s3_class(result, "ggseg_atlas")
  })
})


describe("as_ggseg_atlas.brain_atlas legacy paths", {
  it("converts brain_atlas with core and data.frame data", {
    sf_geom <- sf::st_sf(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    old_atlas <- structure(
      list(
        atlas = "old",
        type = "cortical",
        core = data.frame(
          hemi = "left",
          region = "frontal",
          label = "lh_frontal",
          names = "frontal"
        ),
        data = sf_geom
      ),
      class = "brain_atlas"
    )
    lifecycle::expect_deprecated(
      result <- as_ggseg_atlas(old_atlas)
    )
    expect_s3_class(result, "ggseg_atlas")
  })

  it("converts brain_atlas with separate sf field", {
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    old_atlas <- structure(
      list(
        atlas = "old",
        type = "cortical",
        core = data.frame(
          hemi = "left",
          region = "frontal",
          label = "lh_frontal",
          names = "frontal"
        ),
        sf = sf_geom,
        vertices = NULL,
        meshes = NULL
      ),
      class = "brain_atlas"
    )
    lifecycle::expect_deprecated(
      result <- as_ggseg_atlas(old_atlas)
    )
    expect_s3_class(result, "ggseg_atlas")
    expect_s3_class(result$data, "ggseg_atlas_data")
  })

  it("errors for unrecognized brain_atlas structure", {
    old_atlas <- structure(
      list(atlas = "bad", type = "cortical"),
      class = "brain_atlas"
    )
    lifecycle::expect_deprecated(
      expect_error(as_ggseg_atlas(old_atlas), "unrecognized structure")
    )
  })
})


describe("as_ggseg_atlas.ggseg3d_atlas", {
  it("converts ggseg3d atlas with deprecation warning", {
    mock_3d <- data.frame(
      atlas = "test_3d",
      hemi = "left",
      surf = "inflated"
    )
    region_data <- data.frame(
      label = "lh_frontal",
      region = "frontal",
      colour = "#FF0000"
    )
    region_data$mesh <- list(NULL)
    region_data$vertices <- list(1L:3L)
    mock_3d$ggseg_3d <- list(region_data)
    class(mock_3d) <- c("ggseg3d_atlas", "data.frame")

    expect_message(
      lifecycle::expect_deprecated(
        result <- as_ggseg_atlas(mock_3d)
      ),
      "Using existing vertex indices from 3D atlas"
    )
    expect_s3_class(result, "ggseg_atlas")
  })
})
