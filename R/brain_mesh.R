#' Get brain surface mesh
#'
#' Retrieves a brain surface mesh for the specified hemisphere and surface type.
#' By default, provides the inflated fsaverage5 surface from internal data.
#' Other surfaces (pial, white, semi-inflated) require the ggseg3d package.
#'
#' @param hemisphere `"lh"` or `"rh"`
#' @param surface Surface type (default `"inflated"`). Other surfaces require
#'   ggseg3d or a custom `brain_meshes` argument.
#' @param brain_meshes Optional user-supplied mesh data. Accepts either
#'   `list(lh = list(vertices, faces), rh = ...)` or the legacy
#'   `list(lh_inflated = list(vertices, faces), ...)` format.
#'
#' @return A list with `vertices` (data.frame with x, y, z) and `faces`
#'   (data.frame with i, j, k), or NULL if the mesh is not available. The face
#'   indices of the bundled inflated surfaces are **0-based** (0 to
#'   `nrow(vertices) - 1`), matching [get_cerebellar_mesh()]. Per-region
#'   subcortical meshes from [ggseg_data_subcortical()] are 1-based instead, and
#'   a user-supplied `brain_meshes` is returned exactly as given, so a consumer
#'   must not assume a single base across mesh sources.
#' @export
#' @examples
#' mesh <- get_brain_mesh("lh")
#' head(mesh$vertices)
get_brain_mesh <- function(
  hemisphere = c("lh", "rh"),
  surface = "inflated",
  brain_meshes = NULL
) {
  hemisphere <- match.arg(hemisphere)

  if (!is.null(brain_meshes)) {
    mesh <- brain_meshes[[hemisphere]]
    if (is.null(mesh)) {
      mesh <- brain_meshes[[paste(hemisphere, surface, sep = "_")]]
    }
    return(mesh)
  }

  if (surface == "inflated") {
    return(brain_mesh_inflated[[hemisphere]])
  }

  cli::cli_abort(c(
    "Surface {.val {surface}} not available in {.pkg ggseg.formats}.",
    "i" = "Install {.pkg ggseg3d}, or pass custom {.arg brain_meshes}."
  ))
}


#' Get SUIT cerebellar surface mesh
#'
#' Retrieves the shared SUIT cerebellar surface mesh used for vertex-based
#' cerebellar atlas rendering. The mesh contains 28,935 original surface
#' vertices plus 1,078 additional vertices forming a cap over the
#' peduncular surface (where the cerebellum meets the brainstem). The cap
#' vertices (indices 28,935--30,012) are duplicates of the boundary loop
#' and a centroid, designed to render as an opaque grey wall when not
#' assigned to any atlas region.
#'
#' @return A list with `vertices` (data.frame with x, y, z) and `faces`
#'   (data.frame with i, j, k, 0-based indices).
#' @export
#' @examples
#' mesh <- get_cerebellar_mesh()
#' nrow(mesh$vertices)
get_cerebellar_mesh <- function() {
  cerebellar_mesh_suit
}
