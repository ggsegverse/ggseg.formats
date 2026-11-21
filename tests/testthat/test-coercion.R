describe("as_ggseg_atlas", {
  it("converts list to ggseg_atlas", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    lst <- as.list(atlas)
    result <- as_ggseg_atlas(lst)

    expect_s3_class(result, "ggseg_atlas")
    expect_identical(atlas_name(result), "test")
  })

  it("errors for unsupported object types", {
    expect_error(as_ggseg_atlas(~age), class = "ggseg.formats_not_atlas")
  })

  it("errors for empty list", {
    expect_error(as_ggseg_atlas(list()), class = "ggseg.formats_not_atlas")
  })
})


describe("as_ggseg_atlas() repairs a published 2.x atlas", {
  # Six atlas objects published in the 2.x series -- ggsegCraddock's three
  # cerebellar atlases, ggsegMcalt's, ggsegAal's `aal3_cerebellum` and
  # ggsegDemoatlas -- ship a legacy `hemi` spelling. They are tagged lists
  # carrying a modern payload, so they take the `restamp_class()` path, which
  # upgraded without repairing anything. The spellings are accepted as input;
  # only the constructed object has to conform.
  it("normalises a legacy hemi spelling on the way in", {
    for (spelling in c("vermis", "middle", "lh", "rh")) {
      atlas <- legacy_list_atlas(dk())
      atlas$core$hemi[1] <- spelling

      result <- as_ggseg_atlas(atlas)

      expect_true(is_ggseg_atlas(result))
      expect_true(all(
        atlas_core(result)$hemi %in% c("left", "right", "midline", NA)
      ))
    }
  })

  it("collapses duplicated core labels on the way in", {
    atlas <- legacy_list_atlas(dk())
    atlas$core$label[2] <- atlas$core$label[1]

    expect_warning(
      result <- as_ggseg_atlas(atlas),
      class = "ggseg.formats_collapsed_duplicate_labels"
    )
    expect_identical(anyDuplicated(atlas_core(result)$label), 0L)
  })
  it("normalises a legacy hemi spelling in an untagged list", {
    # An untagged list built through the public constructor skipped the
    # repair, because the constructor must refuse a bad `hemi` from an atlas
    # author rather than quietly fix it.
    atlas <- unclass(legacy_list_atlas(dk()))
    atlas$core$hemi[1] <- "vermis"

    result <- as_ggseg_atlas(atlas)

    expect_true(is_ggseg_atlas(result))
    expect_false("vermis" %in% atlas_core(result)$hemi)
  })
})


describe("as_ggseg_atlas.ggseg_atlas", {
  it("converts legacy structure with separate sf/vertices fields", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = c("lh_frontal", "rh_frontal"),
      view = c("lateral", "lateral"),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2()
      )
    )
    core <- data.frame(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      display = c("frontal", "frontal")
    )

    legacy <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        palette = NULL,
        core = core,
        sf = sf_geom,
        vertices = NULL
      ),
      class = "ggseg_atlas"
    )

    result <- as_ggseg_atlas(legacy)

    expect_s3_class(result, "ggseg_atlas")
    expect_s3_class(atlas_data(result), "ggseg_atlas_data")
    expect_identical(atlas_name(result), "legacy")
  })

  it("returns unchanged if already has proper data structure", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    result <- as_ggseg_atlas(atlas)
    expect_identical(result, atlas)
  })

  it("errors for unrecognized ggseg_atlas structure", {
    bad_atlas <- structure(
      list(atlas = "bad", type = "cortical"),
      class = "ggseg_atlas"
    )

    expect_error(as_ggseg_atlas(bad_atlas), "unrecognized structure")
  })
})


describe("as_ggseg_atlas.brain_atlas (legacy auto-conversion)", {
  it("auto-converts old brain_atlas with proper data to ggseg_atlas", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    old_atlas <- structure(
      list(
        atlas = "old",
        type = "cortical",
        palette = NULL,
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      class = c("cortical_atlas", "brain_atlas", "list")
    )

    lifecycle::expect_deprecated(
      result <- as_ggseg_atlas(old_atlas)
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_identical(atlas_name(result), "old")
  })

  it("auto-converts old brain_atlas with sf-in-data to ggseg_atlas", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      display = c("frontal", "frontal"),
      view = c("lateral", "lateral"),
      colour = c("#FF0000", "#00FF00"),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2()
      )
    )

    old_atlas <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        data = sf_geom
      ),
      class = "brain_atlas"
    )

    lifecycle::expect_deprecated(
      result <- as_ggseg_atlas(old_atlas)
    )

    expect_s3_class(result, "ggseg_atlas")
    expect_false(is.null(atlas_core(result)))
    expect_s3_class(atlas_data(result), "ggseg_atlas_data")
  })
})


describe("as_ggseg_atlas.list", {
  it("converts legacy list with separate sf field", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(
        make_polygon()
      )
    )
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )

    legacy_list <- list(
      atlas = "legacy",
      type = "cortical",
      palette = NULL,
      core = core,
      sf = sf_geom,
      vertices = NULL
    )

    result <- as_ggseg_atlas(legacy_list)

    expect_s3_class(result, "ggseg_atlas")
    expect_s3_class(atlas_data(result), "ggseg_atlas_data")
  })
})


describe("convert_legacy_brain_data", {
  it("errors for non-brain_atlas input", {
    expect_error(
      convert_legacy_brain_data(list()),
      "must be a.*brain_atlas.*ggseg_atlas"
    )
  })

  it("returns atlas unchanged if already has core", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)

    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )

    result <- convert_legacy_brain_data(atlas)
    expect_s3_class(result, "ggseg_atlas")
  })

  it("converts legacy atlas without core", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      display = c("frontal", "frontal"),
      view = c("lateral", "lateral"),
      colour = c("#FF0000", "#00FF00"),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2()
      )
    )

    legacy <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        data = sf_geom
      ),
      class = "brain_atlas"
    )

    result <- convert_legacy_brain_data(legacy)

    expect_s3_class(result, "ggseg_atlas")
    expect_false(is.null(atlas_core(result)))
    expect_s3_class(atlas_data(result), "ggseg_atlas_data")
    expect_identical(atlas_name(result), "legacy")
  })

  it("renames side column to view", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      hemi = c("left", "right"),
      region = c("frontal", "frontal"),
      label = c("lh_frontal", "rh_frontal"),
      display = c("frontal", "frontal"),
      side = c("lateral", "lateral"),
      geometry = sf::st_sfc(
        make_polygon(),
        make_polygon2()
      )
    )

    legacy <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        data = sf_geom
      ),
      class = "brain_atlas"
    )

    result <- convert_legacy_brain_data(legacy)

    expect_s3_class(result, "ggseg_atlas")
    expect_true("view" %in% names(atlas_geom(result)))
  })

  it("handles legacy atlas without colour column", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(
        make_polygon()
      )
    )

    legacy <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        data = sf_geom
      ),
      class = "brain_atlas"
    )

    result <- convert_legacy_brain_data(legacy)

    expect_s3_class(result, "ggseg_atlas")
    expect_null(atlas_palette(result))
  })
})


describe("as_brain_atlas (deprecated)", {
  it("warns and delegates to as_ggseg_atlas", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    vertices <- data.frame(label = "lh_frontal")
    vertices$vertices <- list(1L:3L)
    atlas <- ggseg_atlas(
      atlas = "test",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    )
    lifecycle::expect_deprecated(
      result <- as_brain_atlas(atlas)
    )
    expect_s3_class(result, "ggseg_atlas")
  })
})


describe("as_ggseg_atlas.brain_atlas legacy paths", {
  it("converts brain_atlas with core and data.frame data", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    old_atlas <- structure(
      list(
        atlas = "old",
        type = "cortical",
        core = data.frame(
          hemi = "left",
          region = "frontal",
          label = "lh_frontal",
          display = "frontal"
        ),
        data = sf_geom
      ),
      class = "brain_atlas"
    )
    lifecycle::expect_deprecated(
      result <- as_ggseg_atlas(old_atlas)
    )
    expect_s3_class(result, "ggseg_atlas")
  })

  it("converts brain_atlas with separate sf field", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(make_polygon())
    )
    old_atlas <- structure(
      list(
        atlas = "old",
        type = "cortical",
        core = data.frame(
          hemi = "left",
          region = "frontal",
          label = "lh_frontal",
          display = "frontal"
        ),
        sf = sf_geom,
        vertices = NULL,
        meshes = NULL
      ),
      class = "brain_atlas"
    )
    lifecycle::expect_deprecated(
      result <- as_ggseg_atlas(old_atlas)
    )
    expect_s3_class(result, "ggseg_atlas")
    expect_s3_class(atlas_data(result), "ggseg_atlas_data")
  })

  it("errors for unrecognized brain_atlas structure", {
    old_atlas <- structure(
      list(atlas = "bad", type = "cortical"),
      class = "brain_atlas"
    )
    lifecycle::expect_deprecated(
      expect_error(as_ggseg_atlas(old_atlas), "unrecognized structure")
    )
  })
})


describe("as_ggseg_atlas.ggseg3d_atlas", {
  it("converts ggseg3d atlas with deprecation warning", {
    mock_3d <- data.frame(
      atlas = "test_3d",
      hemi = "left",
      surf = "inflated"
    )
    region_data <- data.frame(
      label = "lh_frontal",
      region = "frontal",
      colour = "#FF0000"
    )
    region_data$mesh <- list(NULL)
    region_data$vertices <- list(1L:3L)
    mock_3d$ggseg_3d <- list(region_data)
    class(mock_3d) <- c("ggseg3d_atlas", "data.frame")

    expect_message(
      lifecycle::expect_deprecated(
        result <- as_ggseg_atlas(mock_3d)
      ),
      "Using existing vertex indices from 3D atlas"
    )
    expect_s3_class(result, "ggseg_atlas")
  })
})


describe("legacy core label de-duplication", {
  it("collapses alias rows instead of aborting, and warns", {
    vertices <- data.frame(label = "Left-Thalamus")
    vertices$vertices <- list(1L:3L)
    legacy <- structure(
      list(
        atlas = "aliased",
        type = "cortical",
        palette = NULL,
        core = data.frame(
          hemi = c("left", "left"),
          region = c("thalamus", "thalamus proper"),
          label = c("Left-Thalamus", "Left-Thalamus"),
          display = c("Thalamus", "Thalamus Proper")
        ),
        vertices = vertices
      ),
      class = c("brain_atlas", "list")
    )

    expect_warning(
      atlas <- withCallingHandlers(
        as_ggseg_atlas(legacy),
        lifecycle_warning_deprecated = function(w) {
          invokeRestart("muffleWarning")
        }
      ),
      class = "ggseg.formats_collapsed_duplicate_labels"
    )
    expect_identical(nrow(atlas_core(atlas)), 1L)
    expect_identical(atlas_core(atlas)$label, "Left-Thalamus")
    expect_true(is_ggseg_atlas(atlas))
  })

  it("leaves a unique core untouched", {
    core <- data.frame(
      hemi = "left",
      region = "frontal",
      label = "lh_frontal",
      display = "frontal"
    )
    expect_identical(dedupe_legacy_core_labels(core, "clean"), core)
  })

  it("passes through objects without a label column", {
    expect_null(dedupe_legacy_core_labels(NULL))
    expect_identical(
      dedupe_legacy_core_labels(data.frame(a = 1)),
      data.frame(a = 1)
    )
  })
})

describe("as_ggseg_atlas() at a package boundary", {
  it("returns a current atlas untouched", {
    expect_identical(as_ggseg_atlas(dk()), dk())
  })

  it("upgrades a legacy list atlas", {
    out <- as_ggseg_atlas(legacy_list_atlas(dk()))
    expect_true(S7::S7_inherits(out))
    expect_true(atlas_schema_is_current(out))
  })

  it("upgrades an atlas on an older schema", {
    stale <- dk()
    S7::prop(stale, "schema") <- atlas_schema_version() - 1L
    expect_true(atlas_schema_is_current(as_ggseg_atlas(stale)))
  })

  it("carries the atlas across unchanged", {
    # The boundary must not alter what it lets through.
    original <- dk()
    out <- as_ggseg_atlas(legacy_list_atlas(original))
    expect_identical(
      as.data.frame(atlas_core(out)),
      as.data.frame(atlas_core(original))
    )
    expect_identical(atlas_palette(out), atlas_palette(original))
    expect_identical(atlas_geom(out), atlas_geom(original))
  })

  it("blames the caller's argument for a non-atlas", {
    takes_an_atlas <- function(brain) as_ggseg_atlas(brain)
    expect_error(
      takes_an_atlas(42),
      class = "ggseg.formats_not_atlas"
    )
    expect_error(takes_an_atlas(42), "brain")
  })

  it("reports an invalid atlas with the defect as the cause", {
    broken <- legacy_list_atlas(dk())
    broken$core$label <- NULL
    expect_error(
      as_ggseg_atlas(broken),
      class = "ggseg.formats_invalid_atlas"
    )
  })

  it("is silent on the way through", {
    # A boundary that chatters is a boundary people route around.
    expect_silent(as_ggseg_atlas(legacy_list_atlas(dk())))
  })

  it("still deprecation-warns for a pre-2.0 brain_atlas", {
    # The one thing the upgrade does not swallow: `brain_atlas` predates the
    # current class entirely, so the warning is worth hearing.
    old <- structure(
      as.list(dk()),
      class = c("cortical_atlas", "brain_atlas", "list")
    )
    expect_warning(as_ggseg_atlas(old), class = "lifecycle_warning_deprecated")
  })

  it("works for every bundled atlas, in both representations", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_true(atlas_schema_is_current(as_ggseg_atlas(atlas)))
      expect_true(atlas_schema_is_current(as_ggseg_atlas(legacy_list_atlas(
        atlas
      ))))
    }
  })
})
