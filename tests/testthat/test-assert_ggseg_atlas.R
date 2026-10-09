describe("assert_ggseg_atlas", {
  it("returns the atlas unchanged and invisibly when it is valid", {
    atlas <- dk()

    expect_invisible(assert_ggseg_atlas(atlas))
    expect_identical(assert_ggseg_atlas(atlas), atlas)
  })

  it("reports a wrong class as a wrong class", {
    expect_error(
      assert_ggseg_atlas(mtcars),
      "must be a <ggseg_atlas>, not <data.frame>",
      class = "ggseg.formats_not_atlas"
    )
  })

  it("names the argument of the calling function", {
    outer <- function(my_atlas) assert_ggseg_atlas(my_atlas)

    expect_error(outer(42), "`my_atlas` must be a <ggseg_atlas>")
  })

  it("attributes the error to the caller, not to itself", {
    outer <- function(atlas) assert_ggseg_atlas(atlas)

    cnd <- rlang::catch_cnd(outer(42), "error")
    expect_identical(conditionCall(cnd), quote(outer(42)))

    broken <- dk()
    broken$core$label <- NULL
    cnd <- rlang::catch_cnd(outer(broken), "error")
    expect_identical(conditionCall(cnd), quote(outer(broken)))
  })

  it("surfaces a missing core column instead of the class", {
    atlas <- dk()
    atlas$core$label <- NULL

    expect_error(
      assert_ggseg_atlas(atlas),
      "`core` must contain columns: label",
      class = "ggseg.formats_invalid_atlas"
    )
  })

  it("surfaces a duplicated core label", {
    atlas <- dk()
    atlas$core$label[2] <- atlas$core$label[1]

    expect_error(
      assert_ggseg_atlas(atlas),
      "`core\\$label` must be unique",
      class = "ggseg.formats_invalid_atlas"
    )
  })

  it("surfaces a non-character core names column", {
    atlas <- dk()
    atlas$core$names <- seq_len(nrow(atlas$core))

    expect_error(
      assert_ggseg_atlas(atlas),
      "`core\\$names` must be a character vector, not <integer>",
      class = "ggseg.formats_invalid_atlas"
    )
  })

  it("surfaces an unnamed palette", {
    atlas <- dk()
    atlas$palette <- unname(atlas_palette(atlas))

    expect_error(
      assert_ggseg_atlas(atlas),
      "`palette` must be a named character vector",
      class = "ggseg.formats_invalid_atlas"
    )
  })

  it("surfaces a core label without 3D geometry", {
    atlas <- aseg()
    dropped <- atlas$data$meshes$label[1]
    atlas$data$meshes <- atlas$data$meshes[-1, ]

    expect_error(
      assert_ggseg_atlas(atlas),
      "All core labels must have corresponding meshes data",
      class = "ggseg.formats_invalid_atlas"
    )
    expect_error(assert_ggseg_atlas(atlas), dropped)
  })

  it("surfaces a data slot that is not a ggseg_atlas_data", {
    atlas <- dk()
    atlas$data <- data.frame(label = "lh_bankssts")

    expect_error(
      assert_ggseg_atlas(atlas),
      "`data` must be a <ggseg_atlas_data> object",
      class = "ggseg.formats_invalid_atlas"
    )
  })

  it("surfaces a type that disagrees with the data class", {
    atlas <- dk()
    class(atlas$data) <- c(
      "ggseg_data_subcortical",
      "ggseg_atlas_data",
      "list"
    )

    expect_error(
      assert_ggseg_atlas(atlas),
      'Atlas type "cortical" requires <ggseg_data_cortical>',
      class = "ggseg.formats_invalid_atlas"
    )
  })
})

describe("validate_ggseg_atlas", {
  it("stays a bare logical and signals nothing", {
    atlas <- dk()
    valid <- validate_ggseg_atlas(atlas)

    expect_true(valid)
    expect_type(valid, "logical")
    expect_length(valid, 1)
    expect_null(attributes(valid))

    atlas$core$label <- NULL
    expect_silent(invalid <- validate_ggseg_atlas(atlas))
    expect_false(invalid)
    expect_null(attributes(invalid))
  })
})

describe("atlas format converters", {
  it("report why an invalid atlas cannot be converted", {
    atlas <- dk()
    atlas$core$label[2] <- atlas$core$label[1]

    expect_error(
      as_polygon_atlas(atlas),
      "`core\\$label` must be unique",
      class = "ggseg.formats_invalid_atlas"
    )
    expect_error(
      as_sf_atlas(atlas),
      "`core\\$label` must be unique",
      class = "ggseg.formats_invalid_atlas"
    )
  })

  it("still reject a non-atlas on its class", {
    expect_error(
      as_polygon_atlas(mtcars),
      "`atlas` must be a <ggseg_atlas>",
      class = "ggseg.formats_not_atlas"
    )
  })
})
