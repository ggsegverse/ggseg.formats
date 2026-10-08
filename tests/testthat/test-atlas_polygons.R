describe("sf_to_polygons()", {
  it("returns one row per label with a nested geometry list-column", {
    skip_if_not_installed("sf")
    polys <- sf_to_polygons(dk_sf_geom())

    expect_s3_class(polys, "brain_polygons")
    expect_s3_class(polys, "tbl_df")
    expect_identical(nrow(polys), length(unique(dk_sf_geom()$label)))
    expect_named(polys, c("label", "geometry"))
    expect_type(polys$geometry, "list")
  })

  it("nested geometry data.frams carry view, x, y, group, subgroup", {
    skip_if_not_installed("sf")
    polys <- sf_to_polygons(dk_sf_geom())
    inner <- polys$geometry[[1]]
    expect_s3_class(inner, "tbl_df")
    expect_named(inner, c("view", "x", "y", "group", "subgroup"))
    expect_type(inner$group, "integer")
    expect_type(inner$subgroup, "integer")
  })

  it("preserves coordinate counts across the conversion", {
    skip_if_not_installed("sf")
    sf0 <- dk_sf_geom()
    polys <- sf_to_polygons(sf0)
    n_sf <- sum(vapply(
      sf0$geometry,
      function(g) {
        nrow(sf::st_coordinates(g))
      },
      integer(1)
    ))
    n_poly <- sum(vapply(polys$geometry, nrow, integer(1)))
    expect_identical(n_sf, n_poly)
  })

  it("errors on non-sf input", {
    skip_if_not_installed("sf")
    expect_error(sf_to_polygons(data.frame(a = 1)), "must inherit from class")
  })
})

describe("print.brain_polygons()", {
  it("prints labels, views and total points for a populated object", {
    p <- atlas_polygons(as_polygon_atlas(dk()))
    expect_snapshot(print(p))
  })

  it("prints without error for a zero-row object", {
    p <- structure(
      as_tbl(data.frame(
        label = character(0),
        geometry = I(list())
      )),
      class = c("brain_polygons", "tbl_df", "tbl", "data.frame")
    )
    expect_snapshot(print(p))
  })
})

describe("sf_to_polygons() column validation", {
  it("errors when a required column is missing", {
    skip_if_not_installed("sf")
    sf_bad <- sf::st_sf(
      label = "lh_x",
      geometry = sf::st_sfc(make_polygon())
    )
    expect_error(sf_to_polygons(sf_bad), "missing columns")
  })
})

describe("validate_polygons() geometry column", {
  it("errors when the geometry column is absent", {
    bad <- data.frame(label = "lh_x")
    expect_error(validate_polygons(bad), "missing columns")
  })

  it("errors when geometry is not a list-column", {
    bad <- data.frame(
      label = "lh_x",
      geometry = 1
    )
    expect_error(validate_polygons(bad), "must be a list-column")
  })
})

describe("validate_geom()", {
  it("errors on objects that are neither sf nor brain_polygons", {
    expect_error(validate_geom(list(a = 1)), "must be an")
  })
})

describe("resolve_geom()", {
  it("warns and ignores sf= when geom is also supplied", {
    skip_if_not_installed("sf")
    polys <- sf_to_polygons(dk_sf_geom())
    sf0 <- dk_sf_geom()
    expect_warning(
      resolve_geom(geom = polys, sf = sf0, .fn = "x"),
      "ignoring"
    )
  })
})

describe("validate_polygon_geoms()", {
  it("errors when a geometry entry is not a data.frame", {
    bad <- structure(
      as_tbl(data.frame(label = "lh_x")),
      class = c("brain_polygons", "tbl_df", "tbl", "data.frame")
    )
    bad$geometry <- list("not a data.frame")
    expect_error(validate_polygons(bad), "must be a data.frame")
  })

  it("errors when a geometry data.frame has zero rows", {
    bad <- data.frame(label = "lh_x")
    bad$geometry <- list(data.frame(
      view = character(0),
      x = numeric(0),
      y = numeric(0),
      group = integer(0),
      subgroup = integer(0)
    ))
    expect_error(validate_polygons(bad), "empty")
  })
})

describe("polygons_to_sf()", {
  it("round-trips dk geometry losslessly (areas equal)", {
    skip_if_not_installed("sf")
    sf0 <- dk_sf_geom()
    polys <- sf_to_polygons(sf0)
    sf1 <- polygons_to_sf(polys)

    expect_s3_class(sf1, "sf")
    expect_named(sf1, c("label", "view", "geometry"))

    key0 <- paste(sf0$label, sf0$view, sep = "@@")
    key1 <- paste(sf1$label, sf1$view, sep = "@@")
    o0 <- order(key0)
    o1 <- order(key1)
    a0 <- as.numeric(sf::st_area(sf0$geometry[o0]))
    a1 <- as.numeric(sf::st_area(sf1$geometry[o1]))
    expect_identical(a0, a1)
  })

  it("preserves holes through the round-trip", {
    skip_if_not_installed("sf")
    outer <- matrix(c(0, 0, 10, 0, 10, 10, 0, 10, 0, 0), ncol = 2, byrow = TRUE)
    hole <- matrix(c(2, 2, 8, 2, 8, 8, 2, 8, 2, 2), ncol = 2, byrow = TRUE)
    holey_mp <- sf::st_multipolygon(list(list(outer, hole)))
    solid_mp <- sf::st_multipolygon(list(list(outer)))

    sf_in <- sf::st_sf(
      label = c("holey", "solid"),
      view = c("test", "test"),
      geometry = sf::st_sfc(holey_mp, solid_mp)
    )

    polys <- sf_to_polygons(sf_in)
    holey_nested <- polys$geometry[polys$label == "holey"][[1]]
    expect_identical(sort(unique(holey_nested$subgroup)), c(1L, 2L))

    sf_out <- polygons_to_sf(polys)
    holey_area <- as.numeric(sf::st_area(
      sf_out$geometry[sf_out$label == "holey"]
    ))
    expect_identical(holey_area, 100 - 36)
  })

  it("errors when polygons is malformed", {
    bad <- data.frame(label = "a", geometry = I(list(data.frame(x = 1))))
    expect_error(polygons_to_sf(bad), "needs columns")
  })
})

describe("validate_polygons()", {
  it("rejects non-data.frames", {
    expect_error(validate_polygons(list()), "must be a data.frame")
  })

  it("rejects duplicated labels", {
    bad <- data.frame(label = c("a", "a"))
    bad$geometry <- list(
      data.frame(view = "x", x = 1, y = 1, group = 1L, subgroup = 1L),
      data.frame(view = "x", x = 2, y = 2, group = 1L, subgroup = 1L)
    )
    expect_error(validate_polygons(bad), "one row per")
  })

  it("rejects missing geometry columns", {
    bad <- data.frame(label = "a")
    bad$geometry <- list(data.frame(view = "x", x = 1, y = 1))
    expect_error(validate_polygons(bad), "needs columns")
  })
})

describe("ggseg_data_cortical() geometry", {
  it("accepts polygons input as geom", {
    skip_if_not_installed("sf")
    polys <- sf_to_polygons(dk_sf_geom())
    d <- ggseg_data_cortical(geom = polys)
    expect_s3_class(d$geom, "brain_polygons")
    expect_null(d$sf)
    expect_null(d$polygons)
  })

  it("accepts sf input as geom", {
    d <- ggseg_data_cortical(geom = dk_sf_geom())
    expect_s3_class(d$geom, "sf")
  })

  it("converts a deprecated sf= argument to polygons", {
    withr::local_options(lifecycle_verbosity = "quiet")
    d <- ggseg_data_cortical(sf = dk_sf_geom())
    expect_s3_class(d$geom, "brain_polygons")
  })

  it("errors with no 2D and no 3D source", {
    expect_error(
      ggseg_data_cortical(),
      "At least one of"
    )
  })
})

describe("as_polygon_atlas() / as_sf_atlas()", {
  it("as_polygon_atlas stores polygons in the geom slot", {
    poly <- as_polygon_atlas(dk())
    expect_true(is_atlas_polygon(poly))
    expect_s3_class(atlas_geom(poly), "brain_polygons")
    expect_null(poly$data$sf)
    expect_null(poly$data$polygons)
    expect_true(is_ggseg_atlas(poly))
  })

  it("as_sf_atlas rehydrates sf into the geom slot", {
    rehy <- as_sf_atlas(as_polygon_atlas(dk()))
    expect_true(is_atlas_sf(rehy))
    expect_s3_class(atlas_geom(rehy), "sf")
  })

  it("is_cortical_atlas still holds after conversion", {
    expect_true(is_cortical_atlas(as_polygon_atlas(dk())))
  })

  it("errors on non-atlas input", {
    expect_error(as_polygon_atlas(list()), "ggseg_atlas")
    expect_error(as_sf_atlas(list()), "ggseg_atlas")
  })
})

describe("migrate_atlas_files()", {
  it("rewrites .rda files to a polygon geom slot", {
    tmp <- withr::local_tempdir()
    atlas <- dk_sf_atlas()
    save(atlas, file = file.path(tmp, "atlas.rda"))

    migrated <- migrate_atlas_files(tmp, quiet = TRUE)
    expect_length(migrated, 1)

    env <- new.env()
    load(file.path(tmp, "atlas.rda"), envir = env)
    expect_null(env$atlas$data$sf)
    expect_null(env$atlas$data$polygons)
    expect_s3_class(env$atlas$data$geom, "brain_polygons")
  })

  it("keep_sf = TRUE stores the geom as sf", {
    tmp <- withr::local_tempdir()
    atlas <- dk()
    save(atlas, file = file.path(tmp, "atlas.rda"))

    migrate_atlas_files(tmp, keep_sf = TRUE, quiet = TRUE)

    env <- new.env()
    load(file.path(tmp, "atlas.rda"), envir = env)
    expect_s3_class(env$atlas$data$geom, "sf")
    expect_null(env$atlas$data$sf)
    expect_null(env$atlas$data$polygons)
  })

  it("skips .rda files with no atlas to migrate", {
    tmp <- withr::local_tempdir()
    notatlas <- list(a = 1)
    save(notatlas, file = file.path(tmp, "other.rda"))

    migrated <- migrate_atlas_files(tmp, quiet = TRUE)
    expect_length(migrated, 0)
  })

  it("errors on non-existent path", {
    expect_error(migrate_atlas_files("/no/such/dir"), "does not exist")
  })
})


describe("sf_to_polygons() non-canonical columns", {
  it("carries extra columns into the nested geometry table", {
    sf0 <- dk_sf_geom()
    sf0$myannot <- paste0("ann_", seq_len(nrow(sf0)))
    sf0$colour <- "#FF0000"

    polys <- sf_to_polygons(sf0)
    inner <- polys$geometry[[1]]

    expect_named(
      inner,
      c("view", "x", "y", "group", "subgroup", "myannot", "colour")
    )
    expect_identical(unique(inner$colour), "#FF0000")
  })

  it("survives a round trip back to sf", {
    sf0 <- dk_sf_geom()
    sf0$myannot <- paste0("ann_", seq_len(nrow(sf0)))
    sf0$colour <- "#FF0000"

    back <- polygons_to_sf(sf_to_polygons(sf0))

    expect_true(all(c("myannot", "colour") %in% names(back)))
    i <- match(
      paste(sf0$label, sf0$view),
      paste(back$label, back$view)
    )
    expect_identical(back$myannot[i], sf0$myannot)
    expect_identical(back$colour[i], sf0$colour)
  })

  it("drops columns whose names the coordinate table reserves", {
    skip_if_not_installed("sf")
    sf0 <- as.data.frame(dk_sf_geom())
    sf0$x <- 1
    sf0 <- sf::st_as_sf(sf0)

    expect_warning(polys <- sf_to_polygons(sf0), "Dropping column")
    expect_named(polys$geometry[[1]], c("view", "x", "y", "group", "subgroup"))
    expect_false(all(polys$geometry[[1]]$x == 1))
  })

  it("keeps the sf_column attribute on the rebuilt sf table", {
    back <- polygons_to_sf(atlas_polygons(dk()))
    expect_identical(attr(back, "sf_column"), "geometry")
  })
})
