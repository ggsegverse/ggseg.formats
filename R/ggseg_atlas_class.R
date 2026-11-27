#' The S7 class hierarchy behind `ggseg_atlas()`
#'
#' The type vocabulary is expressed as the class hierarchy rather than as a
#' `type` string checked against a list of permitted values. Each type is a
#' concrete subclass of the abstract `ggseg_atlas` parent, and
#' `white_matter_atlas`
#' descends from `subcortical_atlas` because a white-matter label map stores
#' and draws exactly what a subcortical atlas does. The abstract parent cannot
#' be instantiated, so there is no way to make an atlas of an unknown type at
#' all, rather than merely a check that rejects one.
#'
#' `type` is a read-only property computed from the class, which is why there
#' is no way to leave the two disagreeing. Retyping an atlas therefore means
#' constructing a new one; see [set_atlas_type()].
#'
#' @name ggseg_atlas_classes
#' @noRd
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
    provenance = NULL | S7::class_list,
    schema = S7::class_integer
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

#' @noRd
ggseg_atlas_class <- S7::new_class(
  "ggseg_atlas",
  abstract = TRUE,
  properties = atlas_shared_properties(),
  validator = function(self) atlas_invariant_defect(self)
)

#' @noRd
cortical_atlas <- S7::new_class(
  "cortical_atlas",
  parent = ggseg_atlas_class
)

#' @noRd
subcortical_atlas <- S7::new_class(
  "subcortical_atlas",
  parent = ggseg_atlas_class
)

#' @noRd
tract_atlas <- S7::new_class(
  "tract_atlas",
  parent = ggseg_atlas_class
)

#' @noRd
cerebellar_atlas <- S7::new_class(
  "cerebellar_atlas",
  parent = ggseg_atlas_class
)

#' @noRd
white_matter_atlas <- S7::new_class(
  "white_matter_atlas",
  parent = subcortical_atlas
)

atlas_class_for_type <- function(type) {
  switch(
    type,
    cortical = cortical_atlas,
    subcortical = subcortical_atlas,
    tract = tract_atlas,
    cerebellar = cerebellar_atlas,
    white_matter = white_matter_atlas,
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

  # `hemi` answers one question with a closed set of answers, and consumers
  # filter and facet on it, so a fifth spelling is not a stylistic choice but
  # a row that silently vanishes from `hemi == "left"`. It belongs here rather
  # than in the constructor alone: the bundled MCALT cerebellar atlas shipped
  # with `hemi == "vermis"` and was rejected by both renderers at draw time,
  # which is exactly the failure an invariant checked on assignment prevents.
  hemi_defect <- core_hemi_defect(core)
  if (!is.null(hemi_defect)) {
    return(hemi_defect)
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
#' asks exactly that question, so the unqualified tags lead the class
#' vector. ggplot2 carries `gg` alongside `ggplot2::ggplot` for the same
#' reason.
#'
#' The tags exist for `inherits()`, and for nothing else.
#'
#' They no longer decide which method runs. The base generics are registered
#' against both the S7 class and the S3 class, so each representation finds
#' the same function whatever the class vector looks like. The tags lead
#' because `class(x)[1]` reads better unqualified in an error message.
#' @noRd
tag_legacy_atlas_classes <- function(x) {
  class(x) <- c(legacy_atlas_class_tags(x), class(x))
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
#' `S7_object`, which sits ahead of the unqualified tags in the class vector,
#' so S7's default wins and dumps every property of a 60 MB atlas. Registering
#' them as S7 methods puts them back in charge -- and it has to be all of
#' them: a package that registers an S7 method and an `S3method()` on the same
#' generic breaks `load_all()`. See `R/zzz_methods.R`.
#' @noRd
NULL


#' The `hemi` vocabulary violation in a core table, or `NULL`
#'
#' Shares the closed vocabulary with `validate_core_hemi()`, which raises the
#' same complaint from the constructor with cli bullets and a condition class.
#' This one returns a bare string, which is all an S7 validator may do.
#' @noRd
core_hemi_defect <- function(core) {
  if (!"hemi" %in% names(core)) {
    return(NULL)
  }
  allowed <- c("left", "right", "midline")
  present <- unique(as.character(core$hemi[!is.na(core$hemi)]))
  unexpected <- setdiff(present, allowed)
  if (length(unexpected) == 0) {
    return(NULL)
  }
  paste0(
    "@core$hemi must be one of ",
    toString(allowed),
    ", or NA; got ",
    toString(unexpected)
  )
}
