cran_0_0_4_tracula_labels <- function() {
  short <- c(
    "acomm",
    "cc.bodyc",
    "cc.bodyp",
    "cc.bodypf",
    "cc.bodypm",
    "cc.bodyt",
    "cc.genu",
    "cc.rostrum",
    "cc.splenium",
    "mcp",
    paste0(
      rep(c("lh", "rh"), each = 16),
      ".",
      c(
        "af",
        "ar",
        "atr",
        "cbd",
        "cbv",
        "cst",
        "emc",
        "fat",
        "fx",
        "ilf",
        "mlf",
        "or",
        "slf1",
        "slf2",
        "slf3",
        "uf"
      )
    )
  )
  sort(paste0(short, ".bbr.prep"))
}

core_without_names <- function() {
  core <- data.frame(
    hemi = "left",
    region = "frontal",
    label = "lh_frontal"
  )
  vertices <- data.frame(label = "lh_frontal")
  vertices$vertices <- list(1L:3L)
  list(core = core, vertices = vertices)
}

atlas_without_names <- function(name = "nameless") {
  parts <- core_without_names()
  suppressMessages(ggseg_atlas(
    atlas = name,
    type = "cortical",
    core = parts$core,
    data = ggseg_data_cortical(vertices = parts$vertices)
  ))
}

describe("atlas_names", {
  it("is deprecated in favour of atlas_display()", {
    expect_snapshot(x <- atlas_names(dk()))
  })

  it("still returns what atlas_display() returns", {
    expect_warning(
      got <- atlas_names(dk()),
      class = "lifecycle_warning_deprecated"
    )
    expect_identical(got, atlas_display(dk()))
  })
})

describe("atlas_display", {
  it("returns the display column of a bundled atlas in core row order", {
    result <- atlas_display(dk())
    expect_type(result, "character")
    expect_identical(result, dk()$core$display)
    expect_true("banks of superior temporal sulcus" %in% result)
  })

  it("works for every bundled atlas", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_gt(length(atlas_display(atlas)), 0)
    }
  })

  it("returns an empty vector when the atlas carries no display column", {
    expect_identical(atlas_display(atlas_without_names()), character(0))
  })

  it("has a data.frame method", {
    df <- data.frame(display = c("b", "a", NA, "a"))
    expect_identical(atlas_display(df), c("b", "a", NA, "a"))
  })
})

describe("core display validation", {
  it("informs the atlas author once when core has no display column", {
    parts <- core_without_names()
    expect_message(
      ggseg_atlas(
        atlas = "informs-once",
        type = "cortical",
        core = parts$core,
        data = ggseg_data_cortical(vertices = parts$vertices)
      ),
      class = "ggseg.formats_missing_display"
    )
  })

  it("does not warn when core has no display column", {
    parts <- core_without_names()
    expect_no_warning(suppressMessages(
      ggseg_atlas(
        atlas = "no-warning",
        type = "cortical",
        core = parts$core,
        data = ggseg_data_cortical(vertices = parts$vertices)
      )
    ))
  })

  it("does not error when core has no display column", {
    expect_s3_class(atlas_without_names(), "ggseg_atlas")
  })

  it("errors when display is not a character vector", {
    parts <- core_without_names()
    parts$core$display <- 1L
    expect_error(
      ggseg_atlas(
        atlas = "bad-display",
        type = "cortical",
        core = parts$core,
        data = ggseg_data_cortical(vertices = parts$vertices)
      ),
      "must be a character vector"
    )
  })

  it("accepts a character display column silently", {
    parts <- core_without_names()
    parts$core$display <- "frontal lobe"
    expect_no_warning(
      ggseg_atlas(
        atlas = "good-display",
        type = "cortical",
        core = parts$core,
        data = ggseg_data_cortical(vertices = parts$vertices)
      )
    )
  })
})

describe("core label uniqueness", {
  it("errors when two core rows share a label, naming them", {
    core <- data.frame(
      hemi = c("left", "left"),
      region = c("thalamus", "thalamus proper"),
      label = c("Left-Thalamus", "Left-Thalamus"),
      display = c("Thalamus", "Thalamus Proper")
    )
    vertices <- data.frame(label = "Left-Thalamus")
    vertices$vertices <- list(1L:3L)
    expect_error(
      ggseg_atlas(
        atlas = "dupe-labels",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      class = "ggseg.formats_duplicate_labels"
    )
    expect_error(
      ggseg_atlas(
        atlas = "dupe-labels",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      "Left-Thalamus"
    )
  })

  it("errors from the deprecated brain_atlas() wrapper too", {
    core <- data.frame(
      hemi = c("left", "left"),
      region = c("a", "b"),
      label = c("x", "x"),
      display = c("a", "b")
    )
    vertices <- data.frame(label = "x")
    vertices$vertices <- list(1L:3L)
    expect_error(
      suppressWarnings(brain_atlas(
        atlas = "dupe-no-error",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      )),
      class = "ggseg.formats_duplicate_labels"
    )
  })

  it("gives every bundled atlas unique core labels", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_false(anyDuplicated(atlas$core$label) > 0)
      expect_identical(nrow(atlas$core), length(atlas_labels(atlas)))
    }
  })
})

describe("core-column accessor alignment", {
  it("returns one element per core row for every bundled atlas", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      n <- nrow(atlas$core)
      expect_length(atlas_labels(atlas), n)
      expect_length(atlas_regions(atlas), n)
      expect_length(atlas_display(atlas), n)
    }
  })

  it("returns the core columns in core row order", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_identical(atlas_labels(atlas), atlas$core$label)
      expect_identical(atlas_regions(atlas), atlas$core$region)
      expect_identical(atlas_display(atlas), atlas$core$display)
    }
  })

  it("describes the same row across the three accessors", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      i <- seq_len(nrow(atlas$core))
      row_of <- match(atlas_labels(atlas)[i], atlas$core$label)
      expect_identical(row_of, i)
      expect_identical(atlas_regions(atlas)[i], atlas$core$region[row_of])
      expect_identical(atlas_display(atlas)[i], atlas$core$display[row_of])
    }
  })

  it("recovers the old distinct region set through unique()", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      regions <- atlas_regions(atlas)
      distinct <- sort(unique(regions[!is.na(regions)]))
      expect_identical(distinct, sort(unique(atlas$core$region)))
      expect_lt(length(distinct), nrow(atlas$core))
    }
  })
})

describe("bundled atlas schema", {
  it("gives every bundled atlas a character display column", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_true("display" %in% names(atlas$core))
      expect_type(atlas$core$display, "character")
      expect_false(anyNA(atlas$core$display))
    }
  })

  it("keeps tracula labels and palette keys as FreeSurfer emits them", {
    expected <- cran_0_0_4_tracula_labels()
    expect_identical(sort(atlas_labels(tracula())), expected)
    expect_identical(sort(names(atlas_palette(tracula()))), expected)
  })

  it("keeps the suffix-free tracula identifier in label_short", {
    core <- tracula()$core
    expect_true("label_short" %in% names(core))
    expect_identical(core$label, paste0(core$label_short, ".bbr.prep"))
  })
})

describe("display is preserved by the atlas verbs", {
  has_display <- function(atlas) "display" %in% names(atlas$core)

  it("survives the region verbs", {
    expect_true(has_display(atlas_region_remove(aseg(), "vessel")))
    expect_true(has_display(atlas_region_keep(aseg(), "thalamus")))
    expect_true(has_display(atlas_region_contextual(aseg(), "vessel")))
    expect_true(has_display(atlas_region_rename(aseg(), "thalamus", "thal")))
    expect_true(has_display(atlas_context_remove(aseg())))
  })

  it("survives the view verbs", {
    views <- atlas_views(aseg())
    expect_true(has_display(atlas_view_keep(aseg(), views[1])))
    expect_true(has_display(atlas_view_remove(aseg(), views[1])))
    expect_true(has_display(atlas_view_remove_region(aseg(), "vessel")))
    expect_true(has_display(atlas_view_remove_small(aseg(), min_area = 1)))
    expect_true(has_display(atlas_view_select(aseg(), threshold = 0.5)))
    expect_true(has_display(atlas_view_gather(aseg())))
    expect_true(has_display(atlas_view_reorder(aseg(), rev(views))))
  })

  it("survives atlas_structure_reorder()", {
    labels <- atlas_labels(aseg())
    expect_true(
      has_display(atlas_structure_reorder(
        aseg(),
        labels[1],
        .after = labels[2]
      ))
    )
  })

  it("fills display on the region a boolean op adds", {
    core <- data.frame(
      hemi = c(NA, NA),
      region = c("a", "b"),
      label = c("a", "b"),
      display = c("alpha", "beta")
    )
    expect_identical(
      add_op_region_meta(
        core,
        c(a = "#aaa", b = "#bbb"),
        "merged",
        "#FF0000"
      )$core$display,
      c("alpha", "beta", "merged")
    )
  })
})

describe("relabel_atlas", {
  it("re-keys core, palette and every payload slot at once", {
    atlas <- relabel_atlas(aseg(), c("Left-Thalamus" = "Left-Thal"))
    expect_true("Left-Thal" %in% atlas$core$label)
    expect_false("Left-Thalamus" %in% atlas$core$label)
    expect_true("Left-Thal" %in% names(atlas$palette))
    expect_true("Left-Thal" %in% atlas$data$meshes$label)
    expect_true("Left-Thal" %in% atlas$data$geom$label)
  })

  it("leaves labels absent from the mapping alone", {
    atlas <- relabel_atlas(aseg(), c("Left-Thalamus" = "Left-Thal"))
    expect_true("Right-Thalamus" %in% atlas$core$label)
  })

  it("errors on a non-atlas or an unnamed mapping", {
    expect_error(relabel_atlas(list(), c(a = "b")), "must be a")
    expect_error(relabel_atlas(aseg(), "b"), "named character vector")
  })
})

describe("legacy_region_map", {
  it("maps pre-0.1.0 region names onto current region keys", {
    map <- legacy_region_map(tracula())
    expect_identical(map[["SLF I"]], "slf1")
    expect_identical(map[["CC body central"]], "cc bodyc")
    expect_identical(unname(map[["anterior commissure"]]), "acomm")
  })

  it("recovers every pre-0.1.0 region of every bundled atlas", {
    expected <- c(dk = 35L, aseg = 19L, tracula = 26L, suit = 13L)
    actual <- vapply(
      list(dk = dk(), aseg = aseg(), tracula = tracula(), suit = suit()),
      function(a) length(legacy_region_map(a)),
      integer(1)
    )
    expect_identical(actual, expected)
  })

  it("maps dk's long annotation names to the short keys", {
    expect_identical(
      legacy_region_map(dk())[["banks of superior temporal sulcus"]],
      "bankssts"
    )
  })

  it("translates an alias whose core row is gone", {
    map <- legacy_region_map(aseg())
    expect_identical(map[["Thalamus"]], "thalamus")
    expect_identical(map[["Thalamus Proper"]], "thalamus")
  })

  it("maps suit onto itself, since its keys never changed", {
    map <- legacy_region_map(suit())
    expect_identical(unname(map), names(map))
  })

  it("only ever maps onto a key the atlas actually has", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_true(all(unname(legacy_region_map(atlas)) %in% atlas$core$region))
    }
  })

  it("has one entry per old name", {
    map <- legacy_region_map(aseg())
    expect_false(anyDuplicated(names(map)) > 0)
  })

  it("warns and returns nothing for an atlas it records no history for", {
    expect_warning(
      map <- legacy_region_map(atlas_without_names("no-such-atlas")),
      "No pre-0.1.0 region names"
    )
    expect_length(map, 0L)
  })

  it("errors on a non-atlas", {
    expect_error(legacy_region_map(data.frame(x = 1)), "must be a")
  })
})

describe("display is the curated display name, not the legacy key", {
  # The two were briefly the same column. Keeping them apart is a deliberate
  # decision, so assert the specific values that would regress if `display` were
  # ever repurposed as the migration table again.
  it("spells out the aseg regions 0.0.4 abbreviated", {
    core <- aseg()$core
    name_of <- function(label) core$display[core$label == label]

    expect_identical(name_of("Left-VentralDC"), "ventral diencephalon")
    expect_identical(name_of("Left-Accumbens-area"), "accumbens")
    expect_identical(name_of("CC_Posterior"), "corpus callosum posterior")
    expect_identical(name_of("CC_Mid_Anterior"), "corpus callosum mid-anterior")
  })

  it("does not reuse the 0.0.4 region strings as aseg display names", {
    legacy <- names(legacy_region_map(aseg()))
    expect_false(any(
      c("ventraldc", "accumbens area", "cc posterior") %in%
        atlas_display(aseg())
    ))
    expect_false(setequal(atlas_display(aseg()), legacy))
  })

  it("spells out the tracula tracts 0.0.4 abbreviated", {
    core <- tracula()$core
    name_of <- function(label) core$display[core$label == label]

    expect_match(
      name_of("lh.slf1.bbr.prep"),
      "superior longitudinal fasciculus I",
      fixed = TRUE
    )
    expect_identical(name_of("cc.genu.bbr.prep"), "corpus callosum genu")
  })

  it("does not reuse the 0.0.4 region strings as tracula display names", {
    expect_false(any(c("SLF I", "CC genu") %in% atlas_display(tracula())))
    expect_false(setequal(
      atlas_display(tracula()),
      names(
        legacy_region_map(tracula())
      )
    ))
  })

  it("keeps every bundled atlas's display names readable", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      nms <- atlas_display(atlas)
      expect_false(any(grepl("[._]", nms)))
      expect_true(all(nzchar(nms)))
    }
  })
})

describe("legacy region no-match hint", {
  it("names the migration helper when the pattern hits a legacy name", {
    expect_warning(
      atlas_region_remove(tracula(), "SLF I"),
      "legacy_region_map"
    )
  })

  it("reports the current region key alongside the legacy one", {
    expect_warning(
      atlas_region_remove(dk(), "banks of superior temporal sulcus"),
      "bankssts"
    )
  })

  it("omits the hint when the pattern matches no legacy name either", {
    warning_text <- tryCatch(
      atlas_region_remove(dk(), "no-such-region-anywhere"),
      warning = conditionMessage
    )
    expect_no_match(warning_text, "legacy_region_map", fixed = TRUE)
  })
})


aseg_without_names <- function() {
  stripped <- aseg()
  stripped$core$display <- NULL
  suppressMessages(ggseg_atlas(
    atlas = "silent-aseg",
    type = stripped$type,
    core = stripped$core,
    data = stripped$data,
    palette = stripped$palette
  ))
}

describe("a missing display column is silent outside construction", {
  it("says nothing when the atlas is plotted", {
    atlas <- aseg_without_names()
    expect_no_condition(
      print(plot(atlas)),
      class = "ggseg.formats_missing_display"
    )
    expect_no_warning(suppressMessages(print(plot(atlas))))
  })

  it("says nothing through the core-column accessors", {
    atlas <- atlas_without_names("silent-accessors")
    expect_no_message(expect_no_warning({
      atlas_regions(atlas)
      atlas_labels(atlas)
      atlas_display(atlas)
      atlas_palette(atlas)
    }))
  })

  it("returns character(0) from atlas_display()", {
    expect_identical(atlas_display(atlas_without_names()), character(0))
  })

  it("says nothing through the class predicates", {
    atlas <- atlas_without_names("silent-predicates")
    expect_no_message(expect_no_warning({
      expect_true(is_ggseg_atlas(atlas))
      expect_true(is_cortical_atlas(atlas))
      expect_false(is_subcortical_atlas(atlas))
    }))
  })

  it("stays silent on a predicate for an atlas with duplicate core labels", {
    # Such an atlas can no longer be constructed, but a published one may
    # already carry alias rows. The predicate must report FALSE without
    # signalling, so renderers can branch on it.
    atlas <- atlas_without_names("dupes-predicate")
    atlas$core <- rbind(atlas$core, atlas$core[1, , drop = FALSE])
    expect_no_message(expect_no_warning(expect_false(is_ggseg_atlas(atlas))))
  })

  it("still reports a structurally invalid atlas as FALSE, silently", {
    broken <- atlas_without_names("silent-invalid")
    broken$core <- data.frame(hemi = "left")
    expect_no_message(expect_no_warning(expect_false(is_ggseg_atlas(broken))))
  })

  it("keeps erroring on a strictly invalid atlas", {
    parts <- core_without_names()
    parts$core$label <- NULL
    expect_error(
      ggseg_atlas(
        atlas = "strictly-invalid",
        type = "cortical",
        core = parts$core,
        data = ggseg_data_cortical(vertices = parts$vertices)
      ),
      "must contain columns"
    )
  })

  it("errors on duplicate core labels at construction", {
    core <- data.frame(
      hemi = c("left", "left"),
      region = c("a", "b"),
      label = c("x", "x")
    )
    vertices <- data.frame(label = "x")
    vertices$vertices <- list(1L:3L)
    expect_error(
      suppressMessages(ggseg_atlas(
        atlas = "errors-on-dupes",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      )),
      class = "ggseg.formats_duplicate_labels"
    )
  })
})


describe("legacy conversion back-fills display", {
  it("copies the legacy long-form region into display", {
    skip_if_not_installed("sf")
    sf_geom <- sf::st_sf(
      label = "lh_frontal",
      view = "lateral",
      geometry = sf::st_sfc(sf::st_polygon(list(
        cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0))
      )))
    )
    legacy <- structure(
      list(
        atlas = "legacy",
        type = "cortical",
        palette = c(lh_frontal = "#FF0000"),
        core = data.frame(
          hemi = "left",
          region = "superior frontal gyrus",
          label = "lh_frontal"
        ),
        data = ggseg_data_cortical(geom = sf_geom)
      ),
      class = "brain_atlas"
    )
    result <- suppressMessages(
      convert_legacy_brain_atlas(atlas_2d = legacy)
    )
    expect_identical(atlas_display(result), "superior frontal gyrus")
  })
})
