describe("as_tbl", {
  it("applies the tibble classes to a data.frame", {
    out <- as_tbl(data.frame(a = 1:2, b = c("x", "y")))
    expect_s3_class(out, "tbl_df")
    expect_s3_class(out, "tbl")
    expect_s3_class(out, "data.frame")
    expect_s3_class(out, c("tbl_df", "tbl", "data.frame"), exact = TRUE)
  })

  it("resets row names", {
    df <- data.frame(a = 1:3)
    out <- as_tbl(df[c(3, 1), , drop = FALSE])
    expect_identical(attr(out, "row.names"), 1:2)
  })

  it("preserves list-columns", {
    df <- data.frame(label = "a")
    df$geometry <- list(data.frame(x = 1:2))
    out <- as_tbl(df)
    expect_type(out$geometry, "list")
    expect_identical(nrow(out$geometry[[1]]), 2L)
  })
})

describe("df_distinct", {
  it("returns unique rows over the given columns as a tibble", {
    df <- data.frame(
      hemi = c("l", "l", "r"),
      region = c("a", "a", "b"),
      extra = 1:3
    )
    out <- df_distinct(df, c("hemi", "region"))
    expect_s3_class(out, "tbl_df")
    expect_identical(nrow(out), 2L)
    expect_named(out, c("hemi", "region"))
  })
})

describe("df_left_join", {
  it("adds columns and preserves left-hand row order", {
    x <- data.frame(label = c("b", "a", "c"))
    y <- data.frame(label = c("a", "b"), value = c(1, 2))
    out <- df_left_join(x, y, by = "label")
    expect_s3_class(out, "tbl_df")
    expect_identical(out$label, c("b", "a", "c"))
    expect_identical(out$value, c(2, 1, NA))
  })

  it("expands rows one-to-many when keys repeat in y", {
    x <- data.frame(label = "a")
    y <- data.frame(label = c("a", "a"), region = c("r1", "r2"))
    out <- df_left_join(x, y, by = "label")
    expect_identical(nrow(out), 2L)
    expect_identical(out$region, c("r1", "r2"))
  })

  it("suffixes colliding non-key columns with .y and warns", {
    x <- data.frame(label = "a", value = 1)
    y <- data.frame(label = "a", value = 99)
    expect_warning(
      out <- df_left_join(x, y, by = "label"),
      "collide"
    )
    expect_identical(out$value, 1)
    expect_identical(out$value.y, 99)
  })
})

describe("df_bind_rows", {
  it("binds rows and adds the id column first", {
    out <- df_bind_rows(
      list(p = data.frame(v = 1), q = data.frame(v = 2)),
      .id = "subject"
    )
    expect_s3_class(out, "tbl_df")
    expect_named(out, c("subject", "v"))
    expect_identical(out$subject, c("p", "q"))
  })

  it("returns an empty tibble for an empty list", {
    expect_identical(nrow(df_bind_rows(list())), 0L)
  })

  it("unions differing columns and fills gaps with NA, with a warning", {
    expect_warning(
      out <- df_bind_rows(list(data.frame(a = 1, b = 2), data.frame(a = 3))),
      "differing columns"
    )
    expect_setequal(names(out), c("a", "b"))
    expect_identical(out$a, c(1, 3))
    expect_identical(out$b, c(2, NA))
  })

  it("aborts when .id is requested for an unnamed list", {
    expect_error(
      df_bind_rows(list(data.frame(v = 1), data.frame(v = 2)), .id = "id"),
      "named list"
    )
  })
})

describe("df_nest / df_unnest", {
  it("round-trips a flat table through nesting", {
    flat <- data.frame(
      label = c("a", "a", "b"),
      view = c("lat", "med", "lat"),
      x = c(1, 2, 3)
    )
    nested <- df_nest(flat, "label", "geometry")
    expect_s3_class(nested, "tbl_df")
    expect_identical(nrow(nested), 2L)
    expect_type(nested$geometry, "list")
    expect_s3_class(nested$geometry[[1]], "tbl_df")

    back <- df_unnest(nested, "geometry")
    expect_identical(nrow(back), 3L)
    expect_setequal(names(back), names(flat))
  })
})

describe("format_list_cell", {
  it("summarises atomic vectors by abbreviated type and length", {
    expect_identical(format_list_cell(1:3), "<int [3]>")
    expect_identical(format_list_cell(c(1.5, 2.5)), "<dbl [2]>")
    expect_identical(format_list_cell(c("a", "b", "c")), "<chr [3]>")
    expect_identical(format_list_cell(c(TRUE, FALSE)), "<lgl [2]>")
    expect_identical(format_list_cell(complex(1)), "<cpl [1]>")
    expect_identical(format_list_cell(list(1, 2)), "<list [2]>")
  })

  it("summarises data.frame cells by dimensions", {
    expect_identical(
      format_list_cell(data.frame(x = 1:5, y = 1:5)),
      "<df [5 x 2]>"
    )
  })

  it("labels NULL cells", {
    expect_identical(format_list_cell(NULL), "<NULL>")
  })

  it("falls back to the type name for unabbreviated types", {
    expect_identical(format_list_cell(as.raw(1:2)), "<raw [2]>")
  })
})

describe("print_data_head", {
  it("prints list-columns as compact summaries, regardless of tibble", {
    df <- as_tbl(data.frame(label = c("a", "b")))
    df$vertices <- list(1:3, 1:10)
    expect_snapshot(result <- print_data_head(df))
    expect_identical(result, df)
  })

  it("notes the rows dropped beyond n", {
    expect_snapshot(print_data_head(as_tbl(data.frame(x = 1:5)), n = 2))
  })
})


describe("df_nest()", {
  it("groups an NA key on its own instead of corrupting both groups", {
    # `df[[key]] == k` is NA for an NA key, and an NA index yields a row of
    # NAs: the NA row leaked into "a" as an all-NA row AND the NA group came
    # back as every row filled with NA. Both groups were wrong.
    flat <- data.frame(
      label = c("a", NA, "a"),
      x = c(1, 2, 3),
      y = c(1, 2, 3)
    )

    nested <- df_nest(flat, "label", "geometry")

    expect_identical(nrow(nested), 2L)
    a <- nested$geometry[[which(nested$label == "a")]]
    na <- nested$geometry[[which(is.na(nested$label))]]
    expect_identical(a$x, c(1, 3))
    expect_identical(na$x, 2)
  })

  it("keeps keys in first-appearance order, and the column unnamed", {
    flat <- data.frame(label = c("z", "a", "z"), x = 1:3)

    nested <- df_nest(flat, "label", "geometry")

    expect_identical(nested$label, c("z", "a"))
    # `split()` names its result by level label, so without unname() the
    # list-column carries "1", "2" and stops being identical() to a frame
    # built before the change.
    expect_null(names(nested$geometry))
  })

  it("round-trips through df_unnest()", {
    flat <- data.frame(
      label = c("a", "b", "a"),
      x = c(1, 2, 3),
      stringsAsFactors = FALSE
    )

    back <- df_unnest(df_nest(flat, "label", "geometry"), "geometry")

    # Pins the label-to-value PAIRING, which sorting each column separately
    # does not: that would pass an implementation nesting row 1's x under the
    # wrong key. Row order is grouped by key rather than restored, so the
    # frames are not comparable whole.
    expect_identical(back$x[back$label == "a"], c(1, 3))
    expect_identical(back$x[back$label == "b"], 2)
    expect_identical(nrow(back), nrow(flat))
  })
})
