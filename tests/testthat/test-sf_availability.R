describe("has_sf()", {
  it("returns a logical scalar", {
    expect_type(has_sf(), "logical")
    expect_length(has_sf(), 1)
  })

  it("reports FALSE when sf is not installed", {
    local_mocked_bindings(
      is_installed = function(...) FALSE,
      .package = "rlang"
    )
    expect_false(has_sf())
  })
})

describe("require_sf()", {
  it("returns invisible TRUE when sf is installed", {
    skip_if_not_installed("sf")
    expect_invisible(require_sf("an operation"))
    expect_true(require_sf("an operation"))
  })

  it("aborts with a pointer to the polygon alternative when sf is missing", {
    local_mocked_bindings(has_sf = function() FALSE)
    expect_error(require_sf("atlas_sf()"), "sf")
    expect_error(require_sf("atlas_sf()"), "as_polygon_atlas")
  })

  it("asks has_sf(), so mocking it is enough to exercise the no-sf path", {
    local_mocked_bindings(has_sf = function() FALSE)
    expect_error(require_sf("an operation"), "requires the")

    local_mocked_bindings(has_sf = function() TRUE)
    expect_true(require_sf("an operation"))
  })
})
