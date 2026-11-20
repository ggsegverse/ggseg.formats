describe("atlas_schema_version()", {
  it("is a single integer", {
    expect_length(atlas_schema_version(), 1)
    expect_type(atlas_schema_version(), "integer")
  })
})


describe("atlas_schema()", {
  it("reports the version an atlas was built against", {
    expect_identical(atlas_schema(dk()), atlas_schema_version())
  })

  it("stamps every atlas the constructor builds", {
    core <- data.frame(
      hemi = "left",
      region = "a",
      label = "lh_a",
      display = "A"
    )
    vertices <- data.frame(label = "lh_a")
    vertices$vertices <- list(1:3)
    atlas <- ggseg_atlas(
      "t",
      "cortical",
      core,
      ggseg_data_cortical(vertices = vertices)
    )
    expect_identical(atlas_schema(atlas), atlas_schema_version())
  })

  it("is 0 for a legacy list atlas, which carries no stamp", {
    expect_identical(atlas_schema(legacy_list_atlas(dk())), 0L)
  })

  it("rejects a non-atlas", {
    expect_error(atlas_schema(42), "ggseg_atlas")
  })

  it("every bundled atlas is current", {
    # These ship inside the package, so a bump that is not followed by a
    # sysdata rebuild would leave the package's own atlases stale.
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_true(atlas_schema_is_current(atlas))
    }
  })
})


describe("a stale schema", {
  # The failure this machinery exists for: an atlas built against an older
  # class definition carries that definition frozen inside it, so a property
  # added since is not merely missing -- reading it is an error, while S7's
  # own validate() passes, because the validator it runs is the frozen one.
  stale_atlas <- function() {
    atlas <- dk()
    S7::prop(atlas, "schema") <- atlas_schema_version() - 1L
    atlas
  }

  it("is not current", {
    expect_false(atlas_schema_is_current(stale_atlas()))
  })

  it("is refused by assert_ggseg_atlas(), naming both versions", {
    expect_error(
      assert_ggseg_atlas(stale_atlas()),
      class = "ggseg.formats_stale_schema"
    )
    expect_error(assert_ggseg_atlas(stale_atlas()), "schema")
  })

  it("says how to fix it", {
    expect_error(assert_ggseg_atlas(stale_atlas()), "as_ggseg_atlas")
  })

  it("is upgraded by as_ggseg_atlas(), without touching the atlas", {
    stale <- stale_atlas()
    upgraded <- as_ggseg_atlas(stale)

    expect_true(atlas_schema_is_current(upgraded))
    expect_identical(
      as.data.frame(atlas_core(upgraded)),
      as.data.frame(atlas_core(stale))
    )
    expect_identical(atlas_palette(upgraded), atlas_palette(stale))
    expect_identical(atlas_type(upgraded), atlas_type(stale))
    expect_identical(atlas_geom(upgraded), atlas_geom(stale))
  })

  it("is left alone when it is already current", {
    atlas <- dk()
    expect_identical(as_ggseg_atlas(atlas), atlas)
  })

  it("does not fire for a legacy list, which is a different problem", {
    # A legacy list has no frozen class to be stale against. It gets the
    # deprecation and the structural check, not the schema complaint.
    legacy <- legacy_list_atlas(dk())
    expect_no_error(assert_ggseg_atlas(legacy))
  })
})
