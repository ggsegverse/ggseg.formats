#' Reaching into an atlas
#'
#' An atlas is an S7 object and `$` is not part of its interface: `atlas$core`
#' is an error, not a slot read. Until 3.0.0 an atlas *was* a list, `"list"`
#' was part of its class vector, and `$` was how the ecosystem reached its
#' parts; the accessors are now the only supported way, because they can
#' outlive a change of representation and `$` cannot.
#' @noRd
NULL

#' `names()` must report `type` even though it is computed
#'
#' `guess_type()` -- and any other caller that works out whether a slot is
#' present before reading it -- asks `"type" %in% names(x)`. A computed
#' property is still a property, so leaving it out of `names()` made every
#' atlas look untyped and sent `atlas_type()` down its guessing path, which
#' silently answered "subcortical" for a cerebellar atlas.
#' @noRd
NULL


#' Replace several properties at once, validating only the result
#'
#' A validator that spans properties makes stepwise assignment impossible:
#' `atlas@core <- new_core` fails on its own when the palette it is about to
#' be paired with has not been assigned yet. Every multi-slot edit therefore
#' has to land in one step.
#' @noRd
atlas_set_props <- function(atlas, ...) {
  values <- list(...)
  if (!S7::S7_inherits(atlas, ggseg_atlas_class)) {
    # A legacy list has no validator spanning its slots, so there is nothing
    # to land in one step; assigning them one at a time is the same thing.
    for (name in names(values)) {
      atlas[[name]] <- values[[name]]
    }
    return(atlas)
  }
  S7::props(atlas) <- values
  atlas
}
