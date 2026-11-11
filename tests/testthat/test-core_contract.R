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


describe("atlas_undrawn()", {
  it("is empty when every region is drawn", {
    expect_length(atlas_undrawn(aseg()), 0L)
    expect_length(atlas_undrawn(dk()), 0L)
  })

  it("names the regions left behind when views are narrowed", {
    # The sparsest view, found rather than assumed: a view that happens to
    # show every region leaves nothing behind, so picking one by position
    # tests nothing the day the atlas is rebuilt with different slabs.
    atlas <- aseg()
    drawn <- atlas_geom(atlas)
    per_view <- table(unlist(lapply(
      drawn$geometry,
      function(g) unique(g$view)
    )))
    sparsest <- names(per_view)[which.min(per_view)]
    one <- atlas_view_keep(atlas, sparsest)
    undrawn <- atlas_undrawn(one)
    expect_gt(length(undrawn), 0)
    expect_true(all(undrawn %in% atlas$core$label))
    expect_false(any(undrawn %in% atlas_undrawn(atlas)))
  })

  it("errors on a non-atlas", {
    expect_error(atlas_undrawn(data.frame(x = 1)), "ggseg_atlas")
  })
})

describe("atlas_context()", {
  it("returns the labels drawn but not held as regions", {
    ctx <- atlas_context(aseg())
    expect_gt(length(ctx), 0)
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


describe("context() and regions()", {
  it("select exactly the backdrop, and exactly the regions", {
    atlas <- aseg()
    ctx <- context()(atlas)
    reg <- regions()(atlas)

    expect_true(all(grepl(ctx, atlas_context(atlas))))
    expect_false(any(grepl(ctx, atlas$core$label)))
    expect_true(all(grepl(reg, atlas$core$label)))
    expect_false(any(grepl(reg, atlas_context(atlas))))
  })

  it("matches nothing when there is no backdrop", {
    # An empty alternation would match everything, which would quietly
    # polish the parcels with the backdrop's settings.
    atlas <- atlas_context_remove(dk())
    expect_false(any(grepl(context()(atlas), atlas$core$label)))
  })

  it("escapes a label that holds regex metacharacters", {
    # FreeSurfer spells its medial wall
    # `Background+FreeSurfer_Defined_Medial_Wall`; an unescaped `+` would
    # make the pattern match something else entirely.
    pattern <- labels_to_pattern("Background+FreeSurfer_Defined_Medial_Wall")
    expect_true(grepl(pattern, "Background+FreeSurfer_Defined_Medial_Wall"))
    expect_false(grepl(pattern, "BackgrounddFreeSurfer_Defined_Medial_Wall"))
  })

  it("is accepted by a geometry verb in place of a pattern", {
    atlas <- aseg()
    expect_no_error(
      atlas_prune_small(
        atlas,
        min_area = 1,
        scope = "piece",
        exclude = context()
      )
    )
  })
})

describe("the published dispatch surface", {
  it("is exactly the set of methods consumers may rely on", {
    # REVIEW.md treats a narrowed or dropped S3 method as a breaking change,
    # because ggseg, ggseg3d, ggseg.extra and every atlas package dispatch
    # through these generics. Enumerating the surface here is what makes that
    # rule enforceable: a method added or removed changes this snapshot, so it
    # cannot pass review unremarked. Previously the surface was written out in
    # REVIEW.md by hand, and had drifted from NAMESPACE.
    surface <- vapply(
      c(
        "as_ggseg_atlas",
        "atlas_display",
        "atlas_hemi",
        "atlas_labels",
        "atlas_regions",
        "atlas_type"
      ),
      function(generic) {
        methods <- as.character(utils::methods(generic))
        toString(sort(substring(methods, nchar(generic) + 2L)))
      },
      character(1)
    )
    expect_snapshot(print(surface))
  })
})

describe("atlas_views_empty", {
  # The flow this exists for: the user's own edits leave a view drawing
  # nothing. Keeping a single region strips every other region from every
  # view, and whichever view that region never appears in is left with
  # context only.
  stripped <- function(atlas) {
    keep <- atlas_regions(atlas)[1]
    suppressMessages(
      atlas_region_keep(atlas, paste0("^", keep, "$"), match_on = "region")
    )
  }

  it("reports nothing for the shipped atlases", {
    expect_identical(atlas_views_empty(aseg()), character(0))
    expect_identical(atlas_views_empty(dk()), character(0))
  })

  it("names a view left with context but no region", {
    before <- aseg()
    after <- stripped(before)

    empty <- atlas_views_empty(after)

    # The view is still there -- that is the point, it has to be reported
    # rather than silently gone -- and it still holds context geometry, so
    # emptiness has to be judged against `core`, not against any geometry.
    expect_gt(length(empty), 0L)
    expect_in(empty, atlas_views(after))
    still_drawn <- unique(polygons_unnest(atlas_polygons(after))$view)
    expect_in(empty, still_drawn)
  })

  it("agrees across the sf and polygon backends", {
    poly <- stripped(aseg())
    sf_backed <- stripped(suppressMessages(as_sf_atlas(aseg())))

    expect_identical(
      sort(atlas_views_empty(poly)),
      sort(atlas_views_empty(sf_backed))
    )
  })

  it("composes with atlas_view_remove, which is the documented use", {
    after <- stripped(aseg())
    empty <- atlas_views_empty(after)

    cleared <- suppressMessages(atlas_view_remove(after, empty))

    expect_identical(atlas_views_empty(cleared), character(0))
    expect_false(any(empty %in% atlas_views(cleared)))
  })

  it("returns nothing without 2D geometry, and rejects non-atlases", {
    bare <- aseg()
    bare$data$geom <- NULL
    bare$data$sf <- NULL

    expect_identical(atlas_views_empty(bare), character(0))
    expect_error(atlas_views_empty(mtcars), "ggseg_atlas")
  })
})
