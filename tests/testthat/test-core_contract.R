describe("atlas_region_semantics()", {
  it("reports a shared region name as shared", {
    expect_identical(atlas_region_semantics(dk()), "shared")
  })

  it("reports a per-hemisphere naming as such", {
    # The source named its parcels per hemisphere, so no name is shared and
    # grouping by region aggregates nothing. Not a defect to strip away.
    atlas <- dk()
    atlas$core$region <- paste0(
      substr(atlas$core$hemi, 1, 1),
      "_",
      atlas$core$region
    )
    expect_identical(atlas_region_semantics(atlas), "per-hemisphere")
  })

  it("says the question does not arise for a one-sided atlas", {
    # With one side there are no two hemispheres for a name to be shared
    # between, so neither convention applies.
    atlas <- dk()
    atlas$core$hemi <- "left"
    expect_identical(atlas_region_semantics(atlas), "unilateral")
  })

  it("is computed from core, so it cannot disagree with it", {
    atlas <- dk()
    expect_identical(atlas_region_semantics(atlas), "shared")
    atlas$core$region <- atlas$core$label
    expect_identical(atlas_region_semantics(atlas), "per-hemisphere")
  })
})


describe("atlas_context()", {
  it("returns the labels drawn but not held as regions", {
    ctx <- atlas_context(aseg())
    expect_true(length(ctx) > 0)
    expect_false(any(ctx %in% aseg()$core$label))
  })

  it("finds a cortical atlas's medial wall", {
    # `dk` draws the unlabelled medial wall as backdrop, under a different
    # spelling from the subcortical silhouette -- which is the reason this
    # accessor exists rather than every caller matching on a name.
    expect_identical(atlas_context(dk()), c("lh_unknown", "rh_unknown"))
  })

  it("is empty when every drawn label is a region", {
    atlas <- dk()
    atlas <- atlas_context_remove(atlas)
    expect_length(atlas_context(atlas), 0L)
  })
})


describe("strip_hemi_affix()", {
  it("takes off exactly one affix, keeping the source's own", {
    # Glasser publishes `L_V1_ROI`; the label is `lh_L_V1_ROI` and the
    # display name is the published one, not `V1_ROI`.
    expect_identical(strip_hemi_affix("lh_L_V1_ROI"), "L_V1_ROI")
    expect_identical(
      strip_hemi_affix("left_Cerebelum_Crus1_L"),
      "Cerebelum_Crus1"
    )
  })

  it("takes a trailing affix off too", {
    expect_identical(strip_hemi_affix("G_Frontal_Sup-1-L"), "G_Frontal_Sup-1")
    expect_identical(strip_hemi_affix("Precentral_L"), "Precentral")
  })

  it("never strips a name to nothing", {
    expect_identical(strip_hemi_affix("Left"), "Left")
  })
})


describe("migrate_atlas_display()", {
  it("fills an absent column with the source name from the label", {
    # Verified against every atlas in the library that already carries the
    # column: 1996 rows, no disagreement.
    atlas <- dk()
    atlas$core$display <- NULL

    expect_identical(
      atlas_display(migrate_atlas_display(atlas)),
      strip_hemi_affix(as.character(atlas$core$label))
    )
  })

  it("never overwrites a curated display name", {
    # `dk` publishes "banks of superior temporal sulcus" for `lh_bankssts`.
    # That is editorial knowledge, not something a label can be stripped
    # down to, and filling the column must never cost it.
    atlas <- dk()
    curated <- atlas_display(atlas)[1]
    expect_identical(curated, "banks of superior temporal sulcus")
    expect_identical(atlas_display(migrate_atlas_display(atlas))[1], curated)
  })

  it("leaves an atlas that already carries display alone", {
    atlas <- dk()
    atlas$core$display[1] <- "something the source said"
    expect_identical(
      atlas_display(migrate_atlas_display(atlas))[1],
      "something the source said"
    )
  })

  it("replaces it when asked", {
    atlas <- dk()
    atlas$core$display[1] <- "wrong"
    expect_false(
      atlas_display(migrate_atlas_display(atlas, overwrite = TRUE))[1] ==
        "wrong"
    )
  })
})


describe("migrate_atlas_hemi()", {
  it("maps the legacy spellings onto the vocabulary", {
    atlas <- dk()
    atlas$core$hemi[1] <- "middle"
    atlas$core$hemi[2] <- "vermis"

    expect_setequal(
      unique(migrate_atlas_hemi(atlas)$core$hemi),
      c("left", "right", "midline")
    )
  })

  it("leaves a conforming atlas alone", {
    atlas <- dk()
    expect_identical(migrate_atlas_hemi(atlas)$core$hemi, atlas$core$hemi)
  })

  it("repairs an atlas that can no longer be constructed", {
    # `ggsegAal`'s `.aal3_cerebellum` carries "middle", so every verb that
    # validates refuses it -- including the display migration. Repairing
    # `core` directly is the only way in.
    atlas <- dk()
    atlas$core$hemi[1] <- "middle"
    expect_error(
      assert_ggseg_atlas(atlas),
      class = "ggseg.formats_invalid_atlas"
    )
    expect_no_error(assert_ggseg_atlas(migrate_atlas_hemi(atlas)))
  })

  it("keeps NA, which means no side applies", {
    atlas <- dk()
    atlas$core$hemi[1] <- NA_character_
    expect_true(is.na(migrate_atlas_hemi(atlas)$core$hemi[1]))
  })
})
