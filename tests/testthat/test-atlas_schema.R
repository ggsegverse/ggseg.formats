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


describe("base generics reach both representations", {
  # The S7 conversion silently broke these. Registering an S7 method on a base
  # generic stops this package's S3 method for the same generic reaching
  # base's dispatch table, so `plot()` on a legacy list atlas fell through to
  # `plot.default()` and `print()` dumped 520 lines of raw list where it had
  # shown a 22-line summary. No test noticed, because every fixture was an S7
  # atlas. These check both.
  both <- function() {
    list(
      S7 = dk(),
      legacy = structure(
        as.list(dk()),
        class = c("cortical_atlas", "ggseg_atlas", "list")
      )
    )
  }

  it("print() gives the atlas summary, not a property dump", {
    for (atlas in both()) {
      out <- capture.output(print(atlas))
      expect_lt(length(out), 60)
      expect_false(any(grepl("^\\$atlas", out)))
      expect_false(any(grepl("^<ggseg.formats::", out)))
    }
  })

  it("print() gives the same summary for both representations", {
    atlases <- both()
    expect_identical(
      capture.output(print(atlases$S7)),
      capture.output(print(atlases$legacy))
    )
  })

  it("plot() draws rather than falling through to plot.default()", {
    for (atlas in both()) {
      grDevices::pdf(NULL)
      expect_no_error(plot(atlas))
      grDevices::dev.off()
    }
  })

  it("as.data.frame() coerces rather than erroring", {
    skip_if_not_installed("sf")
    for (atlas in both()) {
      expect_s3_class(as.data.frame(atlas), "data.frame")
    }
  })

  it("as.list() returns the slots", {
    for (atlas in both()) {
      expect_true(all(
        c("atlas", "type", "core", "data") %in%
          names(as.list(atlas))
      ))
    }
  })

  it("names() reports the slots", {
    for (atlas in both()) {
      expect_true(all(c("atlas", "core", "data") %in% names(atlas)))
    }
  })

  it("the unqualified class tags lead, so S3 finds our methods first", {
    # An S7 atlas whose qualified names led reached S7's print.S7_object
    # before ever reaching print.ggseg_atlas.
    expect_identical(class(dk())[1], "cortical_atlas")
    expect_identical(class(dk())[2], "ggseg_atlas")
  })
})
