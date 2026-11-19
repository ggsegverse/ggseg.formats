#' Reaching into an atlas
#'
#' An atlas is an S7 object and `$` is not part of its interface: `atlas_slot(atlas, "core")`
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
S7::method(names, ggseg_atlas_class) <- function(x) {
  S7::prop_names(x)
}

#' Replace several properties at once, validating only the result
#'
#' A validator that spans properties makes stepwise assignment impossible:
#' `atlas@core <- new_core` fails on its own when the palette it is about to
#' be paired with has not been assigned yet. Every multi-slot edit therefore
#' has to land in one step.
#' @noRd
atlas_set_props <- function(atlas, ...) {
  S7::props(atlas) <- list(...)
  atlas
}


#' Read one slot of an atlas, whichever representation it is in
#'
#' The accessors are the only supported way to reach into an atlas, and they
#' have to answer for two kinds of object: the S7 atlas this package builds,
#' and the plain list carrying a `ggseg_atlas` or `brain_atlas` tag that an
#' older release built and an installed atlas package still ships. This is the
#' one place that difference is handled; every accessor above it reads through
#' this and never asks which representation it was given.
#' @noRd
atlas_slot <- function(atlas, name) {
  if (S7::S7_inherits(atlas, ggseg_atlas_class)) {
    # A legacy atlas is a list, and `$` on a list answers NULL for a slot it
    # does not have. The conversion paths lean on that: they ask for `sf`,
    # `vertices` and `meshes`, which are legacy slots and not properties of
    # any S7 atlas, and branch on the NULL.
    if (!name %in% S7::prop_names(atlas)) {
      return(NULL)
    }
    return(S7::prop(atlas, name))
  }
  atlas[[name]]
}
