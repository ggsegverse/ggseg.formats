describe("atlas_structure_reorder()", {
  drawn <- function(atlas) ggseg.formats::atlas_geom(atlas)$label

  it("moves a structure after another", {
    a <- aseg()
    before <- drawn(a)
    out <- atlas_structure_reorder(
      a,
      before[2],
      .after = before[5]
    )

    expect_identical(
      drawn(out),
      c(before[c(1, 3, 4, 5, 2)], before[-(1:5)])
    )
  })

  it("moves a structure before another", {
    a <- aseg()
    before <- drawn(a)
    out <- atlas_structure_reorder(a, before[5], .before = before[2])

    expect_identical(
      drawn(out),
      c(before[c(1, 5, 2, 3, 4)], before[-(1:5)])
    )
  })

  it("moves to the front when given no anchor, as relocate() does", {
    a <- aseg()
    before <- drawn(a)
    out <- atlas_structure_reorder(a, before[4])

    expect_identical(drawn(out), c(before[4], before[-4]))
  })

  it("keeps the order the structures were named in", {
    a <- aseg()
    before <- drawn(a)
    out <- atlas_structure_reorder(a, before[c(5, 2)])

    expect_identical(drawn(out)[1:2], before[c(5, 2)])
  })

  it("moves both hemispheres when given a region", {
    a <- aseg()
    region <- unique(atlas_regions(a))[1]
    out <- atlas_structure_reorder(a, region, match_on = "region")

    moved <- a$core$label[a$core$region == region]
    expect_setequal(utils::head(drawn(out), length(moved)), moved)
  })

  it("leaves core, palette and type alone", {
    a <- aseg()
    out <- atlas_structure_reorder(a, drawn(a)[2], .after = drawn(a)[4])

    expect_identical(out$core, a$core)
    expect_identical(atlas_palette(out), atlas_palette(a))
    expect_identical(atlas_type(out), atlas_type(a))
    expect_setequal(drawn(out), drawn(a))
  })

  it("moves every row a structure owns, when views are not gathered", {
    skip_if_not_installed("sf")
    # Ungathered geometry holds a row per structure and view, so a label can
    # own several rows and all of them have to travel together.
    geom <- sf::st_sf(
      label = c("a", "b", "a", "b"),
      view = c("lateral", "lateral", "medial", "medial"),
      geometry = sf::st_sfc(
        sf::st_point(c(0, 0)),
        sf::st_point(c(1, 0)),
        sf::st_point(c(0, 1)),
        sf::st_point(c(1, 1))
      )
    )
    atlas <- ggseg_atlas(
      atlas = "demo",
      type = "cortical",
      palette = c(a = "#f00", b = "#00f"),
      core = data.frame(
        hemi = c("left", "left"),
        region = c("a", "b"),
        label = c("a", "b"),
        names = c("a", "b")
      ),
      data = ggseg_data_cortical(geom = geom, vertices = NULL)
    )

    out <- atlas_structure_reorder(atlas, "a", .after = "b")

    expect_identical(atlas_geom(out)$label, c("b", "b", "a", "a"))
    expect_identical(
      atlas_geom(out)$view,
      c("lateral", "medial", "lateral", "medial")
    )
  })

  it("errors when a structure has no geometry", {
    a <- aseg()
    ghost <- a$core[1, ]
    ghost$label <- "ghost"
    ghost$region <- "ghost"
    a$core <- rbind(a$core, ghost)
    expect_snapshot(atlas_structure_reorder(a, "ghost"), error = TRUE)
  })

  it("errors on an unknown structure", {
    expect_snapshot(
      atlas_structure_reorder(aseg(), "notastructure"),
      error = TRUE
    )
  })

  it("errors when given both anchors", {
    a <- aseg()
    expect_snapshot(
      atlas_structure_reorder(
        a,
        drawn(a)[1],
        .before = drawn(a)[2],
        .after = drawn(a)[3]
      ),
      error = TRUE
    )
  })

  it("errors when the anchor is one of the structures moved", {
    a <- aseg()
    expect_snapshot(
      atlas_structure_reorder(a, drawn(a)[1], .after = drawn(a)[1]),
      error = TRUE
    )
  })

  it("errors on a non-atlas", {
    expect_snapshot(
      atlas_structure_reorder(list(), "x"),
      error = TRUE
    )
  })
})
