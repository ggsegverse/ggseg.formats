describe("set_atlas_name()", {
  it("replaces the name", {
    expect_identical(atlas_name(set_atlas_name(dk(), "renamed")), "renamed")
  })

  it("rejects a name that is not a single string", {
    expect_error(set_atlas_name(dk(), c("a", "b")), "single, non-missing")
    expect_error(set_atlas_name(dk(), NA_character_), "single, non-missing")
    expect_error(set_atlas_name(dk(), 1), "single, non-missing")
  })

  it("rejects a non-atlas", {
    expect_error(set_atlas_name(list(), "x"), class = "rlang_error")
  })
})


describe("set_atlas_geom()", {
  it("round-trips the geometry it was given", {
    atlas <- dk()
    expect_identical(
      atlas_geom(set_atlas_geom(atlas, atlas_geom(atlas))),
      atlas_geom(atlas)
    )
  })

  it("replaces rather than merges", {
    atlas <- dk()
    half <- utils::head(atlas_geom(atlas), 3)
    expect_identical(nrow(atlas_geom(set_atlas_geom(atlas, half))), 3L)
  })

  it("clears the legacy sf slot, so the write is not shadowed", {
    # `atlas_geom()` falls back to the legacy `sf` slot when `geom` is absent.
    # A write that left `sf` in place would be invisible on an atlas that
    # still carried one.
    atlas <- dk()
    written <- set_atlas_geom(atlas, utils::head(atlas_geom(atlas), 2))
    expect_null(atlas_data(written)$sf)
    expect_identical(nrow(atlas_geom(written)), 2L)
  })

  it("rejects geometry that is not a data frame", {
    expect_error(set_atlas_geom(dk(), 1:3), "data frame")
  })
})


describe("set_atlas_core()", {
  it("replaces the core table", {
    atlas <- dk()
    keep <- utils::head(atlas_core(atlas), 10)
    expect_identical(nrow(atlas_core(set_atlas_core(atlas, keep))), 10L)
  })

  it("carries the palette across, dropping labels that have gone", {
    atlas <- dk()
    keep <- utils::head(atlas_core(atlas), 10)
    result <- set_atlas_core(atlas, keep)
    expect_length(atlas_palette(result), 10)
    expect_setequal(names(atlas_palette(result)), keep$label)
  })

  it("clears the palette when asked", {
    atlas <- dk()
    keep <- utils::head(atlas_core(atlas), 10)
    expect_length(atlas_palette(set_atlas_core(atlas, keep, palette = NULL)), 0)
  })

  it("takes a new palette", {
    atlas <- dk()
    keep <- utils::head(atlas_core(atlas), 2)
    pal <- stats::setNames(c("#000000", "#FFFFFF"), keep$label)
    expect_identical(atlas_palette(set_atlas_core(atlas, keep, pal)), pal)
  })

  it("lands core and palette together, which stepwise assignment cannot", {
    # The validator spans properties, so assigning a core whose labels the
    # current palette does not key would fail on its own. This is the whole
    # reason the setter takes both.
    atlas <- dk()
    keep <- utils::head(atlas_core(atlas), 2)
    pal <- stats::setNames(c("#000000", "#FFFFFF"), keep$label)
    expect_no_error(set_atlas_core(atlas, keep, pal))
  })

  it("still enforces the invariants", {
    atlas <- dk()
    dupe <- atlas_core(atlas)[c(1, 1), , drop = FALSE]
    expect_error(set_atlas_core(atlas, dupe), "must be unique")
  })

  it("rejects a core that is not a data frame", {
    expect_error(set_atlas_core(dk(), 1:3), "must be a data.frame")
  })
})


describe("has_atlas_*() geometry predicates", {
  it("report the 3D geometry each bundled atlas actually carries", {
    expect_true(has_atlas_vertices(dk()))
    expect_false(has_atlas_meshes(dk()))

    expect_true(has_atlas_meshes(aseg()))
    expect_false(has_atlas_vertices(aseg()))

    expect_true(has_atlas_centerlines(tracula()))
    expect_false(has_atlas_meshes(tracula()))
  })

  it("has_atlas_3d() is true when any 3D geometry is present", {
    expect_true(has_atlas_3d(dk()))
    expect_true(has_atlas_3d(aseg()))
    expect_true(has_atlas_3d(tracula()))
  })

  it("has_atlas_geom() reports 2D geometry", {
    expect_true(has_atlas_geom(dk()))
  })

  it("is FALSE for a non-atlas rather than erroring", {
    # These are used in control flow, so they must not abort.
    for (f in list(
      has_atlas_geom,
      has_atlas_vertices,
      has_atlas_meshes,
      has_atlas_centerlines,
      has_atlas_3d
    )) {
      expect_false(f(42))
      expect_false(f(list()))
      expect_false(f(NULL))
    }
  })

  it("is FALSE, not an error, for an atlas missing that geometry", {
    # The accessors abort in this case; the predicates exist precisely so a
    # caller can ask without catching an error.
    expect_false(has_atlas_centerlines(dk()))
    expect_error(atlas_centerlines(dk()))
  })
})


describe("every setter works on a legacy list atlas", {
  # An atlas package built before 3.0.0 ships a tagged list, and those are
  # valid atlases -- `is_ggseg_atlas()` says so. Reaching a property with `@`
  # on one makes R try S4 semantics and fail with "not a defined class", so
  # every setter has to go through the representation bridge instead. All of
  # them did this wrong until a published atlas was poked at.
  legacy <- function() {
    structure(
      as.list(dk()),
      class = c("cortical_atlas", "ggseg_atlas", "list")
    )
  }

  it("is a valid atlas to begin with", {
    expect_true(is_atlas_class(legacy()))
    expect_true(is_ggseg_atlas(legacy()))
  })

  it("set_atlas_palette()", {
    atlas <- legacy()
    pal <- utils::head(atlas_palette(atlas), 3)
    expect_identical(
      atlas_palette(suppressWarnings(set_atlas_palette(atlas, pal))),
      pal
    )
  })

  it("set_atlas_palette(NULL)", {
    expect_length(atlas_palette(set_atlas_palette(legacy(), NULL)), 0)
  })

  it("set_atlas_name()", {
    expect_identical(atlas_name(set_atlas_name(legacy(), "renamed")), "renamed")
  })

  it("set_atlas_provenance()", {
    prov <- list(pipeline = "test", created = "2026-11-20")
    expect_identical(
      atlas_provenance(set_atlas_provenance(legacy(), prov)),
      prov
    )
  })

  it("set_atlas_geom()", {
    atlas <- legacy()
    half <- utils::head(atlas_geom(atlas), 2)
    expect_identical(nrow(atlas_geom(set_atlas_geom(atlas, half))), 2L)
  })

  it("set_atlas_core()", {
    atlas <- legacy()
    keep <- utils::head(atlas_core(atlas), 5)
    expect_identical(nrow(atlas_core(set_atlas_core(atlas, keep))), 5L)
  })

  it("set_atlas_type()", {
    expect_identical(
      atlas_type(set_atlas_type(legacy(), "cortical")),
      "cortical"
    )
  })

  it("leaves the atlas a list, not a half-converted object", {
    out <- set_atlas_name(legacy(), "renamed")
    expect_true(is.list(out))
    expect_false(S7::S7_inherits(out))
    expect_true(is_atlas_class(out))
  })
})

describe("set_atlas_geom() on a legacy atlas", {
  it("writes geometry that survives the next coercion", {
    # A pre-2.0 atlas keeps geometry in a top-level `sf` with no payload at
    # all. Writing `geom` beside it left the old `sf` to shadow the write,
    # which then won at the next coercion -- a ggseg.extra pipeline that
    # smoothed a legacy atlas saved the unsmoothed geometry, silently.
    a <- dk()
    geom <- atlas_geom(a)
    legacy <- structure(
      list(
        atlas = "dk",
        type = "cortical",
        palette = atlas_palette(a),
        core = atlas_core(a),
        sf = geom,
        vertices = atlas_data(a)$vertices
      ),
      class = c("cortical_atlas", "ggseg_atlas", "list")
    )

    result <- set_atlas_geom(legacy, geom[1:10, ])

    expect_true(is_ggseg_atlas(result))
    expect_identical(nrow(atlas_geom(result)), 10L)
    expect_identical(nrow(atlas_geom(as_ggseg_atlas(result))), 10L)
  })
})
