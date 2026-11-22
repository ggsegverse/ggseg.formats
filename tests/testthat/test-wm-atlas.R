describe("atlas_types()", {
  it("is the governed vocabulary, pinned so a change cannot pass unremarked", {
    # Consumers match.arg() against this, and every atlas package declares a
    # type from it. Growing or narrowing it is a contract change, which is
    # why it is written out here rather than derived.
    expect_identical(
      atlas_types(),
      c("cortical", "subcortical", "tract", "cerebellar", "wm")
    )
  })
})


describe("a white-matter atlas", {
  wm_atlas <- function() {
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
      type = "wm",
      core = data.frame(
        hemi = c("left", "right"),
        region = c("cst", "cst"),
        label = c("cst_left", "cst_right"),
        display = c("cst_left", "cst_right"),
        stringsAsFactors = FALSE
      ),
      data = ggseg_data_wm(meshes = meshes)
    )
  }

  it("is its own type", {
    expect_true(is_wm_atlas(wm_atlas()))
    expect_identical(atlas_type(wm_atlas()), "wm")
  })

  it("is also a subcortical atlas, so methods written for one apply", {
    # The reason the parent is in the class vector at all: a white-matter
    # atlas stores what a subcortical one stores and is drawn the same way,
    # so nothing has to be written twice.
    expect_true(is_subcortical_atlas(wm_atlas()))
  })

  it("is not any of the other types", {
    a <- wm_atlas()
    expect_false(is_cortical_atlas(a))
    expect_false(is_tract_atlas(a))
    expect_false(is_cerebellar_atlas(a))
  })

  it("carries meshes the shared accessor can read", {
    expect_identical(nrow(atlas_meshes(wm_atlas())), 2L)
  })

  it("does not make a subcortical atlas a white-matter one", {
    # Inheritance runs one way. A plain subcortical atlas must not start
    # answering to is_wm_atlas().
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
    expect_false(is_wm_atlas(sub))
  })
})


describe("ggseg_data_wm()", {
  it("inherits the subcortical data class", {
    d <- ggseg_data_wm(
      meshes = local({
        m <- data.frame(label = "a", stringsAsFactors = FALSE)
        m$mesh <- list(list(
          vertices = data.frame(x = 1:3, y = 1:3, z = 1:3),
          faces = data.frame(i = 1L, j = 2L, k = 3L)
        ))
        m
      })
    )
    expect_s3_class(d, "ggseg_data_wm")
    expect_s3_class(d, "ggseg_data_subcortical")
  })

  it("needs geometry or meshes, like its parent", {
    expect_error(ggseg_data_wm(), "At least one of")
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
      type = "wm",
      core = atlas_core(aseg()),
      palette = atlas_palette(aseg()),
      data = ggseg_data_wm(
        geom = atlas_data(aseg())$geom,
        meshes = atlas_data(aseg())$meshes
      )
    )

    result <- atlas_view_gather(atlas)

    expect_s3_class(atlas_data(result), "ggseg_data_wm")
    expect_true(is_ggseg_atlas(result))
  })
})
