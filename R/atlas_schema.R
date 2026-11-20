#' The schema version an atlas was built against
#'
#' A serialized S7 object carries a frozen copy of its class: the properties,
#' the constructor and the validator as they stood when the object was built.
#' That is what lets an atlas saved by one release load under another, and it
#' is also the trap. Add a property to `ggseg_atlas` and an atlas built before
#' it does not merely lack the property -- reading it is a hard error, while
#' `S7::validate()` still passes, because the validator it runs is the one
#' frozen inside it. The atlas looks fine, dispatches fine, and fails only
#' when something touches the new property.
#'
#' Nothing in S7 detects that, so the atlas carries its own stamp. Every atlas
#' records the schema version it was built against; `atlas_schema_version()`
#' is what the installed `ggseg.formats` builds today. When the two differ,
#' [as_ggseg_atlas()] rebuilds the atlas through the current constructor,
#' which fills in whatever is new and revalidates against current rules.
#'
#' This matters because atlases are published, not just made: roughly 150 of
#' them live in `R/sysdata.rda` files across the atlas packages, each built by
#' whichever `ggseg.formats` was current that day, and r-universe rebuilds
#' them on its own schedule.
#'
#' @section When to bump:
#'
#' Bump `atlas_schema_version()` whenever an atlas built by the previous
#' version would be wrong, or incomplete, under the current one: a property
#' added or removed, an invariant tightened, a slot's meaning changed. Do not
#' bump for a new accessor, a new verb, or a bug fix that leaves stored data
#' alone -- a bump costs every published atlas a rebuild or an upgrade.
#'
#' @return `atlas_schema_version()` returns a single integer.
#'   `atlas_schema()` returns the version an atlas was built against, or `0L`
#'   for an atlas built before the stamp existed -- including every legacy
#'   list atlas. `atlas_schema_is_current()` returns a logical scalar.
#'
#' @param atlas a `ggseg_atlas` object
#' @name atlas_schema_version
#' @family atlas accessors
#' @seealso [as_ggseg_atlas()], which upgrades a stale atlas.
#' @examples
#' atlas_schema_version()
#' atlas_schema(dk())
#' atlas_schema_is_current(dk())
NULL

#' @rdname atlas_schema_version
#' @export
atlas_schema_version <- function() {
  1L
}

#' @rdname atlas_schema_version
#' @export
atlas_schema <- function(atlas) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  stamp <- atlas_slot(atlas, "schema")
  if (is.null(stamp) || length(stamp) != 1 || is.na(stamp)) {
    return(0L)
  }
  as.integer(stamp)
}

#' @rdname atlas_schema_version
#' @export
atlas_schema_is_current <- function(atlas) {
  is_atlas_class(atlas) && atlas_schema(atlas) == atlas_schema_version()
}


#' The complaint a stale schema deserves, or `NULL`
#'
#' Phrased for whoever is holding the atlas rather than whoever built it: the
#' person hitting this installed an atlas package built against an older
#' `ggseg.formats`, and the fix is a call, not a rebuild from source data.
#' @noRd
atlas_schema_defect <- function(atlas, arg = "atlas") {
  # Only an S7 atlas carries a frozen class, so only an S7 atlas can be stale
  # in this sense. A legacy list has no schema at all; it is reported by the
  # structural check and converted by `as_ggseg_atlas()`, which deprecates it
  # on the way through.
  if (!S7::S7_inherits(atlas, ggseg_atlas_class)) {
    return(NULL)
  }

  stamp <- atlas_schema(atlas)
  current <- atlas_schema_version()
  if (stamp == current) {
    return(NULL)
  }

  # Interpolated here rather than left for `cli_abort()`, which would evaluate
  # the braces in its caller's environment, where these locals do not exist.
  c(
    cli::format_inline(
      "{.arg {arg}} was built against atlas schema {stamp}, and this is
       {.pkg ggseg.formats} schema {current}."
    ),
    "i" = cli::format_inline(
      "Properties added since then are absent from it, and the checks it
       validates against are the ones frozen inside it."
    ),
    "i" = cli::format_inline(
      "Upgrade it with {.code as_ggseg_atlas({arg})}, which rebuilds it
       against the current schema without touching its geometry."
    )
  )
}
