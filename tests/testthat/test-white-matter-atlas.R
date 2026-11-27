describe("atlas_types()", {
  it("is the governed vocabulary, pinned so a change cannot pass unremarked", {
    # Consumers match.arg() against this, and every atlas package declares a
    # type from it. Growing or narrowing it is a contract change, which is
    # why it is written out here rather than derived.
    expect_identical(
      atlas_types(),
      c("cortical", "subcortical", "tract", "cerebellar", "white_matter")
    )
  })
})


describe("a white-matter atlas", {
  white_matter_atlas_fixture <- function() {
    meshes <- data.frame(
      label = c("cst_left", "cst_right"),
      stringsAsFactors = FALSE
    )
    meshes$mesh <- list(
      list(
        vertices = data.frame(x = c(-10, -9, -8), y = 1:3, z = 1:3),
        faces = data.frame(i = 1L, j = 2L, k = 3L)
      ),
      list(
        vertices = data.frame(x = c(10, 9, 8), y = 1:3, z = 1:3),
        faces = data.frame(i = 1L, j = 2L, k = 3L)
      )
    )
    ggseg_atlas(
      atlas = "demo_wm",
      type = "white_matter",
      core = data.frame(
        hemi = c("left", "right"),
        region = c("cst", "cst"),
        label = c("cst_left", "cst_right"),
        display = c("cst_left", "cst_right"),
        stringsAsFactors = FALSE
      ),
      data = ggseg_data_white_matter(meshes = meshes)
    )
  }

  it("is its own type", {
    expect_true(is_white_matter_atlas(white_matter_atlas_fixture()))
    expect_identical(atlas_type(white_matter_atlas_fixture()), "white_matter")
  })

  it("is also a subcortical atlas, so methods written for one apply", {
    # The reason the parent is in the class vector at all: a white-matter
    # atlas stores what a subcortical one stores and is drawn the same way,
    # so nothing has to be written twice.
    expect_true(is_subcortical_atlas(white_matter_atlas_fixture()))
  })

  it("is not any of the other types", {
    a <- white_matter_atlas_fixture()
    expect_false(is_cortical_atlas(a))
    expect_false(is_tract_atlas(a))
    expect_false(is_cerebellar_atlas(a))
  })

  it("carries meshes the shared accessor can read", {
    expect_identical(nrow(atlas_meshes(white_matter_atlas_fixture())), 2L)
  })

  it("does not make a subcortical atlas a white-matter one", {
    # Inheritance runs one way. A plain subcortical atlas must not start
    # answering to is_white_matter_atlas().
    sub <- ggseg_atlas(
      atlas = "demo_sub",
      type = "subcortical",
      core = data.frame(
        hemi = "left",
        region = "thal",
        label = "thal_left",
        display = "thal_left",
        stringsAsFactors = FALSE
      ),
      data = ggseg_data_subcortical(
        meshes = local({
          m <- data.frame(label = "thal_left", stringsAsFactors = FALSE)
          m$mesh <- list(list(
            vertices = data.frame(x = 1:3, y = 1:3, z = 1:3),
            faces = data.frame(i = 1L, j = 2L, k = 3L)
          ))
          m
        })
      )
    )
    expect_false(is_white_matter_atlas(sub))
  })
})


describe("ggseg_data_white_matter()", {
  it("inherits the subcortical data class", {
    d <- ggseg_data_white_matter(
      meshes = local({
        m <- data.frame(label = "a", stringsAsFactors = FALSE)
        m$mesh <- list(list(
          vertices = data.frame(x = 1:3, y = 1:3, z = 1:3),
          faces = data.frame(i = 1L, j = 2L, k = 3L)
        ))
        m
      })
    )
    expect_s3_class(d, "ggseg_data_white_matter")
    expect_s3_class(d, "ggseg_data_subcortical")
  })

  it("needs geometry or meshes, like its parent", {
    expect_error(ggseg_data_white_matter(), "At least one of")
  })
})

describe("a wm atlas cannot be built invalid", {
  it("refuses a subcortical payload at construction", {
    # `wm_atlas` sits under `subcortical_atlas`, and S7 runs the validator
    # while the two-level subclass is still stamped with its parent -- so the
    # `type` the validator computed was "subcortical" and a wm atlas carrying
    # a subcortical payload was constructed, invalid the moment it existed.
    # nolint start: undesirable_operator_linter.
    expect_error(
      ggseg.formats:::new_ggseg_atlas(
        "x",
        "wm",
        NULL,
        atlas_core(aseg()),
        atlas_data(aseg()),
        NULL
      )
    )
    # nolint end
  })

  it("keeps the wm payload through a geometry verb", {
    # `rebuild_data_with_geom()` sniffs which slots are filled, so a wm
    # payload came back as `ggseg_data_subcortical` and the atlas no longer
    # validated -- with the validator now running, that would be a hard error
    # out of every view and region verb.
    atlas <- ggseg_atlas(
      atlas = "wmtest",
      type = "white_matter",
      core = atlas_core(aseg()),
      palette = atlas_palette(aseg()),
      data = ggseg_data_white_matter(
        geom = atlas_data(aseg())$geom,
        meshes = atlas_data(aseg())$meshes
      )
    )

    result <- atlas_view_gather(atlas)

    expect_s3_class(atlas_data(result), "ggseg_data_white_matter")
    expect_true(is_ggseg_atlas(result))
  })
})

describe("the pre-0.1.0 `wm` spelling", {
  meshes <- function() {
    out <- data.frame(label = "cst_left", stringsAsFactors = FALSE)
    out$mesh <- list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    ))
    out
  }
  core <- function() {
    data.frame(
      region = "cst",
      label = "cst_left",
      hemi = "left",
      display = "CST",
      stringsAsFactors = FALSE
    )
  }

  it("is repaired by the constructor, with a deprecation warning", {
    # expect_error()/expect_no_warning() cannot see a lifecycle warning
    # without the class, so name it.
    expect_warning(
      atlas <- ggseg_atlas(
        atlas = "demo",
        type = "wm",
        core = core(),
        data = ggseg_data_white_matter(meshes = meshes())
      ),
      class = "lifecycle_warning_deprecated"
    )
    expect_identical(atlas_type(atlas), "white_matter")
    expect_true(is_white_matter_atlas(atlas))
  })

  it("is not in the vocabulary any more", {
    expect_false("wm" %in% atlas_types())
    expect_true("white_matter" %in% atlas_types())
  })

  it("keeps the old function names working, deprecated", {
    expect_warning(
      data <- ggseg_data_wm(meshes = meshes()),
      class = "lifecycle_warning_deprecated"
    )
    expect_s3_class(data, "ggseg_data_white_matter")

    withr::local_options(lifecycle_verbosity = "quiet")
    atlas <- ggseg_atlas(
      atlas = "demo",
      type = "white_matter",
      core = core(),
      data = ggseg_data_white_matter(meshes = meshes())
    )
    withr::local_options(lifecycle_verbosity = "warning")
    expect_warning(
      out <- is_wm_atlas(atlas),
      class = "lifecycle_warning_deprecated"
    )
    expect_true(out)
  })
})
