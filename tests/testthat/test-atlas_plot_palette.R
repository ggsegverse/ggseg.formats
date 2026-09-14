uniform_palette <- function(atlas, colour = "#000000") {
  stats::setNames(rep(colour, nrow(atlas$core)), atlas$core$label)
}

describe("is_context_label()", {
  it("treats labels absent from core as context", {
    expect_identical(
      is_context_label(c("a", "b"), core_labels = "a"),
      c(FALSE, TRUE)
    )
  })

  it("treats pipeline backdrop names as context even when they are core", {
    expect_true(all(is_context_label(
      c("cortex", "cortex_", "lh_unknown", "Background", "medial_wall"),
      core_labels = c(
        "cortex",
        "cortex_",
        "lh_unknown",
        "Background",
        "medial_wall"
      )
    )))
  })

  it("does not mistake a region that merely mentions a backdrop word", {
    expect_false(is_context_label(
      "lh_unknown_gyrus",
      core_labels = "lh_unknown_gyrus"
    ))
  })

  it("treats every label as a region when core is unknown", {
    expect_identical(is_context_label(c("a", "b")), c(FALSE, FALSE))
  })
})

describe("palette_is_usable()", {
  it("rejects a missing or empty palette", {
    expect_false(palette_is_usable(NULL, c("a", "b")))
    expect_false(palette_is_usable(character(0), c("a", "b")))
  })

  it("rejects a palette giving every region the same colour", {
    pal <- c(a = "#FF0000", b = "#FF0000", c = "#FF0000")
    expect_false(palette_is_usable(pal, names(pal)))
  })

  it("rejects an all-black palette", {
    pal <- c(a = "#000000", b = "#000000")
    expect_false(palette_is_usable(pal, names(pal)))
  })

  it("ignores case when comparing colours", {
    pal <- c(a = "#ff0000", b = "#FF0000")
    expect_false(palette_is_usable(pal, names(pal)))
  })

  it("accepts a palette whose regions differ", {
    pal <- c(a = "#FF0000", b = "#00FF00")
    expect_true(palette_is_usable(pal, names(pal)))
  })

  it("accepts a dark but varied palette", {
    pal <- c(a = "#010203", b = "#030201")
    expect_true(palette_is_usable(pal, names(pal)))
  })

  it("accepts a single-region palette, which cannot be uniform", {
    expect_true(palette_is_usable(c(a = "#000000"), "a"))
  })

  it("does not let a grey medial wall rescue a uniform palette", {
    pal <- c(a = "#000000", b = "#000000", lh_unknown = "#BEBEBE")
    expect_false(palette_is_usable(pal, names(pal), core_labels = names(pal)))
  })

  it("counts a missing entry as a distinguishing state", {
    pal <- c(a = "#000000")
    expect_true(palette_is_usable(pal, c("a", "b"), core_labels = c("a", "b")))
  })
})

describe("fallback_palette()", {
  it("gives every region its own colour", {
    cols <- fallback_palette(c("a", "b", "c"))
    expect_length(unique(cols[c("a", "b", "c")]), 3L)
    expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", cols)))
  })

  it("keeps context grey", {
    cols <- fallback_palette(c("a", "cortex_", "lh_unknown"), core_labels = "a")
    expect_identical(unname(cols["cortex_"]), context_fill_colour)
    expect_identical(unname(cols["lh_unknown"]), context_fill_colour)
    expect_false(unname(cols["a"]) == context_fill_colour)
  })

  it("is deterministic", {
    expect_identical(fallback_palette(letters), fallback_palette(letters))
  })
})

describe("atlas_plot_palette()", {
  it("errors on a non-atlas", {
    expect_error(atlas_plot_palette(list()), "ggseg_atlas")
  })

  it("returns a usable palette untouched", {
    expect_identical(atlas_plot_palette(dk()), atlas_palette(dk()))
    expect_identical(atlas_plot_palette(aseg()), atlas_palette(aseg()))
  })

  it("falls back with a warning naming the atlas for a uniform palette", {
    a <- suppressWarnings(set_atlas_palette(
      dk(),
      uniform_palette(dk(), "#FF0000")
    ))
    expect_warning(atlas_plot_palette(a), "dk")
    cols <- suppressWarnings(atlas_plot_palette(a))
    expect_gt(length(unique(cols[a$core$label])), 1L)
  })

  it("falls back for an all-black palette", {
    a <- suppressWarnings(set_atlas_palette(dk(), uniform_palette(dk())))
    cols <- suppressWarnings(atlas_plot_palette(a))
    expect_false(any(cols[a$core$label] == "#000000"))
  })

  it("keeps context grey when falling back", {
    a <- suppressWarnings(set_atlas_palette(aseg(), uniform_palette(aseg())))
    cols <- suppressWarnings(atlas_plot_palette(a))
    context <- setdiff(names(cols), a$core$label)
    expect_gt(length(context), 0L)
    expect_true(all(cols[context] == context_fill_colour))
  })

  it("keeps a core medial wall grey when falling back", {
    a <- aseg()
    extra <- a$core[1, , drop = FALSE]
    extra$region <- "cortex"
    extra$label <- "cortex_"
    a$core <- rbind(a$core, extra)
    a <- suppressWarnings(set_atlas_palette(a, uniform_palette(a)))
    cols <- suppressWarnings(atlas_plot_palette(a))
    expect_identical(unname(cols["cortex_"]), context_fill_colour)
  })

  it("falls back silently when the atlas carries no palette at all", {
    a <- dk()
    a$palette <- NULL
    cols <- expect_no_warning(atlas_plot_palette(a))
    expect_gt(length(unique(cols[a$core$label])), 1L)
  })
})

describe("plot.ggseg_atlas() with an unusable palette", {
  it("warns and draws distinguishable colours", {
    local_null_pdf()
    a <- suppressWarnings(set_atlas_palette(dk(), uniform_palette(dk())))
    expect_warning(plot(a), "usable colour palette")
  })

  it("leaves a well-formed palette alone", {
    local_null_pdf()
    expect_no_warning(plot(dk()))
  })
})
