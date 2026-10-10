describe("migrate_atlas_files()", {
  it("aborts when the target directory does not exist", {
    expect_error(
      migrate_atlas_files(file.path(tempdir(), "does-not-exist-xyz")),
      "does not exist"
    )
  })

  it("warns and returns nothing when the directory has no .rda files", {
    dir <- withr::local_tempdir()
    expect_warning(out <- migrate_atlas_files(dir), "No")
    expect_identical(out, character())
  })

  it("rewrites a legacy sf atlas to brain_polygons in place", {
    dir <- withr::local_tempdir()
    atlas <- dk_sf_atlas()
    save(atlas, file = file.path(dir, "atlas.rda"))

    migrated <- migrate_atlas_files(dir, quiet = TRUE)
    expect_length(migrated, 1)

    env <- new.env()
    load(file.path(dir, "atlas.rda"), envir = env)
    expect_s3_class(atlas_geom(env$atlas), "brain_polygons")
    expect_null(env$atlas$data$sf)
  })

  it("stores geometry as sf when keep_sf = TRUE", {
    dir <- withr::local_tempdir()
    atlas <- as_polygon_atlas(dk())
    save(atlas, file = file.path(dir, "atlas.rda"))

    migrate_atlas_files(dir, keep_sf = TRUE, quiet = TRUE)

    env <- new.env()
    load(file.path(dir, "atlas.rda"), envir = env)
    expect_s3_class(atlas_geom(env$atlas), "sf")
  })

  it("skips files that are already in the target representation", {
    dir <- withr::local_tempdir()
    atlas <- as_polygon_atlas(dk())
    save(atlas, file = file.path(dir, "atlas.rda"))

    expect_identical(migrate_atlas_files(dir, quiet = TRUE), character())
  })

  it("skips sf atlases when keep_sf = TRUE", {
    dir <- withr::local_tempdir()
    atlas <- dk_sf_atlas()
    save(atlas, file = file.path(dir, "atlas.rda"))

    expect_identical(
      migrate_atlas_files(dir, keep_sf = TRUE, quiet = TRUE),
      character()
    )
  })

  it("reports migrated files when quiet = FALSE", {
    dir <- withr::local_tempdir()
    atlas <- dk_sf_atlas()
    save(atlas, file = file.path(dir, "atlas.rda"))

    expect_message(migrate_atlas_files(dir, quiet = FALSE), "Migrated")
  })

  it("reports skipped files when quiet = FALSE", {
    dir <- withr::local_tempdir()
    x <- 1:3
    save(x, file = file.path(dir, "notatlas.rda"))

    expect_message(
      migrate_atlas_files(dir, quiet = FALSE),
      "nothing to migrate"
    )
  })
})

describe("migrate_atlas_object()", {
  it("returns NULL for an atlas without 2D geometry", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    atlas <- ggseg_atlas(
      atlas = "a",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    expect_null(migrate_atlas_object(atlas, keep_sf = FALSE))
  })
})


describe("migrate_atlas_files() column-loss guard", {
  it("aborts when a conversion to polygons would lose columns", {
    skip_if_not_installed("sf")
    dir <- withr::local_tempdir()
    atlas <- dk_sf_atlas()
    geom <- as.data.frame(atlas_geom(atlas))
    geom$group <- 1L
    atlas$data$geom <- sf::st_as_sf(geom)
    save(atlas, file = file.path(dir, "atlas.rda"))

    expect_error(
      migrate_atlas_files(dir, quiet = TRUE),
      "would lose column"
    )
  })

  it("leaves the file untouched when it aborts", {
    skip_if_not_installed("sf")
    dir <- withr::local_tempdir()
    atlas <- dk_sf_atlas()
    geom <- as.data.frame(atlas_geom(atlas))
    geom$group <- 1L
    atlas$data$geom <- sf::st_as_sf(geom)
    f <- file.path(dir, "atlas.rda")
    save(atlas, file = f)
    before <- tools::md5sum(f)

    expect_error(migrate_atlas_files(dir, quiet = TRUE))
    expect_identical(tools::md5sum(f), before)
  })

  it("migrates with a warning when force = TRUE", {
    skip_if_not_installed("sf")
    dir <- withr::local_tempdir()
    atlas <- dk_sf_atlas()
    geom <- as.data.frame(atlas_geom(atlas))
    geom$group <- 1L
    atlas$data$geom <- sf::st_as_sf(geom)
    save(atlas, file = file.path(dir, "atlas.rda"))

    expect_warning(
      migrated <- migrate_atlas_files(dir, quiet = TRUE, force = TRUE),
      "would lose column"
    )
    expect_length(migrated, 1)

    env <- new.env()
    load(file.path(dir, "atlas.rda"), envir = env)
    expect_s3_class(atlas_geom(env$atlas), "brain_polygons")
  })

  it("aborts when a conversion to sf would collapse a varying column", {
    dir <- withr::local_tempdir()
    atlas <- as_polygon_atlas(dk())
    geom <- atlas_geom(atlas)
    geom$geometry[[1]]$myannot <- c("a", rep("b", nrow(geom$geometry[[1]]) - 1))
    atlas$data$geom <- geom
    save(atlas, file = file.path(dir, "atlas.rda"))

    expect_error(
      migrate_atlas_files(dir, keep_sf = TRUE, quiet = TRUE),
      "myannot"
    )
  })

  it("carries a constant extra column into sf without complaint", {
    dir <- withr::local_tempdir()
    atlas <- as_polygon_atlas(dk())
    geom <- atlas_geom(atlas)
    geom$geometry <- lapply(geom$geometry, function(g) {
      g$myannot <- "a"
      g
    })
    atlas$data$geom <- geom
    save(atlas, file = file.path(dir, "atlas.rda"))

    expect_no_warning(
      migrate_atlas_files(dir, keep_sf = TRUE, quiet = TRUE)
    )

    env <- new.env()
    load(file.path(dir, "atlas.rda"), envir = env)
    expect_true("myannot" %in% names(atlas_geom(env$atlas)))
  })
})
