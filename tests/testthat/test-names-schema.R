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
  suppressWarnings(ggseg_atlas(
    atlas = name,
    type = "cortical",
    core = parts$core,
    data = ggseg_data_cortical(vertices = parts$vertices)
  ))
}

describe("atlas_names", {
  it("returns the sorted unique long-form names of a bundled atlas", {
    result <- atlas_names(dk())
    expect_type(result, "character")
    expect_identical(result, sort(unique(dk()$core$names)))
    expect_true("banks of superior temporal sulcus" %in% result)
  })

  it("works for every bundled atlas", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_gt(length(atlas_names(atlas)), 0)
    }
  })

  it("returns an empty vector when the atlas carries no names column", {
    expect_identical(atlas_names(atlas_without_names()), character(0))
  })

  it("has a data.frame method", {
    df <- data.frame(names = c("b", "a", NA, "a"))
    expect_identical(atlas_names(df), c("a", "b"))
  })
})

describe("core names validation", {
  it("warns once when core has no names column", {
    parts <- core_without_names()
    expect_warning(
      ggseg_atlas(
        atlas = "warns-once",
        type = "cortical",
        core = parts$core,
        data = ggseg_data_cortical(vertices = parts$vertices)
      ),
      class = "ggseg.formats_missing_names"
    )
  })

  it("does not error when core has no names column", {
    expect_s3_class(atlas_without_names(), "ggseg_atlas")
  })

  it("errors when names is not a character vector", {
    parts <- core_without_names()
    parts$core$names <- 1L
    expect_error(
      ggseg_atlas(
        atlas = "bad-names",
        type = "cortical",
        core = parts$core,
        data = ggseg_data_cortical(vertices = parts$vertices)
      ),
      "must be a character vector"
    )
  })

  it("accepts a character names column silently", {
    parts <- core_without_names()
    parts$core$names <- "frontal lobe"
    expect_no_warning(
      ggseg_atlas(
        atlas = "good-names",
        type = "cortical",
        core = parts$core,
        data = ggseg_data_cortical(vertices = parts$vertices)
      )
    )
  })
})

describe("core label uniqueness", {
  it("warns when two core rows share a label", {
    core <- data.frame(
      hemi = c("left", "left"),
      region = c("thalamus", "thalamus proper"),
      label = c("Left-Thalamus", "Left-Thalamus"),
      names = c("Thalamus", "Thalamus Proper")
    )
    vertices <- data.frame(label = "Left-Thalamus")
    vertices$vertices <- list(1L:3L)
    expect_warning(
      ggseg_atlas(
        atlas = "dupe-labels",
        type = "cortical",
        core = core,
        data = ggseg_data_cortical(vertices = vertices)
      ),
      class = "ggseg.formats_duplicate_labels"
    )
  })

  it("does not error on duplicate labels", {
    core <- data.frame(
      hemi = c("left", "left"),
      region = c("a", "b"),
      label = c("x", "x"),
      names = c("a", "b")
    )
    vertices <- data.frame(label = "x")
    vertices$vertices <- list(1L:3L)
    atlas <- suppressWarnings(ggseg_atlas(
      atlas = "dupe-no-error",
      type = "cortical",
      core = core,
      data = ggseg_data_cortical(vertices = vertices)
    ))
    expect_s3_class(atlas, "ggseg_atlas")
  })

  it("gives every bundled atlas unique core labels", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_false(anyDuplicated(atlas$core$label) > 0)
      expect_identical(nrow(atlas$core), length(atlas_labels(atlas)))
    }
  })
})

describe("bundled atlas schema", {
  it("gives every bundled atlas a character names column", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      expect_true("names" %in% names(atlas$core))
      expect_type(atlas$core$names, "character")
      expect_false(anyNA(atlas$core$names))
    }
  })

  it("keeps tracula labels and palette keys as FreeSurfer emits them", {
    expected <- cran_0_0_4_tracula_labels()
    expect_identical(atlas_labels(tracula()), expected)
    expect_identical(sort(names(atlas_palette(tracula()))), expected)
  })

  it("keeps the suffix-free tracula identifier in label_short", {
    core <- tracula()$core
    expect_true("label_short" %in% names(core))
    expect_identical(core$label, paste0(core$label_short, ".bbr.prep"))
  })
})

describe("names is preserved by the atlas verbs", {
  has_names <- function(atlas) "names" %in% names(atlas$core)

  it("survives the region verbs", {
    expect_true(has_names(atlas_region_remove(aseg(), "vessel")))
    expect_true(has_names(atlas_region_keep(aseg(), "thalamus")))
    expect_true(has_names(atlas_region_contextual(aseg(), "vessel")))
    expect_true(has_names(atlas_region_rename(aseg(), "thalamus", "thal")))
    expect_true(has_names(atlas_context_remove(aseg())))
  })

  it("survives the view verbs", {
    views <- atlas_views(aseg())
    expect_true(has_names(atlas_view_keep(aseg(), views[1])))
    expect_true(has_names(atlas_view_remove(aseg(), views[1])))
    expect_true(has_names(atlas_view_remove_region(aseg(), "vessel")))
    expect_true(has_names(atlas_view_remove_small(aseg(), min_area = 1)))
    expect_true(has_names(atlas_view_select(aseg(), threshold = 0.5)))
    expect_true(has_names(atlas_view_gather(aseg())))
    expect_true(has_names(atlas_view_reorder(aseg(), rev(views))))
  })

  it("survives atlas_structure_reorder()", {
    labels <- atlas_labels(aseg())
    expect_true(
      has_names(atlas_structure_reorder(aseg(), labels[1], .after = labels[2]))
    )
  })

  it("fills names on the region a boolean op adds", {
    core <- data.frame(
      hemi = c(NA, NA),
      region = c("a", "b"),
      label = c("a", "b"),
      names = c("alpha", "beta")
    )
    expect_identical(
      add_op_region_meta(
        core,
        c(a = "#aaa", b = "#bbb"),
        "merged",
        "#FF0000"
      )$core$names,
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

describe("names is the curated display name, not the legacy key", {
  # The two were briefly the same column. Keeping them apart is a deliberate
  # decision, so assert the specific values that would regress if `names` were
  # ever repurposed as the migration table again.
  it("spells out the aseg regions 0.0.4 abbreviated", {
    core <- aseg()$core
    name_of <- function(label) core$names[core$label == label]

    expect_identical(name_of("Left-VentralDC"), "ventral diencephalon")
    expect_identical(name_of("Left-Accumbens-area"), "accumbens")
    expect_identical(name_of("CC_Posterior"), "corpus callosum posterior")
    expect_identical(name_of("CC_Mid_Anterior"), "corpus callosum mid-anterior")
  })

  it("does not reuse the 0.0.4 region strings as aseg names", {
    legacy <- names(legacy_region_map(aseg()))
    expect_false(any(
      c("ventraldc", "accumbens area", "cc posterior") %in%
        atlas_names(aseg())
    ))
    expect_false(setequal(atlas_names(aseg()), legacy))
  })

  it("spells out the tracula tracts 0.0.4 abbreviated", {
    core <- tracula()$core
    name_of <- function(label) core$names[core$label == label]

    expect_match(
      name_of("lh.slf1.bbr.prep"),
      "superior longitudinal fasciculus I",
      fixed = TRUE
    )
    expect_identical(name_of("cc.genu.bbr.prep"), "corpus callosum genu")
  })

  it("does not reuse the 0.0.4 region strings as tracula names", {
    expect_false(any(c("SLF I", "CC genu") %in% atlas_names(tracula())))
    expect_false(setequal(
      atlas_names(tracula()),
      names(
        legacy_region_map(tracula())
      )
    ))
  })

  it("keeps every bundled atlas's names readable", {
    for (atlas in list(dk(), aseg(), tracula(), suit())) {
      nms <- atlas_names(atlas)
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
