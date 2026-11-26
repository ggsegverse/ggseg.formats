cohort_data <- function() {
  # `lh_a` is skewed on purpose: with c(1, 3) mean and median are both 2, so
  # the default `fun = mean` was indistinguishable from `median`.
  data.frame(
    label = c("lh_a", "lh_a", "lh_a", "lh_b"),
    hemi = "left",
    subject = c("s01", "s02", "s03", "s01"),
    value = c(1, 2, 9, 10)
  )
}

describe("aggregate_brain_values()", {
  it("reduces numeric columns per key with fun (default mean)", {
    agg <- aggregate_brain_values(
      cohort_data(),
      "label",
      warn_collapse = FALSE
    )
    # mean(c(1, 2, 9)) is 4; median is 2, so this pins the default.
    expect_identical(agg$value, c(4, 10))
  })

  it("keeps an NA key distinct from one spelled \"NA\"", {
    # `as.character(NA)` is the string "NA", so keying on values merged the two
    # into one group and averaged a region's value into its namesake.
    agg <- aggregate_brain_values(
      data.frame(label = c("NA", NA, "NA"), value = c(1, 100, 3)),
      "label",
      warn_collapse = FALSE
    )

    expect_identical(nrow(agg), 2L)
    expect_identical(agg$value, c(2, 100))
  })

  it("keeps numeric keys that print alike but differ", {
    # `as.character()` rounds, so 0.1 + 0.2 and 0.3 keyed as one group.
    agg <- aggregate_brain_values(
      data.frame(k = c(0.1 + 0.2, 0.3), value = c(1, 100)),
      "k",
      warn_collapse = FALSE
    )

    expect_identical(nrow(agg), 2L)
  })

  it("does not merge two distinct multi-column keys", {
    # The key is a pasted tuple of INDICES, so it needs its separator. The
    # first eleven rows make both columns index 1..11; the last two are then
    # (label 1, view 11) and (label 11, view 1), which unseparated both
    # render "111" and would merge into one group.
    labels <- paste0("L", 1:11)
    views <- paste0("V", 1:11)
    data <- data.frame(
      label = c(labels, labels[1], labels[11]),
      view = c(views, views[11], views[1]),
      value = c(rep(0, 11), 7, 70)
    )

    agg <- aggregate_brain_values(
      data,
      c("label", "view"),
      warn_collapse = FALSE
    )

    expect_identical(nrow(agg), 13L)
    expect_identical(agg$value[agg$label == "L1" & agg$view == "V11"], 7)
    expect_identical(agg$value[agg$label == "L11" & agg$view == "V1"], 70)
  })

  it("honours a custom aggregating function", {
    expect_identical(
      aggregate_brain_values(
        cohort_data(),
        "label",
        fun = max,
        warn_collapse = FALSE
      )$value,
      c(9, 10)
    )
    expect_identical(
      aggregate_brain_values(
        cohort_data(),
        "label",
        fun = min,
        warn_collapse = FALSE
      )$value,
      c(1, 10)
    )
  })

  it("takes the first value of non-numeric columns", {
    expect_identical(
      aggregate_brain_values(
        cohort_data(),
        "label",
        warn_collapse = FALSE
      )$subject,
      c("s01", "s01")
    )
  })

  it("collapses to one row per key combination", {
    agg <- aggregate_brain_values(
      cohort_data(),
      c("label", "hemi"),
      warn_collapse = FALSE
    )
    expect_identical(nrow(agg), 2L)
    expect_identical(agg$label, c("lh_a", "lh_b"))
  })

  it("drops the ignored columns and keeps the keys", {
    agg <- aggregate_brain_values(
      cohort_data(),
      "label",
      ignore = c("hemi", "subject"),
      warn_collapse = FALSE
    )
    expect_named(agg, c("label", "value"))
  })

  it("returns no rows, with the same columns, for empty data", {
    agg <- aggregate_brain_values(
      cohort_data()[0, ],
      "label",
      ignore = "hemi",
      warn_collapse = FALSE
    )
    expect_identical(nrow(agg), 0L)
    expect_named(agg, c("label", "subject", "value"))
  })

  it("errors clearly when fun does not reduce to a single value", {
    expect_error(
      aggregate_brain_values(
        cohort_data(),
        "label",
        fun = range,
        warn_collapse = FALSE
      ),
      "single value"
    )
  })

  it("errors when keys are missing or absent from data", {
    expect_error(
      aggregate_brain_values(cohort_data(), character(0)),
      "one or more columns"
    )
    expect_error(
      aggregate_brain_values(cohort_data(), "nope"),
      "nope"
    )
  })

  it("warns through aggregation when rows collapse", {
    rlang::reset_warning_verbosity("ggseg_collapsed_rows")
    expect_warning(
      aggregate_brain_values(cohort_data(), "label"),
      class = "ggseg_collapsed_rows"
    )
  })
})

describe("warn_collapsed_rows()", {
  it("warns when several data rows map to one region", {
    rlang::reset_warning_verbosity("ggseg_collapsed_rows")
    w <- expect_warning(
      warn_collapsed_rows(cohort_data(), "label", "value"),
      class = "ggseg_collapsed_rows"
    )
    expect_match(conditionMessage(w), "dplyr::last", fixed = TRUE)
    expect_match(conditionMessage(w), "Non-numeric", fixed = TRUE)
  })

  it("stays silent when every region appears once", {
    rlang::reset_warning_verbosity("ggseg_collapsed_rows")
    expect_no_warning(
      warn_collapsed_rows(cohort_data()[3:4, ], "label", "value"),
      class = "ggseg_collapsed_rows"
    )
  })

  it("stays silent when there is no value column to collapse", {
    rlang::reset_warning_verbosity("ggseg_collapsed_rows")
    expect_no_warning(
      warn_collapsed_rows(cohort_data(), "label", character(0)),
      class = "ggseg_collapsed_rows"
    )
  })

  it("warns only once per session", {
    rlang::reset_warning_verbosity("ggseg_collapsed_rows")
    expect_warning(
      warn_collapsed_rows(cohort_data(), "label", "value"),
      class = "ggseg_collapsed_rows"
    )
    expect_no_warning(
      warn_collapsed_rows(cohort_data(), "label", "value"),
      class = "ggseg_collapsed_rows"
    )
  })
})
