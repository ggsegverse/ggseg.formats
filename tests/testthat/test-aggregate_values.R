cohort_data <- function() {
  data.frame(
    label = c("lh_a", "lh_a", "lh_b"),
    hemi = "left",
    subject = c("s01", "s02", "s01"),
    value = c(1, 3, 10)
  )
}

describe("aggregate_brain_values()", {
  it("reduces numeric columns per key with fun (default mean)", {
    agg <- aggregate_brain_values(
      cohort_data(),
      "label",
      warn_collapse = FALSE
    )
    expect_identical(agg$value, c(2, 10))
  })

  it("honours a custom aggregating function", {
    expect_identical(
      aggregate_brain_values(
        cohort_data(),
        "label",
        fun = max,
        warn_collapse = FALSE
      )$value,
      c(3, 10)
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
    expect_identical(names(agg), c("label", "value"))
  })

  it("returns no rows, with the same columns, for empty data", {
    agg <- aggregate_brain_values(
      cohort_data()[0, ],
      "label",
      ignore = "hemi",
      warn_collapse = FALSE
    )
    expect_identical(nrow(agg), 0L)
    expect_identical(names(agg), c("label", "subject", "value"))
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
      warn_collapsed_rows(cohort_data()[2:3, ], "label", "value"),
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
