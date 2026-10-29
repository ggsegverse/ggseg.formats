# The core schema's three name columns ----
#
# `label`, `region` and `display` each answer a different question, and an
# atlas that blurs them is unusable for joining results across parcellations.
# This file holds the contract and the accessors that let a consumer ask
# which of the two `region` conventions an atlas follows, rather than
# testing for it.

#' What an atlas's three name columns mean
#'
#' Every `ggseg_atlas` keys its `core` on three columns, and they are not
#' interchangeable.
#'
#' \describe{
#'   \item{`label`}{The canonical key. Unique within the atlas, carries the
#'     hemisphere, and is what user data joins on and what a palette is keyed
#'     by. Never derived from the others.}
#'   \item{`display`}{The best human-readable name for the region: what a
#'     legend or an axis should show. It exists because `region` is derived
#'     and lossy -- deriving it lowercases and replaces punctuation, so
#'     `L_V1_ROI` becomes `v1 roi` and the published name is gone.
#'
#'     Two kinds occur, and both are legitimate. Usually it is the source's
#'     own name, verbatim, with the hemisphere affix the pipeline added
#'     taken back off. Sometimes it is curated: `dk` publishes
#'     `banks of superior temporal sulcus` for the label `lh_bankssts`,
#'     which is editorial knowledge no amount of stripping would recover.
#'     [migrate_atlas_display()] therefore fills the column and never
#'     replaces it.}
#'   \item{`region`}{A grouping key, derived from `display`. Whether it
#'     aggregates across hemispheres depends on the source, which is what
#'     [atlas_region_semantics()] reports.}
#' }
#'
#' # The two conventions for `region`
#'
#' A parcellation that names its structures anatomically gives both
#' hemispheres the same name, so `region` aggregates them and `hemi`
#' disambiguates: grouping by `region` gives one row per structure.
#'
#' A parcellation that numbers its parcels does not. `region_0001` and
#' `region_0002` are two different parcels, not one structure seen twice,
#' and no hemisphere-free name exists to recover -- the source never gave
#' one. There `region` is 1:1 with `label` and grouping by it aggregates
#' nothing.
#'
#' Both are correct for their source. What was missing was a way to ask
#' which you have, short of testing whether any name is shared across
#' hemispheres. [atlas_region_semantics()] is that question.
#'
#' @name core_contract
#' @seealso [atlas_region_semantics()], [atlas_display()], [atlas_context()]
NULL


#' Does this atlas's `region` aggregate across hemispheres?
#'
#' Answers which of the two conventions described in [core_contract] an
#' atlas follows, so a consumer joining results across parcellations does
#' not have to work it out.
#'
#' Computed from `core` rather than stored, so it cannot disagree with the
#' data it describes: a stored flag would be one more thing to keep true
#' through every verb that edits an atlas.
#'
#' @param atlas A `ggseg_atlas`.
#' @return One of:
#'   \describe{
#'     \item{`"shared"`}{`region` names are shared between the hemispheres,
#'       so grouping by `region` aggregates a structure across sides.}
#'     \item{`"per-hemisphere"`}{No name is shared, so `region` is 1:1 with
#'       `label` and grouping by it aggregates nothing.}
#'     \item{`"unilateral"`}{The atlas has fewer than two lateral
#'       hemispheres, so the question does not arise.}
#'   }
#' @examples
#' atlas_region_semantics(dk())
#' atlas_region_semantics(aseg())
#' @export
atlas_region_semantics <- function(atlas) {
  assert_ggseg_atlas(atlas)
  core <- as.data.frame(atlas$core)
  hemi <- as.character(core$hemi)
  sides <- setdiff(unique(hemi[!is.na(hemi)]), "midline")
  if (length(sides) < 2L) {
    return("unilateral")
  }
  region <- as.character(core$region)
  shared <- intersect(region[hemi == sides[1]], region[hemi == sides[2]])
  if (length(shared) > 0L) "shared" else "per-hemisphere"
}


#' The labels an atlas draws but does not treat as regions
#'
#' Anatomical backdrop -- a cortical silhouette behind subcortical
#' structures, an unlabelled medial wall -- is geometry without a `core`
#' row. It is drawn in grey, it is not in the legend, and it is not
#' something user data joins to.
#'
#' Returns the labels rather than leaving every caller to compute the set
#' difference or, worse, match on a name. Build scripts had been writing
#' `labels = "^cortex"`, which silently matched nothing for as long as a
#' pipeline bug left the backdrop undrawn.
#'
#' @param atlas A `ggseg_atlas`.
#' @return Character vector of labels, empty when the atlas draws no
#'   backdrop.
#' @examples
#' atlas_context(aseg())
#' @export
atlas_context <- function(atlas) {
  assert_ggseg_atlas(atlas)
  drawn <- drawn_labels(atlas)
  setdiff(drawn, as.character(atlas$core$label))
}


#' Give an atlas built before `display` existed its display names
#'
#' `display` holds the source's own name for a region, and an atlas built
#' before the column existed looks as though that name is lost. It is not:
#' `label` is the source name with a hemisphere affix on it, so the display
#' name is recoverable exactly. Verified against every atlas that already
#' carries the column -- 1996 rows, no disagreement.
#'
#' Atlases that already carry `display` are returned unchanged, so this is
#' safe to run over a whole library.
#'
#' @param atlas A `ggseg_atlas`.
#' @param overwrite Replace an existing `display` column. Off by default,
#'   because an atlas that carries one got it from its source, and the
#'   source's own name beats one derived from a key.
#' @return `atlas`, with `display` in `core`.
#' @examples
#' atlas <- dk()
#' atlas$core$display <- NULL
#' atlas_display(migrate_atlas_display(atlas))[1:3]
#' @export
migrate_atlas_display <- function(atlas, overwrite = FALSE) {
  assert_ggseg_atlas(atlas)
  if ("display" %in% names(atlas$core) && !overwrite) {
    return(atlas)
  }
  core <- atlas$core
  core$display <- strip_hemi_affix(as.character(core$label))
  rebuild_atlas_core(atlas, core)
}


#' Map a legacy `hemi` spelling onto the vocabulary
#'
#' `hemi` is a closed vocabulary -- `"left"`, `"right"`, `"midline"` or `NA`
#' -- and two spellings predate it. `"middle"` was an earlier name for the
#' midline, and `"vermis"` is a cerebellar structure rather than a side, so
#' both map onto `"midline"`. The finer distinction belongs in a column of
#' its own.
#'
#' An atlas carrying one cannot be constructed, so it cannot be passed
#' through any verb that validates -- including
#' [migrate_atlas_display()]. This repairs `core` directly for that reason.
#'
#' @param atlas A `ggseg_atlas`, or a list shaped like one that no longer
#'   validates.
#' @return `atlas`, with `hemi` in the vocabulary.
#' @examples
#' atlas <- dk()
#' atlas$core$hemi[1] <- "middle"
#' unique(migrate_atlas_hemi(atlas)$core$hemi)
#' @export
migrate_atlas_hemi <- function(atlas) {
  if (!is.list(atlas) || is.null(atlas$core)) {
    cli::cli_abort("{.arg atlas} must be a list with a {.field core}.")
  }
  hemi <- as.character(atlas$core$hemi)
  atlas$core$hemi <- legacy_hemi_map[hemi] |>
    unname() |>
    (\(mapped) ifelse(is.na(mapped), hemi, mapped))()
  atlas
}

#' Legacy `hemi` spellings and what they mean
#' @noRd
legacy_hemi_map <- c(
  middle = "midline",
  vermis = "midline",
  mid = "midline"
)


#' Select an atlas's backdrop, or its regions, in a geometry verb
#'
#' The geometry verbs take `labels` and `exclude` as patterns, and a
#' backdrop has to be addressed separately from the parcels: what makes a
#' cortical silhouette read as a brain is its sulci, which are fine detail,
#' so it wants gentler simplification and a smoothing method that does not
#' fill them.
#'
#' Build scripts had been writing the pattern by hand, as `"^cortex"`. That
#' is a guess about what the pipeline named the backdrop, and it was wrong
#' twice over: the name varies across the library -- `cortex_`, `cortex`,
#' `lh_unknown`, `lh_Background+FreeSurfer_Defined_Medial_Wall` -- and a
#' pattern matching nothing is silent, so those steps did nothing at all for
#' as long as a pipeline bug left the backdrop undrawn.
#'
#' These ask the atlas instead. The lookup table decides what is backdrop
#' when the atlas is built; this is how that decision is read back.
#'
#' @return A function of an atlas returning a pattern, which `labels` and
#'   `exclude` accept.
#' @name selectors
#' @examples
#' # gentler on the backdrop than on the parcels
#' \dontrun{
#' atlas |>
#'   atlas_simplify(keep = 0.5, labels = context()) |>
#'   atlas_simplify(keep = 0.25, exclude = context())
#' }
#' @rdname selectors
#' @seealso [atlas_context()]
#' @export
context <- function() {
  function(atlas) {
    labels_to_pattern(atlas_context(atlas))
  }
}


#' @rdname selectors
#' @export
regions <- function() {
  function(atlas) {
    labels_to_pattern(as.character(atlas$core$label))
  }
}


#' The regions an atlas names but never draws
#'
#' A region in `core` with no geometry in any view is invisible: it joins,
#' it carries a colour, and nothing appears. It is the failure mode of
#' choosing which slabs to keep, and it is silent -- the atlas validates,
#' plots without complaint, and simply omits the region.
#'
#' Build scripts narrow a pipeline's slabs to the few that read well. That
#' choice is a measurement of the geometry underneath it, so it goes stale
#' when the geometry changes. Asserting on this after the narrowing turns a
#' silent omission into a failed build.
#'
#' @param atlas A `ggseg_atlas`.
#' @return The `core` labels with no geometry in any view, as a character
#'   vector; empty when every region is drawn somewhere.
#' @seealso [atlas_view_keep()] and [atlas_view_remove()], which narrow the
#'   views this checks.
#' @examples
#' atlas_undrawn(aseg())
#' @export
#' @family atlas accessors
atlas_undrawn <- function(atlas) {
  if (!is_ggseg_atlas(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas}.")
  }
  setdiff(as.character(atlas$core$label), drawn_labels(atlas))
}


#' Every label an atlas's 2D geometry draws, whichever backend holds it
#' @noRd
drawn_labels <- function(atlas) {
  poly <- data_poly(atlas$data)
  if (!is.null(poly)) {
    return(unique(as.character(poly$label)))
  }
  sf_data <- data_sf(atlas$data)
  if (!is.null(sf_data)) {
    return(unique(as.character(sf_data$label)))
  }
  character(0)
}


#' Strip the hemisphere affix a label carries over its source name
#'
#' A label is the source's own name with a hemisphere affix put on it by the
#' pipeline, so taking that affix off recovers the source name exactly.
#'
#' One leading affix and one trailing one come off, which is what produced
#' every display name in the library today. The rule is asymmetric on
#' purpose: a leading affix may be the source's own, as in Glasser's
#' `L_V1_ROI` under the label `lh_L_V1_ROI`, and only the pipeline's is
#' taken, so the display name is `L_V1_ROI` and not `V1_ROI`. A trailing one
#' is taken, so `G_Frontal_Sup-1-L` becomes `G_Frontal_Sup-1` and both
#' hemispheres read the same in a legend, where `hemi` tells them apart.
#'
#' Stripping until nothing
#' is left would invent a name the source never used, and for a parcellation
#' that names its parcels per hemisphere it would invent a correspondence
#' between two unrelated parcels. Such an atlas is per-hemisphere by its
#' source's choice, which [atlas_region_semantics()] reports rather than
#' strips away.
#'
#' Never strips a name to nothing: a structure genuinely called `Left` keeps
#' its name.
#' @param label Character vector of labels.
#' @noRd
strip_hemi_affix <- function(label) {
  prefix <- paste0(
    "^(Left|Right|left|right|LEFT|RIGHT|lh|rh|LH|RH|L|R|",
    "Vermis|vermis|Midline|midline)[-_. ]+"
  )
  suffix <- "[-_. ]+(left|right|lh|rh|l|r|vermis|midline)$"
  out <- sub(prefix, "", label)
  out <- sub(suffix, "", out, ignore.case = TRUE)
  ifelse(nzchar(out), out, label)
}


#' Replace an atlas's core, keeping everything else
#' @noRd
rebuild_atlas_core <- function(atlas, core) {
  ggseg_atlas(
    atlas = atlas$atlas,
    type = atlas$type,
    core = core,
    data = atlas$data,
    palette = atlas$palette,
    provenance = atlas$provenance
  )
}


#' An anchored alternation matching exactly these labels
#'
#' A label may hold regex metacharacters -- the FreeSurfer medial wall is
#' spelled `Background+FreeSurfer_Defined_Medial_Wall` -- so each is escaped
#' before it goes into the pattern.
#'
#' An empty set has to match nothing, where `"^(|)$"` would match everything
#' and quietly polish the parcels with the backdrop's settings. `"$x"` is a
#' character after the end of the string, which nothing satisfies, and
#' unlike a negative lookahead it is valid in the default engine.
#' @noRd
labels_to_pattern <- function(labels) {
  if (length(labels) == 0L) {
    return("$x")
  }
  escaped <- gsub("([][^$.|?*+(){}\\])", "\\\\\\1", labels)
  paste0("^(", paste(escaped, collapse = "|"), ")$")
}


#' Resolve a label selector to a pattern
#'
#' `labels` and `exclude` take a pattern, or a function of the atlas
#' returning one -- which is what [context()] and [regions()] are.
#' @noRd
resolve_label_pattern <- function(selector, atlas) {
  if (!is.function(selector)) {
    return(selector)
  }
  pattern <- selector(atlas)
  if (!is.character(pattern) || length(pattern) != 1L) {
    cli::cli_abort(c(
      "A function given as {.arg labels} or {.arg exclude} must return one
      pattern.",
      "x" = "It returned {.obj_type_friendly {pattern}}."
    ))
  }
  pattern
}
