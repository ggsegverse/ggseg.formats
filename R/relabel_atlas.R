#' Re-key an atlas's labels
#'
#' `label` is an atlas's join key: `core`, the palette's names and every
#' geometry payload (`geom`, `vertices`, `meshes`, `centerlines`) are keyed on
#' it. Rewriting it in one of those places and not the others silently decouples
#' geometry from metadata, which is how a renamed region ends up drawn in the
#' wrong colour or not at all, so this rewrites all of them together.
#'
#' Labels absent from `mapping` are left alone, so contextual geometry such as
#' the `cortex_` silhouette survives a partial re-key untouched.
#'
#' This is the supported way to correct an atlas's identifiers -- the operation
#' `tracula()` itself needed when its `.bbr.prep` suffix was restored. Use
#' [atlas_region_rename()] instead to change the display names in `region`,
#' which is not a join key.
#'
#' @inheritParams atlas_palette
#' @param mapping Named character vector: names are the atlas's current labels,
#'   values the replacements.
#'
#' @return The `ggseg_atlas` with `mapping` applied to `core$label`, the
#'   palette's names and every payload slot that carries a `label` column.
#' @family atlas manipulations
#' @seealso [atlas_region_rename()] to rename regions rather than re-key labels.
#' @export
#' @examples
#' a <- relabel_atlas(aseg(), c("Left-Thalamus" = "lh_thalamus"))
#' head(atlas_labels(a))
relabel_atlas <- function(atlas, mapping) {
  if (!is_atlas_class(atlas)) {
    cli::cli_abort("{.arg atlas} must be a {.cls ggseg_atlas} object.")
  }
  if (!is.character(mapping) || is.null(names(mapping))) {
    cli::cli_abort("{.arg mapping} must be a named character vector.")
  }

  remap <- function(x) {
    hit <- match(x, names(mapping))
    x[!is.na(hit)] <- unname(mapping[hit[!is.na(hit)]])
    x
  }

  core <- atlas$core
  core$label <- remap(core$label)

  palette <- atlas$palette
  names(palette) <- remap(names(palette))

  data <- atlas$data
  for (slot in names(data)) {
    if (is.data.frame(data[[slot]]) && "label" %in% names(data[[slot]])) {
      data[[slot]]$label <- remap(data[[slot]]$label)
    }
  }

  ggseg_atlas(
    atlas = atlas$atlas,
    type = atlas$type,
    palette = palette,
    core = core,
    data = data
  )
}
