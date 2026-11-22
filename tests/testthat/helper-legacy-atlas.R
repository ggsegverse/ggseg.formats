# An S7 atlas cannot be constructed invalid: the validator spans the
# properties and runs on every assignment. Fixtures that have to be invalid --
# duplicated core labels, a missing core column, an unnamed palette, a payload
# that disagrees with the type -- are therefore built as legacy tagged lists,
# which is also the shape a published atlas built by an older ggseg.formats
# still has. The invalid-atlas paths through `assert_ggseg_atlas()`,
# `validate_ggseg_atlas()` and the format converters are exercised on those.
legacy_list_atlas <- function(atlas) {
  structure(
    as.list(atlas),
    class = c(
      paste0(atlas_type(atlas), "_atlas"),
      "ggseg_atlas",
      "list"
    )
  )
}
