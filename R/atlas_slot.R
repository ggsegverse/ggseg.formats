#' Reading an atlas whichever representation it is in
#'
#' The accessors are the only supported way to reach into an atlas, and they
#' have to answer for two kinds of object: the S7 atlas this package builds,
#' and the plain list carrying a `ggseg_atlas` or `brain_atlas` tag that an
#' older release built and an installed atlas package still ships. These are
#' the only place that difference is handled.
#'
#' They live in a file of their own, with no `S7::new_class()` or
#' `S7::method()` call at its top level, because `lintr`'s `object_usage_linter`
#' cannot resolve a function defined alongside those and reports every call to
#' it as an undefined global -- 381 of them, one per call site.
#' @name atlas_slot_access
#' @noRd
NULL


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


#' Write one slot of an atlas, whichever representation it is in
#'
#' The counterpart to `atlas_slot()`, for the handful of places that edit one
#' slot in place. Having it as a replacement function is what lets a nested
#' edit -- `atlas_slot(atlas, "data")$geom <- geom` -- work on both
#' representations: R rewrites that into a read of the slot followed by a write
#' back through here.
#'
#' Only single-slot edits can go through this, because the validator spans the
#' properties and runs on every assignment. An edit whose intermediate state is
#' invalid has to land in one step, through `atlas_set_props()`.
#' @noRd
`atlas_slot<-` <- function(atlas, name, value) {
  if (S7::S7_inherits(atlas, ggseg_atlas_class)) {
    S7::prop(atlas, name) <- value
    return(atlas)
  }
  atlas[[name]] <- value
  atlas
}
