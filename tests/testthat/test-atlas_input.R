legacy_atlas <- function(atlas = dk()) {
  structure(
    as.list(atlas),
    class = c(paste0(atlas_type(atlas), "_atlas"), "ggseg_atlas", "list")
  )
}

describe("atlas_input()", {
  it("returns a current atlas untouched", {
    expect_identical(atlas_input(dk()), dk())
  })

  it("upgrades a legacy list atlas", {
    out <- atlas_input(legacy_atlas())
    expect_true(S7::S7_inherits(out))
    expect_true(atlas_schema_is_current(out))
  })

  it("upgrades an atlas on an older schema", {
    stale <- dk()
    S7::prop(stale, "schema") <- atlas_schema_version() - 1L
    expect_true(atlas_schema_is_current(atlas_input(stale)))
  })

  it("carries the atlas across unchanged", {
    # The boundary must not alter what it lets through.
    original <- dk()
    out <- atlas_input(legacy_atlas(original))
    expect_identical(
      as.data.frame(atlas_core(out)),
      as.data.frame(atlas_core(original))
    )
    expect_identical(atlas_palette(out), atlas_palette(original))
    expect_identical(atlas_geom(out), atlas_geom(original))
  })

  it("blames the caller's argument for a non-atlas", {
    takes_an_atlas <- function(brain) atlas_input(brain)
    expect_error(
      takes_an_atlas(42),
      class = "ggseg.formats_not_atlas"
    )
    expect_error(takes_an_atlas(42), "brain")
  })

  it("reports an invalid atlas with the defect as the cause", {
    broken <- legacy_atlas()
    broken$core$label <- NULL
    expect_error(
      atlas_input(broken),
      class = "ggseg.formats_invalid_atlas"
    )
  })

  it("is silent on the way through", {
    # A boundary that chatters is a boundary people route around.
    expect_silent(atlas_input(legacy_atlas()))
  })

  it("works for every bundled atlas, in both representations", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_true(atlas_schema_is_current(atlas_input(atlas)))
      expect_true(atlas_schema_is_current(atlas_input(legacy_atlas(atlas))))
    }
  })
})
