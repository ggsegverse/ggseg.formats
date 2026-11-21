#' Take an atlas in at a package boundary
#'
#' The one call a function should make on an atlas it was handed by a user.
#' It answers for every representation an atlas arrives in -- the S7 object
#' this release builds, the plain tagged list an atlas package built before
#' 3.0.0, and an S7 atlas stamped with an older schema -- and returns the
#' current one. Downstream code then has a single kind of object to reason
#' about.
#'
#' @section Why upgrade rather than assert:
#'
#' [assert_ggseg_atlas()] checks and returns its input unchanged, which leaves
#' every path after it to cope with whatever it was given. That is how a
#' legacy list atlas reached `as.data.frame()` in `brain_join()` and
#' `plot.default()` from `plot()`: not because those paths were wrong, but
#' because nothing had made the object current first.
#'
#' Upgrading here means a published atlas is revalidated against the running
#' version's rules before anything touches it, and a stale schema is caught at
#' the boundary rather than three calls deep on a property that is not there.
#'
#' It is a no-op on an atlas that is already current, so the cost falls on the
#' objects that need it.
#'
#' @param atlas An atlas, in any representation.
#' @param arg The argument name to blame in an error. Defaults to the caller's.
#' @param call The environment to attribute the error to.
#'
#' @return The atlas, as a current `ggseg_atlas`.
#' @seealso [assert_ggseg_atlas()], which checks without upgrading, and
#'   [as_ggseg_atlas()], which upgrades without the boundary error messages.
#' @export
#' @examples
#' # A no-op on a current atlas.
#' identical(atlas_input(dk()), dk())
#'
#' # An atlas built before 3.0.0 comes back current.
#' legacy <- structure(as.list(dk()), class = c("cortical_atlas", "list"))
#' atlas_schema(atlas_input(legacy))
atlas_input <- function(
  atlas,
  arg = rlang::caller_arg(atlas),
  call = rlang::caller_env()
) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort(
      "{.arg {arg}} must be a {.cls ggseg_atlas}, not
       {.cls {class(atlas)[1]}}.",
      class = "ggseg.formats_not_atlas",
      call = call
    )
  }

  if (atlas_is_current(atlas)) {
    return(atlas)
  }

  rlang::try_fetch(
    suppressMessages(as_ggseg_atlas(atlas)),
    error = function(cnd) {
      cli::cli_abort(
        "{.arg {arg}} is a {.cls ggseg_atlas} with an invalid structure.",
        class = "ggseg.formats_invalid_atlas",
        parent = cnd,
        call = call
      )
    }
  )
}


#' Is this atlas already the thing every path downstream expects?
#'
#' Both halves matter. An S7 atlas on an old schema is missing whatever has
#' been added since, and a legacy list is not an S7 object at all.
#' @noRd
atlas_is_current <- function(atlas) {
  S7::S7_inherits(atlas, ggseg_atlas_class) && atlas_schema_is_current(atlas)
}
