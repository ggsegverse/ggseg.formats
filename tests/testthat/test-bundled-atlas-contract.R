# The bundled atlases are data, so no code change can break them and no test
# that only inspects their shape will notice when the data itself is wrong.
# These contracts pin the properties a consumer relies on, derived from the
# atlas rather than hard-coded, so they survive region additions, renames and
# row reordering while still failing on a mis-keyed or mirrored atlas.

bundled_atlases <- function() {
  list(dk = dk(), aseg = aseg(), suit = suit(), tracula = tracula())
}

label_side <- function(labels) {
  ifelse(
    grepl("^(lh|left|l)[-_.]", labels, ignore.case = TRUE),
    "left",
    ifelse(
      grepl("^(rh|right|r)[-_.]", labels, ignore.case = TRUE),
      "right",
      NA_character_
    )
  )
}

describe("bundled atlas laterality", {
  it("assigns every side-marked label to the hemisphere its label names", {
    for (nm in names(bundled_atlases())) {
      atlas <- bundled_atlases()[[nm]]
      labels <- atlas_labels(atlas)
      sides <- label_side(labels)
      marked <- !is.na(sides)
      expect_identical(
        atlas_hemi(atlas)[marked],
        sides[marked],
        info = nm
      )
    }
  })

  it("never assigns an unmarked label to a lateral hemisphere", {
    for (nm in names(bundled_atlases())) {
      atlas <- bundled_atlases()[[nm]]
      unmarked <- is.na(label_side(atlas_labels(atlas)))
      expect_false(
        any(atlas_hemi(atlas)[unmarked] %in% c("left", "right")),
        info = nm
      )
    }
  })

  it("uses only the closed hemisphere vocabulary", {
    for (nm in names(bundled_atlases())) {
      expect_true(
        all(
          atlas_hemi(bundled_atlases()[[nm]]) %in%
            c("left", "right", "midline", NA_character_)
        ),
        info = nm
      )
    }
  })
})

describe("bundled atlas keys", {
  it("keys every region on a unique, non-missing label", {
    for (nm in names(bundled_atlases())) {
      labels <- atlas_labels(bundled_atlases()[[nm]])
      expect_false(anyNA(labels), info = nm)
      expect_false(any(labels == ""), info = nm)
      expect_identical(anyDuplicated(labels), 0L, info = nm)
    }
  })

  it("names every palette entry after a label the atlas carries", {
    for (nm in names(bundled_atlases())) {
      atlas <- bundled_atlases()[[nm]]
      palette <- atlas_palette(atlas)
      if (is.null(palette) || !length(palette)) {
        next
      }
      expect_true(all(names(palette) %in% atlas_labels(atlas)), info = nm)
    }
  })

  it("draws only labels the atlas owns or declares as context", {
    for (nm in names(bundled_atlases())) {
      atlas <- bundled_atlases()[[nm]]
      geom <- atlas_geom(atlas)
      if (is.null(geom)) {
        next
      }
      expect_identical(
        setdiff(unique(geom$label), atlas_labels(atlas)),
        as.character(atlas_context(atlas)),
        info = nm
      )
    }
  })
})
