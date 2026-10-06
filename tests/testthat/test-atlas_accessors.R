describe("atlas_palette", {
  it("returns the palette from an atlas object", {
    pal <- atlas_palette(dk())
    expect_type(pal, "character")
    expect_gt(length(pal), 0)
    expect_true(all(grepl("^#", pal)))
  })

  it("errors when given an atlas name string instead of an object", {
    expect_error(atlas_palette("dk"), "must be a.*ggseg_atlas")
  })

  it("errors when the object is not an atlas", {
    expect_error(atlas_palette(data.frame(x = 1)), "must be a.*ggseg_atlas")
  })
})

describe("atlas_geom", {
  it("errors for non-ggseg_atlas input", {
    expect_error(atlas_geom(list()), "must be a")
  })
})

describe("atlas_geometry_type", {
  it("returns 'sf' for an sf atlas", {
    expect_identical(atlas_geometry_type(dk_sf_atlas()), "sf")
  })

  it("returns 'polygon' for a polygon atlas", {
    expect_identical(atlas_geometry_type(dk()), "polygon")
  })

  it("errors when the atlas has no recognised 2D geometry", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      names = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    atlas <- ggseg_atlas(
      atlas = "a",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    expect_error(atlas_geometry_type(atlas), "no recognised 2D geometry")
  })
})

describe("atlas_polygons", {
  it("errors for non-ggseg_atlas input", {
    expect_error(atlas_polygons(list()), "must be a")
  })
})

describe("atlas_sf", {
  it("returns sf data from atlas", {
    sf_data <- atlas_sf(dk())
    expect_s3_class(sf_data, "sf")
  })

  it("has ggseg_sf as first class", {
    sf_data <- atlas_sf(dk())
    expect_identical(class(sf_data)[1], "ggseg_sf")
    expect_s3_class(sf_data, "sf")
  })

  it("prints without error and keeps its classes", {
    sf_data <- sf::st_sf(
      label = c("lh_a", "lh_b"),
      view = c("lateral", "medial"),
      geometry = sf::st_sfc(make_polygon(), make_polygon2())
    )
    class(sf_data) <- c("ggseg_sf", class(sf_data))
    expect_s3_class(sf_data, "ggseg_sf")
    expect_s3_class(sf_data, "sf")
    expect_snapshot(print(sf_data))
  })

  it("errors when atlas is not brain_atlas", {
    expect_error(atlas_sf(list()), "must be a")
  })

  it("errors when atlas has no 2D geometry", {
    atlas <- dk()
    atlas$data$geom <- NULL
    atlas$data$sf <- NULL
    expect_error(atlas_sf(atlas), "does not contain 2D geometry")
  })

  it("returns sf joined with core and palette", {
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
      names = c("frontal", "frontal"),
      names = c("frontal", "frontal")
    )
    palette <- c(lh_frontal = "#FF0000", rh_frontal = "#00FF00")

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      palette = palette,
      core = core,
      data = ggseg_data_cortical(geom = sf_geom)
    )

    result <- atlas_sf(atlas)

    expect_s3_class(result, "sf")
    expect_identical(nrow(result), 2L)
    expect_true("hemi" %in% names(result))
    expect_true("region" %in% names(result))
    expect_true("colour" %in% names(result))
  })

  it("removes hemi/region from sf before merge", {
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      hemi = "left",
      region = "frontal",
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

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(geom = sf_geom)
    )

    result <- atlas_sf(atlas)

    expect_true("hemi" %in% names(result))
    expect_true("region" %in% names(result))
  })

  it("draws contextual rows before core rows (not re-sorted by label)", {
    sf_geom <- sf::st_sf(
      label = c("lh_zzz", "lh_aaa", "lh_ctx"),
      view = "lateral",
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2(),
        make_polygon(c(4, 0, 5, 0, 5, 1, 4, 0))
      )
    )
    core <- data.frame(
      hemi = "left",
      region = c("zzz", "aaa"),
      label = c("lh_zzz", "lh_aaa"),
      names = c("zzz", "aaa")
    )
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(geom = sf_geom)
    )

    # lh_zzz demoted to context: it plus the pipeline outline lh_ctx must lead
    # the remaining core region lh_aaa so focus regions draw on top.
    demoted <- atlas_region_contextual(atlas, "zzz", match_on = "region")
    result <- atlas_sf(demoted)

    is_core <- result$label %in% demoted$core$label
    expect_lt(max(which(!is_core)), min(which(is_core)))
    # alphabetical order (lh_aaa, lh_ctx, lh_zzz) would put a core row first;
    # guard against a regression to the merge() default sort.
    expect_true(is.unsorted(result$label))
  })
})


describe("atlas_vertices", {
  it("has ggseg_vertices as first class", {
    result <- atlas_vertices(dk())
    expect_identical(class(result)[1], "ggseg_vertices")
    expect_s3_class(result, "tbl_df")
  })

  it("prints without error and keeps its classes", {
    result <- atlas_vertices(dk())
    expect_s3_class(result, "ggseg_vertices")
    expect_s3_class(result, "tbl_df")
    expect_snapshot(print(result))
  })

  it("returns vertices joined with core and palette", {
    core <- data.frame(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      names = c("frontal", "frontal"),
      names = c("frontal", "frontal")
    )
    vertices <- data.frame(label = c("lh_frontal", "rh_frontal"))
    vertices$vertices <- list(1L:3L, 4L:6L)
    palette <- c(lh_frontal = "#FF0000", rh_frontal = "#00FF00")

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      palette = palette,
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    result <- atlas_vertices(atlas)

    expect_identical(nrow(result), 2L)
    expect_true("hemi" %in% names(result))
    expect_true("region" %in% names(result))
    expect_true("colour" %in% names(result))
    expect_identical(result$colour, c("#FF0000", "#00FF00"))
  })

  it("errors for atlas without vertices", {
    meshes <- data.frame(label = "hippocampus")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))
    core <- data.frame(
      hemi = NA,
      region = "hippocampus",
      label = "hippocampus",
      names = "hippocampus"
    )

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "subcortical",
      core = core,
      data = ggseg_data_subcortical(meshes = meshes)
    )

    expect_error(atlas_vertices(atlas), "does not contain vertices")
  })

  it("returns vertices without colour column when no palette", {
    core <- data.frame(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      names = c("frontal", "frontal"),
      names = c("frontal", "frontal")
    )
    vertices <- data.frame(label = c("lh_frontal", "rh_frontal"))
    vertices$vertices <- list(1L:3L, 4L:6L)

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    result <- atlas_vertices(atlas)

    expect_false("colour" %in% names(result))
  })

  it("errors for non-ggseg_atlas input", {
    expect_error(atlas_vertices(data.frame()), "must be a.*ggseg_atlas")
  })
})


describe("atlas_centerlines", {
  make_tract_atlas <- function() {
    centerlines <- data.frame(label = c("lh_af", "rh_af"))
    centerlines$points <- list(
      cbind(1:5, 1:5, 1:5),
      cbind(6:10, 1:5, 1:5)
    )
    centerlines$tangents <- list(
      cbind(rep(1, 5), 0, 0),
      cbind(rep(1, 5), 0, 0)
    )

    ggseg_atlas(
      atlas = "test",
      type = "tract",
      palette = c(lh_af = "#FF0000", rh_af = "#00FF00"),
      core = data.frame(
        hemi = c("left", "right"),
        region = c("af", "af"),
        label = c("lh_af", "rh_af"),
        names = c("af", "af")
      ),
      data = ggseg_data_tract(centerlines = centerlines)
    )
  }

  it("returns centerlines joined with core and palette", {
    result <- atlas_centerlines(make_tract_atlas())

    expect_identical(nrow(result), 2L)
    expect_identical(result$region, c("af", "af"))
    expect_identical(result$colour, c("#FF0000", "#00FF00"))
    expect_identical(dim(result$points[[1]]), c(5L, 3L))
  })

  it("errors on an atlas that has no centerlines", {
    expect_error(
      atlas_centerlines(aseg()),
      "does not contain tract centerlines"
    )
  })

  it("errors on a non-atlas", {
    expect_error(atlas_centerlines(data.frame(a = 1)), "must be a")
  })
})


describe("atlas_meshes", {
  it("has ggseg_meshes as first class", {
    result <- atlas_meshes(aseg())
    expect_identical(class(result)[1], "ggseg_meshes")
    expect_s3_class(result, "data.frame")
  })

  it("prints without error and keeps its classes", {
    result <- atlas_meshes(aseg())
    expect_s3_class(result, "ggseg_meshes")
    expect_s3_class(result, "tbl_df")
    expect_snapshot(print(result))
  })

  it("returns meshes joined with core and palette", {
    meshes <- data.frame(label = "hippocampus")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))
    core <- data.frame(
      hemi = NA,
      region = "hippocampus",
      label = "hippocampus",
      names = "hippocampus"
    )
    palette <- c(hippocampus = "#FF0000")

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "subcortical",
      palette = palette,
      core = core,
      data = ggseg_data_subcortical(meshes = meshes)
    )

    result <- atlas_meshes(atlas)

    expect_identical(nrow(result), 1L)
    expect_true("colour" %in% names(result))
    expect_identical(result$colour, "#FF0000")
  })

  it("errors for atlas without meshes", {
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

    expect_error(atlas_meshes(atlas), "does not contain meshes")
  })

  it("returns meshes without colour column when no palette", {
    meshes <- data.frame(label = "hippocampus")
    meshes$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))
    core <- data.frame(
      hemi = NA,
      region = "hippocampus",
      label = "hippocampus",
      names = "hippocampus"
    )

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "subcortical",
      core = core,
      data = ggseg_data_subcortical(meshes = meshes)
    )

    result <- atlas_meshes(atlas)

    expect_false("colour" %in% names(result))
  })

  it("errors for non-ggseg_atlas input", {
    expect_error(atlas_meshes(data.frame()), "must be a.*ggseg_atlas")
  })
})
