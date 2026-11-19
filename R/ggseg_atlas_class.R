#' The S7 class hierarchy behind `ggseg_atlas()`
#'
#' The type vocabulary is expressed as the class hierarchy rather than as a
#' `type` string checked against a list of permitted values. Each type is a
#' concrete subclass of the abstract `ggseg_atlas` parent, and `wm_atlas`
#' descends from `subcortical_atlas` because a white-matter label map stores
#' and draws exactly what a subcortical atlas does. The abstract parent cannot
#' be instantiated, so an atlas of an unknown type is unrepresentable rather
#' than merely rejected.
#'
#' `type` is a read-only property computed from the class, which is why there
#' is no way to leave the two disagreeing. Retyping an atlas therefore means
#' constructing a new one; see [set_atlas_type()].
#'
#' @name ggseg_atlas_classes
#' @keywords internal
NULL

atlas_data_class <- S7::new_union(
  S7::new_S3_class("ggseg_atlas_data"),
  S7::new_S3_class("brain_atlas_data")
)

atlas_shared_properties <- function() {
  list(
    atlas = S7::class_character,
    type = S7::new_property(
      S7::class_character,
      getter = function(self) atlas_type_of_class(self)
    ),
    palette = NULL | S7::class_character,
    core = S7::class_data.frame,
    data = atlas_data_class,
    provenance = NULL | S7::class_list
  )
}

#' The type a concrete atlas class stands for
#'
#' `class()` on an S7 object defined in a package leads with the namespaced
#' name (`ggseg.formats::cortical_atlas`), so the type is read off the class
#' object's own name instead of parsed out of the class vector.
#' @noRd
atlas_type_of_class <- function(x) {
  sub("_atlas$", "", S7::S7_class(x)@name)
}

#' @rdname ggseg_atlas_classes
#' @export
ggseg_atlas_class <- S7::new_class(
  "ggseg_atlas",
  abstract = TRUE,
  properties = atlas_shared_properties(),
  validator = function(self) atlas_invariant_defect(self)
)

#' @rdname ggseg_atlas_classes
#' @export
cortical_atlas <- S7::new_class(
  "cortical_atlas",
  parent = ggseg_atlas_class
)

#' @rdname ggseg_atlas_classes
#' @export
subcortical_atlas <- S7::new_class(
  "subcortical_atlas",
  parent = ggseg_atlas_class
)

#' @rdname ggseg_atlas_classes
#' @export
tract_atlas <- S7::new_class(
  "tract_atlas",
  parent = ggseg_atlas_class
)

#' @rdname ggseg_atlas_classes
#' @export
cerebellar_atlas <- S7::new_class(
  "cerebellar_atlas",
  parent = ggseg_atlas_class
)

#' @rdname ggseg_atlas_classes
#' @export
wm_atlas <- S7::new_class(
  "wm_atlas",
  parent = subcortical_atlas
)

atlas_class_for_type <- function(type) {
  switch(
    type,
    cortical = cortical_atlas,
    subcortical = subcortical_atlas,
    tract = tract_atlas,
    cerebellar = cerebellar_atlas,
    wm = wm_atlas,
    cli::cli_abort("No atlas class for type {.val {type}}.")
  )
}


#' Invariants an atlas must hold at every moment, not only at construction
#'
#' The `ggseg_atlas()` constructor is where an atlas author gets the full
#' diagnosis: cli bullets, a condition class per defect, and warning-level
#' nudges about schema gaps that are not yet errors. An S7 validator can
#' return only a string, and it runs on every property assignment, so it
#' carries the cheap structural invariants that must never be false --
#' the ones that would silently corrupt a plot rather than merely leave the
#' schema thin.
#'
#' Keeping the pair in step is the cost of validating mutation: a check added
#' to the constructor is not enforced on assignment until it is named here
#' too.
#' @noRd
atlas_invariant_defect <- function(self) {
  core <- self@core

  if (length(self@atlas) != 1 || is.na(self@atlas)) {
    return("@atlas must be a single, non-missing atlas name")
  }

  missing_core <- setdiff(c("region", "label"), names(core))
  if (length(missing_core)) {
    return(paste0("@core must contain columns: ", toString(missing_core)))
  }

  dupes <- unique(core$label[duplicated(core$label)])
  if (length(dupes)) {
    return(paste0(
      "@core$label must be unique; duplicated: ",
      toString(dupes),
      ". label is the key the palette and geometry join on."
    ))
  }

  if (!is.null(self@palette) && is.null(names(self@palette))) {
    return("@palette must be a named character vector, keyed by core$label")
  }

  expected <- paste0(c("ggseg_data_", "brain_data_"), self@type)
  if (!any(vapply(expected, inherits, logical(1), x = self@data))) {
    return(paste0(
      "@data must be a <",
      expected[[1]],
      "> for a ",
      self@type,
      " atlas, not <",
      class(self@data)[[1]],
      ">"
    ))
  }

  NULL
}


#' Carry the unqualified class tags the ecosystem dispatches on
#'
#' An S7 class defined inside a package is tagged with its qualified name --
#' `ggseg.formats::cortical_atlas` -- and nothing else, so
#' `inherits(x, "cortical_atlas")` is false for a perfectly good atlas. Every
#' renderer, every atlas package's tests and every `is_*_atlas()` predicate
#' asks exactly that question, so the unqualified tags are prepended to the
#' class vector. ggplot2 carries `gg` alongside `ggplot2::ggplot` for the same
#' reason.
#'
#' The tags are *appended*, never prepended. S7 finds a method for a base
#' generic such as `$<-` by looking up `class(x)[1]` in its own table, so a
#' leading unqualified tag makes that lookup miss and `atlas$core <- value`
#' falls through to S7's "can't set properties with `$`" error. Appending
#' leaves `class(x)[1]` qualified -- `inherits()` scans the whole vector, so
#' it is satisfied either way.
#' @noRd
tag_legacy_atlas_classes <- function(x) {
  class(x) <- c(class(x), legacy_atlas_class_tags(x))
  x
}

#' @noRd
legacy_atlas_class_tags <- function(x) {
  qualified <- grep("::", class(x), value = TRUE, fixed = TRUE)
  sub("^[^:]+::", "", qualified)
}


#' Is this object slot-addressable with `$`?
#'
#' Stands in for the `is.list()` guards that predate the class: an atlas is no
#' longer a list, but both the S7 object and a legacy list carry named slots
#' reachable with `$`. Guards that mean "I can read `x$core` off this" ask
#' this instead of asking whether it is a list.
#' @noRd
atlas_has_slots <- function(x) {
  S7::S7_inherits(x, ggseg_atlas_class) || is.list(x)
}


#' Methods on base generics have to be S7 methods, not S3 methods
#'
#' S7 registers its own S3 methods on `print()`, `format()` and friends for
#' `S7_object`, and `S7_object` sits ahead of the appended unqualified tags in
#' the class vector. An S3 `print.ggseg_atlas()` is therefore never reached:
#' S7's generic default wins and dumps every property of a 60 MB atlas to the
#' console. Registering the same functions as S7 methods puts them back in
#' charge, and is where they belong once the class is S7 anyway.
#' @noRd
NULL

S7::method(print, ggseg_atlas_class) <- print_ggseg_atlas
S7::method(plot, ggseg_atlas_class) <- plot_ggseg_atlas
S7::method(as.list, ggseg_atlas_class) <- as_list_ggseg_atlas
S7::method(as.data.frame, ggseg_atlas_class) <- as_data_frame_ggseg_atlas


#' The same methods, still registered for legacy list atlases
#'
#' An atlas built by an older `ggseg.formats` and shipped inside an installed
#' atlas package is a plain list carrying the `ggseg_atlas` or `brain_atlas`
#' S3 tag. It is not an S7 object, so the S7 methods above never see it, and
#' without these registrations it would print as a raw list. Both sets of
#' methods delegate to the same functions.
#' @param x an atlas
#' @param n rows of `core` to print
#' @param ... passed on
#' @return `x`, invisibly, or the coerced object
#' @name legacy_atlas_methods
#' @keywords internal
#' @export
print.ggseg_atlas <- print_ggseg_atlas

#' @rdname legacy_atlas_methods
#' @export
plot.ggseg_atlas <- plot_ggseg_atlas

#' @rdname legacy_atlas_methods
#' @export
as.list.ggseg_atlas <- as_list_ggseg_atlas

#' @rdname legacy_atlas_methods
#' @export
as.data.frame.ggseg_atlas <- as_data_frame_ggseg_atlas
