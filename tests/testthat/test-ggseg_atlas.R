make_poly <- function(coords) {
  testthat::skip_if_not_installed("sf")
  sf::st_polygon(list(matrix(coords, ncol = 2, byrow = TRUE)))
}

describe("ggseg_atlas class", {
  it("dk is a ggseg_atlas", {
    expect_true(is_ggseg_atlas(dk()))
    expect_s3_class(dk(), "ggseg_atlas")
  })

  it("as_ggseg_atlas round-trips", {
    result <- as_ggseg_atlas(dk())
    expect_s3_class(result, "ggseg_atlas")
  })

  it("as.data.frame returns sf data", {
    skip_if_not_installed("sf")
    df <- as.data.frame(dk())
    expect_s3_class(df, "data.frame")
    expect_true("geometry" %in% names(df))
    expect_true("region" %in% names(df))
    expect_true("hemi" %in% names(df))
    expect_true("view" %in% names(df))
  })

  it("print method works", {
    expect_s3_class(dk()$core, "tbl_df")
    expect_snapshot(print(dk()))
  })

  it("print caps core rows at n", {
    expect_snapshot(print(dk(), n = 3))
    expect_snapshot(print(dk(), n = 6))
  })

  it("atlas_regions returns character vector", {
    regions <- atlas_regions(dk())
    expect_type(regions, "character")
    expect_gt(length(regions), 0)
  })

  it("atlas_labels returns character vector", {
    labels <- atlas_labels(dk())
    expect_type(labels, "character")
    expect_gt(length(labels), 0)
  })

  it("atlas_views returns character vector", {
    views <- atlas_views(dk())
    expect_type(views, "character")
    expect_true(all(c("lateral", "medial") %in% views))
  })

  it("aseg atlas works", {
    skip_if_not_installed("sf")
    expect_true(is_ggseg_atlas(aseg()))
    df <- as.data.frame(aseg())
    expect_s3_class(df, "data.frame")
  })
})


describe("is_*_atlas helpers", {
  it("is_cortical_atlas identifies cortical atlases", {
    expect_true(is_cortical_atlas(dk()))
    expect_false(is_cortical_atlas(aseg()))
    expect_false(is_cortical_atlas(tracula()))
    expect_false(is_cortical_atlas(list()))
  })

  it("is_subcortical_atlas identifies subcortical atlases", {
    expect_true(is_subcortical_atlas(aseg()))
    expect_false(is_subcortical_atlas(dk()))
    expect_false(is_subcortical_atlas(tracula()))
    expect_false(is_subcortical_atlas(NULL))
  })

  it("is_tract_atlas identifies tract atlases", {
    expect_true(is_tract_atlas(tracula()))
    expect_false(is_tract_atlas(dk()))
    expect_false(is_tract_atlas(aseg()))
    expect_false(is_tract_atlas("string"))
  })

  it("is_cerebellar_atlas identifies cerebellar atlases", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "left_I-IV",
      view = "flatmap",
      geometry = sf::st_sfc(
        make_poly(c(0, 0, 1, 0, 1, 1, 0, 0))
      )
    )
    cer <- ggseg_atlas(
      atlas = "suit_lobules",
      type = "cerebellar",
      core = data.frame(
        hemi = "left",
        region = "I-IV",
        label = "left_I-IV",
        display = "lobules I-IV"
      ),
      data = ggseg_data_cerebellar(geom = sf_geom)
    )
    expect_true(is_cerebellar_atlas(cer))
    expect_false(is_cerebellar_atlas(dk()))
    expect_false(is_cerebellar_atlas(aseg()))
    expect_false(is_cerebellar_atlas(NULL))
  })

  it("is_ggseg_atlas matches all subtypes", {
    expect_true(is_ggseg_atlas(dk()))
    expect_true(is_ggseg_atlas(aseg()))
    expect_true(is_ggseg_atlas(tracula()))
  })

  it("rejects objects with faked class", {
    fake <- structure(list(x = 1), class = "ggseg_atlas")
    expect_false(is_ggseg_atlas(fake))

    fake_cortical <- structure(
      list(x = 1),
      class = c("cortical_atlas", "ggseg_atlas")
    )
    expect_false(is_cortical_atlas(fake_cortical))
  })
})


describe("cerebellar atlas construction and data.frame conversion", {
  make_cerebellar_atlas <- function() {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = c("left_I-IV", "vermis_VI", "right_Crus-I"),
      view = "flatmap",
      geometry = sf::st_sfc(
        make_poly(c(0, 0, 1, 0, 1, 1, 0, 0)),
        make_poly(c(2, 0, 3, 0, 3, 1, 2, 0)),
        make_poly(c(4, 0, 5, 0, 5, 1, 4, 0))
      )
    )
    ggseg_atlas(
      atlas = "suit_lobules",
      type = "cerebellar",
      core = data.frame(
        hemi = c("left", "midline", "right"),
        region = c("I-IV", "VI", "Crus-I"),
        label = c("left_I-IV", "vermis_VI", "right_Crus-I"),
        display = c("lobules I-IV", "vermis VI", "Crus I")
      ),
      data = ggseg_data_cerebellar(geom = sf_geom)
    )
  }

  it("creates a valid cerebellar atlas", {
    atlas <- make_cerebellar_atlas()
    expect_s3_class(atlas, "cerebellar_atlas")
    expect_s3_class(atlas, "ggseg_atlas")
    expect_identical(atlas$type, "cerebellar")
    expect_identical(nrow(atlas$core), 3L)
  })

  it("as.data.frame preserves the midline hemisphere and its label", {
    atlas <- make_cerebellar_atlas()
    df <- as.data.frame(atlas)
    expect_true("midline" %in% df$hemi)
    expect_true("left" %in% df$hemi)
    expect_true("right" %in% df$hemi)
    expect_identical(df$label[df$hemi == "midline"], "vermis_VI")
    expect_identical(nrow(df), 3L)
  })

  it("as.data.frame does not filter NA hemi for cerebellar", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "midline_dentate",
      view = "flatmap",
      geometry = sf::st_sfc(
        make_poly(c(0, 0, 1, 0, 1, 1, 0, 0))
      )
    )
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cerebellar",
      core = data.frame(
        hemi = NA_character_,
        region = "dentate",
        label = "midline_dentate",
        display = "dentate nucleus"
      ),
      data = ggseg_data_cerebellar(geom = sf_geom)
    )
    df <- as.data.frame(atlas)
    expect_identical(nrow(df), 1L)
    expect_true(is.na(df$hemi[1]))
  })

  it("type mismatch errors correctly", {
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)
    expect_error(
      ggseg_atlas(
        atlas = "test",
        type = "cerebellar",
        core = data.frame(
          hemi = "left",
          region = "frontal",
          label = "lh_frontal",
          display = "frontal"
        ),
        data = ggseg_data_cortical(vertices = vertices)
      ),
      "requires.*ggseg_data_cerebellar"
    )
  })
})


describe("ggseg_atlas constructor validation", {
  it("errors when atlas is not a single string", {
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
        atlas = c("a", "b"),
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      "single character string"
    )
  })

  it("errors when core missing required columns", {
    core <- data.frame(hemi = "left", name = "frontal")
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    expect_error(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      "must contain columns"
    )
  })

  it("errors when data is not ggseg_atlas_data", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    expect_error(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = list(sf = NULL)
      ),
      "ggseg_atlas_data"
    )
  })

  it("errors when data type mismatches atlas type", {
    core <- data.frame(
      hemi = NA,
      region = "hippocampus",
      label = "hippocampus",
      display = "hippocampus"
    )
    meshes <- data.frame(label = "hippocampus")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))
    expect_error(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_subcortical(meshes = meshes)
      ),
      "requires.*ggseg_data_cortical"
    )
  })
})


describe("deprecated wrappers", {
  it("brain_atlas() warns about deprecation", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    lifecycle::expect_deprecated(
      brain_atlas(
        atlas = "test",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      )
    )
  })

  it("is_brain_atlas() warns about deprecation", {
    lifecycle::expect_deprecated(is_brain_atlas(dk()))
  })
})


describe("as.data.frame.ggseg_atlas", {
  it("infers hemi from label prefixes", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = c("lh_frontal", "rh_parietal"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(make_polygon(), make_polygon2())
    )
    core <- data.frame(
      region = c("frontal", "parietal"),
      label = c("lh_frontal", "rh_parietal"),
      display = c("frontal", "parietal")
    )
    vertices <- data.frame(label = c("lh_frontal", "rh_parietal"))
    vertices$vertices <- list(1L:3L, 4L:6L)

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(geom = sf_geom, vertices = vertices)
    )

    df <- as.data.frame(atlas)
    expect_true("hemi" %in% names(df))
    expect_true(all(df$hemi %in% c("left", "right")))
  })

  it("places context geometry last in row order", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = c("lh_medialwall", "lh_frontal"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(make_polygon(), make_polygon2())
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(geom = sf_geom, vertices = vertices)
    )

    df <- as.data.frame(atlas)
    last_label <- df$label[nrow(df)]
    expect_identical(last_label, "lh_frontal")
  })

  it("errors when atlas has no 2D geometry", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )
    expect_error(as.data.frame(atlas), "no 2D geometry")
  })
})


describe("as.list.ggseg_atlas", {
  it("returns the five atlas components", {
    out <- as.list(dk())
    expect_type(out, "list")
    expect_identical(
      sort(names(out)),
      sort(c("atlas", "type", "palette", "core", "data"))
    )
    expect_identical(out$atlas, dk()$atlas)
    expect_identical(out$type, "cortical")
  })
})


describe("plot.ggseg_atlas", {
  it("plots a cortical sf atlas without error", {
    local_null_pdf()
    expect_no_error(plot(dk()))
  })

  it("plots a subcortical atlas without error", {
    local_null_pdf()
    expect_no_error(plot(aseg()))
  })

  it("plots a tract atlas without error", {
    local_null_pdf()
    expect_no_error(plot(tracula()))
  })

  it("plots a cerebellar atlas without error", {
    local_null_pdf()
    expect_no_error(plot(suit()))
  })

  it("draws polygons with holes via polypath", {
    skip_if_not_installed("sf")
    theta <- seq(0, 2 * pi, length.out = 60)
    outer <- cbind(10 * cos(theta), 10 * sin(theta))
    outer[60, ] <- outer[1, ]
    inner <- cbind(3 * cos(rev(theta)), 3 * sin(rev(theta)))
    inner[60, ] <- inner[1, ]
    donut <- sf::st_polygon(list(outer, inner))
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(donut)
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(
        geom = sf_geom,
        vertices = data.frame(label = "lh_frontal", vertices = I(list(1L:3L)))
      )
    )
    local_null_pdf()
    expect_no_error(plot(atlas))
  })

  it("forwards styling overrides through dots", {
    local_null_pdf()
    expect_no_error(plot(dk(), border = "black", lwd = 1))
  })

  it("plots an atlas with no palette using generated colours", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = c("lh_frontal", "rh_parietal"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(
        make_poly(c(0, 0, 1, 0, 1, 1, 0, 0)),
        make_poly(c(5, 0, 6, 0, 6, 1, 5, 0))
      )
    )
    core <- data.frame(
      hemi = c("left", "right"),
      region = c("frontal", "parietal"),
      label = c("lh_frontal", "rh_parietal"),
      display = c("frontal", "parietal")
    )
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "subcortical",
      core = core,
      data = ggseg_data_subcortical(geom = sf_geom)
    )
    expect_null(atlas$palette)
    local_null_pdf()
    expect_no_error(plot(atlas))
  })
})


describe("print.ggseg_atlas rendering branches", {
  it("prints a tract atlas (centerlines)", {
    expect_snapshot(print(tracula()))
  })

  it("prints a subcortical atlas (meshes)", {
    expect_snapshot(print(aseg()))
  })

  it("prints a cortical atlas (vertices)", {
    expect_snapshot(print(dk()))
  })

  it("prints an atlas with no 3D geometry as none", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_poly(c(0, 0, 1, 0, 1, 1, 0, 0)))
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cerebellar",
      core = core,
      data = ggseg_data_cerebellar(geom = sf_geom)
    )
    expect_snapshot(print(atlas))
  })

  it("prints a polygon atlas summary with views", {
    poly_atlas <- as_polygon_atlas(dk())
    expect_snapshot(print(poly_atlas))
  })
})


describe("as_sf_for_data_frame empty geometry", {
  it("errors when raw sf data has zero rows", {
    skip_if_not_installed("sf")
    empty_sf <- sf::st_sf(
      label = character(0),
      view = character(0),
      geometry = sf::st_sfc()
    )
    atlas <- structure(
      list(
        atlas = "test",
        type = "subcortical",
        palette = NULL,
        core = NULL,
        data = empty_sf
      ),
      class = c("subcortical_atlas", "ggseg_atlas", "list")
    )
    expect_error(as.data.frame(atlas), "no 2D geometry")
  })
})


describe("is_ggseg3d_atlas", {
  it("returns TRUE for data.frame with ggseg_3d column", {
    x <- data.frame(ggseg_3d = 1)
    expect_true(is_ggseg3d_atlas(x))
  })

  it("returns FALSE for data.frame without ggseg_3d column", {
    x <- data.frame(a = 1)
    expect_false(is_ggseg3d_atlas(x))
  })

  it("returns FALSE for non-data.frame", {
    expect_false(is_ggseg3d_atlas(list(ggseg_3d = 1)))
  })
})


describe("ggseg_atlas constructor validation", {
  it("errors on vector atlas name", {
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
        atlas = c("a", "b"),
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      "single character string"
    )
  })
})


describe("as.data.frame.ggseg_atlas edge cases", {
  it("maps palette colours to result", {
    skip_if_not_installed("sf")
    df <- as.data.frame(dk())
    expect_true("colour" %in% names(df))
    expect_false(all(is.na(df$colour)))
  })

  it("handles sf with hemi column via core merge", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = c("lh_frontal", NA_character_),
      view = c("lateral", "lateral"),
      hemi = c("left", NA_character_),
      geometry = sf::st_sfc(make_polygon(), make_polygon2())
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(
        geom = sf_geom,
        vertices = data.frame(label = "lh_frontal", vertices = I(list(1L:3L)))
      )
    )
    df <- as.data.frame(atlas)
    expect_true("hemi" %in% names(df))
    expect_identical(df$hemi[df$label == "lh_frontal"], "left")
  })

  it("backfills sf hemi when core hemi is NA", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = c("lh_frontal", "context"),
      view = c("lateral", "lateral"),
      hemi = c("left", "bg"),
      geometry = sf::st_sfc(make_polygon(), make_polygon2())
    )
    core <- data.frame(
      hemi = NA_character_,
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "subcortical",
      core = core,
      data = ggseg_data_subcortical(geom = sf_geom)
    )
    df <- as.data.frame(atlas)
    frontal_row <- df[df$label == "lh_frontal", ]
    expect_identical(frontal_row$hemi, "left")
  })

  it("removes rows with missing hemi for cortical atlas", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = c("lh_frontal", "no_prefix"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(make_polygon(), make_polygon2())
    )
    core <- data.frame(
      hemi = c("left", NA_character_),
      region = c("frontal", "unknown"),
      label = c("lh_frontal", "no_prefix"),
      display = c("frontal", "unknown")
    )
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(
        geom = sf_geom,
        vertices = data.frame(
          label = c("lh_frontal", "no_prefix"),
          vertices = I(list(1L:3L, 4L:6L))
        )
      )
    )
    df <- as.data.frame(atlas)
    expect_false("no_prefix" %in% df$label)
  })
})


describe("ggseg_atlas constructor: non-data.frame core", {
  it("errors when core is not a data.frame", {
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)
    expect_error(
      ggseg_atlas(
        atlas = "test",
        type = "cortical",
        core = list(hemi = "left", region = "frontal", label = "lh_frontal"),
        data = ggseg_data_cortical(vertices = vertices)
      ),
      "must be a data.frame"
    )
  })
})


describe("as.data.frame with legacy data structure", {
  it("handles data as raw sf (not ggseg_atlas_data)", {
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
      display = "frontal"
    )
    atlas <- structure(
      list(
        atlas = "test",
        type = "cortical",
        palette = c(lh_frontal = "#FF0000"),
        core = core,
        data = sf_geom
      ),
      class = c("cortical_atlas", "ggseg_atlas", "list")
    )
    df <- as.data.frame(atlas)
    expect_s3_class(df, "data.frame")
    expect_true("lh_frontal" %in% df$label)
  })

  it("handles NULL core", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    atlas <- structure(
      list(
        atlas = "test",
        type = "subcortical",
        palette = NULL,
        core = NULL,
        data = sf_geom
      ),
      class = c("subcortical_atlas", "ggseg_atlas", "list")
    )
    df <- as.data.frame(atlas)
    expect_s3_class(df, "data.frame")
    expect_true("lh_frontal" %in% df$label)
  })
})
