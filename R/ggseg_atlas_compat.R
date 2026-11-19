#' Reach an atlas's properties with `$`, as the list representation allowed
#'
#' Until 0.1.0 an atlas *was* a list, `"list"` was part of its class vector,
#' and `atlas$core` was how the whole ecosystem -- this package, ggseg,
#' ggseg3d, ggseg.extra, every atlas package's build script and every user's
#' analysis -- reached its parts. Routing `$` to the property of the same name
#' keeps all of that working against an object that is no longer a list.
#'
#' The accessors ([atlas_core()], [atlas_palette()], and friends) remain the
#' supported interface, because they can outlive a change of representation
#' and `$` cannot. What `$` no longer does is return `NULL` for a name that
#' is not a property: `atlas$mispelled` is now an error rather than silence.
#'
#' `$<-` routes to property assignment, so it validates. Assigning a core
#' table with duplicated labels through `atlas$core <-` now fails where it
#' used to corrupt the atlas quietly.
#' @noRd
NULL

S7::method(`$`, ggseg_atlas_class) <- S7::prop

S7::method(`$<-`, ggseg_atlas_class) <- function(x, name, value) {
  S7::prop(x, name) <- value
  x
}

#' `names()` must report `type` even though it is computed
#'
#' `guess_type()` -- and any other caller that works out whether a slot is
#' present before reading it -- asks `"type" %in% names(x)`. A computed
#' property is still a property, so leaving it out of `names()` made every
#' atlas look untyped and sent `atlas_type()` down its guessing path, which
#' silently answered "subcortical" for a cerebellar atlas.
#' @noRd
S7::method(names, ggseg_atlas_class) <- function(x) {
  S7::prop_names(x)
}

#' Replace several properties at once, validating only the result
#'
#' A validator that spans properties makes stepwise assignment impossible:
#' `atlas$core <- new_core` fails on its own when the palette it is about to
#' be paired with has not been assigned yet. Every multi-slot edit therefore
#' has to land in one step.
#' @noRd
atlas_set_props <- function(atlas, ...) {
  S7::props(atlas) <- list(...)
  atlas
}
