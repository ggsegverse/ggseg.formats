#' Set the palette of an atlas
#'
#' Replaces the colour palette of a brain atlas, validating that `value` is a
#' named character vector and warning if it does not cover every atlas label.
#' This is the setter counterpart to the [atlas_palette()] accessor; it returns
#' the modified atlas, so it composes with the pipe.
#'
#' @inheritParams atlas_palette
#' @param value Named character vector of colours keyed by atlas `label`,
#'   or `NULL` to clear the palette.
#'
#' @return The `ggseg_atlas` with its palette replaced.
#' @family atlas setters
#' @seealso [atlas_palette()] to read the palette.
#' @export
#' @examples
#' a <- aseg()
#' labs <- atlas_labels(a)
#' a <- set_atlas_palette(a, setNames(grDevices::rainbow(length(labs)), labs))
set_atlas_palette <- function(atlas, value) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  if (is.null(value)) {
    # A palette-less atlas is a state the class allows and the renderers cope
    # with, so the setter has to be able to produce it. Without this, clearing
    # a palette was only reachable by assigning the property directly.
    atlas_slot(atlas, "palette") <- NULL
    return(atlas)
  }

  if (!is.character(value) || is.null(names(value))) {
    cli::cli_abort(c(
      "{.arg value} must be a named character vector of colours, or {.val NULL}
       to clear it.",
      "i" = "Names are the atlas region {.field label}s."
    ))
  }
  absent <- setdiff(unique(atlas_labels(atlas)), names(value))
  if (length(absent)) {
    cli::cli_warn(c(
      "Palette does not cover every atlas label.",
      "i" = "e.g. {.val {utils::head(absent, 3)}} ({length(absent)} total)."
    ))
  }
  atlas_slot(atlas, "palette") <- value
  atlas
}


#' Set the type of an atlas
#'
#' Replaces the type of a brain atlas. The type is held in three coupled
#' places: the `type` field, the leading `<type>_atlas` class, and the
#' `ggseg_data_<type>` class of the data payload. This setter reconstructs the
#' atlas through [ggseg_atlas()] so all three stay in agreement -- assigning
#' the `type` field directly leaves the subclass stale and
#' [is_tract_atlas()] and friends disagreeing with [atlas_type()].
#'
#' Because type and payload are coupled, the new type must match the data the
#' atlas already carries: a `"tract"` atlas needs [ggseg_data_tract()]
#' (centerlines), a `"subcortical"` atlas needs [ggseg_data_subcortical()]
#' (meshes). Retyping an atlas whose payload does not match is an error --
#' rebuild the payload with the matching `ggseg_data_*()` constructor first.
#'
#' @inheritParams atlas_palette
#' @param value Atlas type; one of `"cortical"`, `"subcortical"`, `"tract"` or
#'   `"cerebellar"`.
#'
#' @return The `ggseg_atlas` with its type, subclass and payload class in
#'   agreement.
#' @family atlas setters
#' @seealso [atlas_type()] to read the type.
#' @export
#' @examples
#' a <- aseg()
#' a <- set_atlas_type(a, "subcortical")
#' atlas_type(a)
set_atlas_type <- function(atlas, value) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  value <- match.arg(value, atlas_types())

  ggseg_atlas(
    atlas = atlas_slot(atlas, "atlas"),
    type = value,
    core = atlas_slot(atlas, "core"),
    data = atlas_slot(atlas, "data"),
    palette = atlas_slot(atlas, "palette"),
    provenance = atlas_slot(atlas, "provenance")
  )
}


#' Record how an atlas was built
#'
#' Attaches a build record to an atlas. Intended for the pipelines in
#' \pkg{ggseg.extra}, which know the arguments a build was given; it is
#' exported so a third party constructing an atlas by hand can record the same
#' thing rather than leaving it unanswerable.
#'
#' @inheritParams atlas_palette
#' @param value A named list, or `NULL` to drop the record. Must contain
#'   `pipeline`, a single string naming what built the atlas and its version,
#'   and `created`, a single string or `Date` for when. Further fields are
#'   yours.
#'
#' @return `atlas`, with `value` as its provenance.
#'
#' @seealso [atlas_provenance()] to read one back.
#' @examples
#' atlas <- set_atlas_provenance(
#'   dk(),
#'   list(pipeline = "hand-built 1.0", created = "2026-10-29")
#' )
#' atlas_provenance(atlas)$pipeline
#' @export
set_atlas_provenance <- function(atlas, value) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  atlas_slot(atlas, "provenance") <- validate_provenance(value)
  atlas
}


#' Set the short name of an atlas
#'
#' Replaces the name an atlas is published and cited under. The counterpart to
#' [atlas_name()], and the setter that was missing from the family: a pipeline
#' that builds an atlas under a working name and renames the finished object
#' had no way to do it short of assigning the property.
#'
#' @inheritParams atlas_palette
#' @param value A single, non-missing character string.
#'
#' @return The `ggseg_atlas` with its name replaced.
#' @family atlas setters
#' @seealso [atlas_name()] to read it.
#' @export
#' @examples
#' atlas_name(set_atlas_name(aseg(), "aseg_subcortical"))
set_atlas_name <- function(atlas, value) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  if (!is.character(value) || length(value) != 1 || is.na(value)) {
    cli::cli_abort("{.arg value} must be a single, non-missing string.")
  }
  atlas_slot(atlas, "atlas") <- value
  atlas
}


#' Set the 2D geometry of an atlas
#'
#' Replaces the single `geom` slot of the atlas payload, which holds either an
#' sf data frame or a `brain_polygons` data frame. The counterpart to
#' [atlas_geom()]: the geometry pipelines in ggseg.extra rewrite geometry
#' constantly -- smoothing, eroding, reshaping -- and had to reach into the
#' payload to put the result back.
#'
#' Writing geometry does not rewrite `core`. A verb that drops regions as well
#' as geometry has to update both, and because the validator spans properties
#' that has to land in one step -- see [set_atlas_core()].
#'
#' @inheritParams atlas_palette
#' @param value An sf data frame or a `brain_polygons` data frame, keyed by
#'   `label`.
#'
#' @return The `ggseg_atlas` with its 2D geometry replaced.
#' @family atlas setters
#' @seealso [atlas_geom()] to read it.
#' @export
#' @examples
#' a <- dk()
#' identical(atlas_geom(set_atlas_geom(a, atlas_geom(a))), atlas_geom(a))
set_atlas_geom <- function(atlas, value) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  if (!is.null(value) && !is.data.frame(value)) {
    cli::cli_abort(
      "{.arg value} must be an {.cls sf} or {.cls brain_polygons} data frame."
    )
  }
  # An atlas built before the unified slot keeps geometry in a top-level `sf`
  # and may have no payload at all. Writing `geom` into that shape leaves the
  # old `sf` in place to shadow it, and the write is lost at the next
  # coercion, so upgrade first and write to the one place geometry lives.
  atlas <- atlas_input(atlas)
  data <- atlas_slot(atlas, "data")
  data$geom <- value
  atlas_slot(atlas, "data") <- data
  atlas
}


#' Set the core table of an atlas, and the palette that is keyed on it
#'
#' `core` and `palette` are keyed on the same labels, so a verb that drops or
#' renames regions changes both. The validator spans properties and runs on
#' every assignment, which means the two cannot be assigned one after the
#' other: the first assignment is checked against the stale value of the
#' other and fails. This lands them together.
#'
#' It also keeps S7 an implementation detail of this package. Without it, every
#' atlas-editing package needs `Imports: S7` and has to know that
#' `S7::props()<-` is the way to make a paired edit.
#'
#' @inheritParams atlas_palette
#' @param value A data frame with one row per region, carrying at least
#'   `region` and `label`.
#' @param palette A named character vector of colours keyed by the new
#'   `label`s, `NULL` to clear it, or `"keep"` (the default) to carry the
#'   existing palette across, dropping entries for labels that have gone.
#'
#' @return The `ggseg_atlas` with its core table, and palette, replaced.
#' @family atlas setters
#' @seealso [atlas_core()] to read it.
#' @export
#' @examples
#' a <- dk()
#' keep <- head(atlas_core(a), 10)
#' nrow(atlas_core(set_atlas_core(a, keep)))
set_atlas_core <- function(atlas, value, palette = "keep") {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  if (!is.data.frame(value)) {
    cli::cli_abort("{.arg value} must be a data.frame.")
  }

  # A legacy list has no validator spanning its slots, so assigning into one
  # accepted a duplicated label or a `hemi` outside the vocabulary in silence
  # and handed back an atlas every later check refuses. Upgrade first and the
  # invariants hold for both representations.
  atlas <- atlas_input(atlas)

  if (identical(palette, "keep")) {
    palette <- atlas_slot(atlas, "palette")
    if (!is.null(palette)) {
      palette <- palette[names(palette) %in% value$label]
    }
  }

  atlas_set_props(atlas, core = value, palette = palette)
}
