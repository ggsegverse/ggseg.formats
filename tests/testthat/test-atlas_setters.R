describe("set_atlas_palette", {
  it("replaces the palette and round-trips through the accessor", {
    a <- dk()
    labs <- atlas_labels(a)
    new_pal <- setNames(rep("#123456", length(labs)), labs)
    a <- set_atlas_palette(a, new_pal)
    expect_identical(atlas_palette(a), new_pal)
  })

  it("warns when the palette does not cover every label", {
    a <- dk()
    labs <- atlas_labels(a)
    expect_warning(
      set_atlas_palette(a, setNames("#123456", labs[1])),
      "does not cover"
    )
  })

  it("errors on an unnamed or non-character value", {
    a <- dk()
    expect_error(
      set_atlas_palette(a, c("#111111", "#222222")),
      "named character"
    )
    expect_error(set_atlas_palette(a, 1:3), "named character")
  })

  it("errors when the object is not an atlas", {
    expect_error(
      set_atlas_palette(data.frame(y = 1), c(a = "#111111")),
      "must be a.*ggseg_atlas"
    )
  })
})

describe("set_atlas_type", {
  it("retypes an atlas whose payload matches the new type", {
    a <- tracula()
    b <- set_atlas_type(a, "tract")
    expect_identical(atlas_type(b), "tract")
    expect_true(is_tract_atlas(b))
    expect_identical(class(b)[1], "tract_atlas")
  })

  it("keeps the ggseg_atlas class and ordering intact", {
    b <- set_atlas_type(tracula(), "tract")
    expect_s3_class(b, c("tract_atlas", "ggseg_atlas", "list"), exact = TRUE)
  })

  it("leaves every other atlas component untouched", {
    a <- tracula()
    b <- set_atlas_type(a, "tract")
    expect_identical(b$core, a$core)
    expect_identical(atlas_palette(b), atlas_palette(a))
    expect_identical(b$data, a$data)
  })

  it("is idempotent when the type is unchanged", {
    a <- aseg()
    expect_identical(set_atlas_type(a, atlas_type(a)), a)
  })

  it("errors when the payload does not match the requested type", {
    expect_error(set_atlas_type(aseg(), "tract"), "requires")
    expect_error(set_atlas_type(dk(), "subcortical"), "requires")
  })

  it("errors on an unknown type", {
    expect_error(set_atlas_type(aseg(), "wibble"), "'arg' should be one of")
  })

  it("errors when the object is not an atlas", {
    expect_error(
      set_atlas_type(data.frame(y = 1), "tract"),
      "must be a.*ggseg_atlas"
    )
  })
})

describe("atlas provenance", {
  record <- list(
    pipeline = "ggseg.extra::create_cortical_atlas 1.9.9",
    created = "2026-10-29",
    source = "Desikan-Killiany",
    parameters = list(keep = 0.25)
  )

  it("is absent on an atlas that never recorded one", {
    expect_null(atlas_provenance(dk()))
  })

  it("round-trips through the setter", {
    atlas <- set_atlas_provenance(dk(), record)
    expect_identical(atlas_provenance(atlas), record)
  })

  it("can be dropped again", {
    atlas <- set_atlas_provenance(dk(), record)
    expect_null(atlas_provenance(set_atlas_provenance(atlas, NULL)))
  })

  it("is accepted by the constructor and leaves the atlas valid", {
    atlas <- dk()
    rebuilt <- ggseg_atlas(
      atlas = atlas$atlas,
      type = atlas$type,
      core = atlas$core,
      data = atlas$data,
      palette = atlas$palette,
      provenance = record
    )
    expect_true(is_ggseg_atlas(rebuilt))
    expect_identical(atlas_provenance(rebuilt), record)
  })

  it("rejects an atlas argument that is not an atlas", {
    expect_error(atlas_provenance(list()), "must be a")
    expect_error(set_atlas_provenance(list(), record), "must be a")
  })

  # The reason provenance is a constructor argument rather than an attribute.
  # Every reshaping verb rebuilds the atlas through ggseg_atlas(), so anything
  # the constructor does not copy is dropped without a word. Each of these
  # reshapes an existing atlas, so each must preserve how it was built.
  it("survives every verb that reshapes an existing atlas", {
    atlas <- set_atlas_provenance(dk(), record)
    labels <- unique(atlas_labels(atlas))
    one <- paste0("^", labels[1], "$")

    reshaped <- list(
      region_remove = atlas_region_remove(atlas, one),
      region_keep = atlas_region_keep(atlas, one),
      # These two assembled the object themselves rather than calling the
      # constructor, so they dropped the record while every other verb kept
      # it. atlas_view_gather() runs on nearly every built atlas, so the loss
      # was total in practice and invisible in principle.
      view_gather = atlas_view_gather(atlas),
      region_contextual = atlas_region_contextual(atlas, one),
      region_rename = atlas_region_rename(
        atlas,
        paste0("^", unique(atlas_regions(atlas))[1], "$"),
        "renamed",
        match_on = "region"
      ),
      set_type = set_atlas_type(atlas, atlas_type(atlas)),
      relabel = relabel_atlas(atlas, stats::setNames(labels[1], labels[1]))
    )

    for (verb in names(reshaped)) {
      expect_identical(
        atlas_provenance(reshaped[[verb]]),
        record,
        info = verb
      )
    }
  })
})
