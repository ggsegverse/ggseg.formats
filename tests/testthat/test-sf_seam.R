describe("attach_sfc()", {
  it("builds a frame sf's own accessors accept", {
    skip_if_not_installed("sf")
    sf_data <- atlas_sf(dk())
    geometry <- sf_data$geometry
    attrs <- sf_data
    attrs$geometry <- NULL
    class(attrs) <- "data.frame"

    out <- attach_sfc(attrs, geometry)

    expect_s3_class(out, "sf")
    expect_s3_class(out$geometry, "sfc")
    expect_identical(attr(out, "sf_column"), "geometry")
    expect_identical(sf::st_geometry(out), geometry)
    expect_named(attr(out, "agr"), setdiff(names(out), "geometry"))
  })

  it("honours the requested column position, including the first", {
    df <- data.frame(a = 1:2, b = 3:4, c = 5:6)
    geometry <- structure(list(1, 2), class = c("sfc_POINT", "sfc"))

    expect_named(
      attach_sfc(df, geometry, after = 2L),
      c("a", "b", "geometry", "c")
    )
    expect_named(
      attach_sfc(df, geometry, after = 0L),
      c("geometry", "a", "b", "c")
    )
    expect_named(
      attach_sfc(df, geometry),
      c("a", "b", "c", "geometry")
    )
  })

  it("uses the geometry column name it is given", {
    df <- data.frame(a = 1:2)
    geometry <- structure(list(1, 2), class = c("sfc_POINT", "sfc"))

    out <- attach_sfc(df, geometry, sf_column = "geom")

    expect_identical(attr(out, "sf_column"), "geom")
    expect_named(out, c("a", "geom"))
    expect_named(attr(out, "agr"), "a")
  })
})


describe("reorder_sfc()", {
  it("permutes and keeps every sfc attribute", {
    skip_if_not_installed("sf")
    geometry <- atlas_sf(dk())$geometry
    i <- rev(seq_along(geometry))

    out <- reorder_sfc(geometry, i)

    expect_s3_class(out, "sfc")
    expect_identical(attributes(out), attributes(geometry))
    expect_identical(unclass(out)[[1]], unclass(geometry)[[length(geometry)]])
  })

  it("carries a repeated position, as a join expanding rows would", {
    skip_if_not_installed("sf")
    geometry <- atlas_sf(dk())$geometry

    out <- reorder_sfc(geometry, c(1L, 1L, 2L))

    expect_length(out, 3L)
    expect_identical(unclass(out)[[1]], unclass(out)[[2]])
  })
})
