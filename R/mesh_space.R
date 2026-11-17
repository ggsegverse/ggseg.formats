#' Record what a mesh's coordinates mean
#'
#' A surface mesh on its own is just numbers: nothing in `vertices` says which
#' hemisphere it is, which vertex space an atlas must have been built against
#' to index it, or how to get from its coordinates to a standard space. Without
#' that, consumers infer those things, and a mesh inferred wrongly still renders
#' perfectly -- a brain mirrored left-to-right, or regions painted at the wrong
#' vertices, looks like a brain. `mesh_space()` makes the mesh state them.
#'
#' @details
#' `vertex_space` is the mesh's identity as far as atlases are concerned.
#' Atlases key regions to vertex indices, so an atlas built against one vertex
#' space and drawn on another puts every region somewhere else. Checking that
#' indices merely fit catches only the case where the other mesh is smaller.
#'
#' Name a *numbered* space -- `"fsaverage5"`, `"fsaverage6"` -- because those
#' are fixed templates and stable across FreeSurfer releases: `fsaverage5` is
#' vertex-for-vertex the same mesh in 7.4.1 and 8.2.0, which is what makes an
#' atlas's indices portable. Unnumbered `"fsaverage"` is not a stable
#' identifier: it is whichever densest mesh that release ships, so the same
#' string can mean different vertex counts and different indices. Record
#' `source` if you must use it.
#'
#' `hemi` is recorded because left and right are the one distinction this
#' ecosystem must never get wrong, and a mesh that cannot state its own side
#' cannot be checked against the data drawn on it.
#'
#' `to_mni305` is a 4x4 affine mapping the mesh's own vertex coordinates to
#' MNI305, collapsing any axis permutation, sign flip and translation into one
#' matrix. It is required when `anatomical` is `TRUE` and must be `NULL`
#' otherwise: inflation and spherical registration move every vertex, so those
#' surfaces have no anatomical position to map to and a matrix for them would
#' be a number that looks usable.
#'
#' Positioning a mesh for display -- moving a hemisphere to meet the midline,
#' say -- is the renderer's decision, not a property of the mesh, so it is
#' deliberately not recorded here.
#'
#' @param vertex_space Vertex space the mesh is in, such as `"fsaverage5"`.
#'   Atlas vertex indices are only meaningful against a named space.
#' @param hemi `"left"`, `"right"` or `"midline"`.
#' @param anatomical Whether the coordinates correspond to positions in a
#'   brain. `FALSE` for inflated and spherical surfaces.
#' @param to_mni305 A 4x4 matrix mapping vertex coordinates to MNI305, or
#'   `NULL` when `anatomical` is `FALSE`.
#' @param units Coordinate units. Millimetres throughout the ecosystem.
#' @param surface Optional surface name, such as `"pial"`.
#' @param source Optional free-text note on where the mesh came from, for
#'   reproducibility. Never read by code; [atlas_provenance()] remains the
#'   authoritative record.
#'
#' @return A `mesh_space` object, to be attached with [set_mesh_space()].
#' @family mesh spaces
#' @export
#' @examples
#' mesh_space(
#'   vertex_space = "fsaverage5",
#'   hemi = "left",
#'   anatomical = FALSE
#' )
mesh_space <- function(
  vertex_space,
  hemi,
  anatomical,
  to_mni305 = NULL,
  units = "mm",
  surface = NULL,
  source = NULL
) {
  check_vertex_space(vertex_space)
  check_mesh_hemi(hemi)
  check_anatomical(anatomical)
  to_mni305 <- check_to_mni305(to_mni305, anatomical)
  check_units(units)
  check_optional_string(surface, "surface")
  check_optional_string(source, "source")

  structure(
    list(
      schema_version = mesh_space_schema_version(),
      vertex_space = vertex_space,
      hemi = hemi,
      anatomical = anatomical,
      to_mni305 = to_mni305,
      units = units,
      surface = surface,
      source = source
    ),
    class = "mesh_space"
  )
}


#' Attach or read a mesh's coordinate record
#'
#' @param mesh A list with `vertices` and `faces`.
#' @param space A [mesh_space()] object.
#'
#' @return `set_mesh_space()` returns `mesh` with the record attached.
#'   `get_mesh_space()` returns the record, or `NULL` when the mesh carries
#'   none -- meshes from outside the core packages legitimately do not.
#' @family mesh spaces
#' @export
#' @examples
#' mesh <- get_brain_mesh("lh")
#' space <- mesh_space("fsaverage5", "left", anatomical = FALSE)
#' mesh <- set_mesh_space(mesh, space)
#' get_mesh_space(mesh)$vertex_space
set_mesh_space <- function(mesh, space) {
  if (!inherits(space, "mesh_space")) {
    cli::cli_abort(
      "{.arg space} must be a {.cls mesh_space}, not
       {.obj_type_friendly {space}}."
    )
  }
  attr(mesh, "mesh_space") <- space
  mesh
}


#' @rdname set_mesh_space
#' @export
get_mesh_space <- function(mesh) {
  attr(mesh, "mesh_space")
}


#' @export
print.mesh_space <- function(x, ...) {
  cli::cli_text("{.cls mesh_space} (v{x$schema_version})")
  cli::cli_bullets(c(
    "*" = "vertex space: {.val {x$vertex_space}}",
    "*" = "hemisphere: {.val {x$hemi}}",
    "*" = if (x$anatomical) {
      "anatomical, mapped to MNI305"
    } else {
      "not anatomical, no MNI305 mapping"
    },
    "*" = "units: {.val {x$units}}"
  ))
  if (!is.null(x$surface)) {
    cli::cli_bullets(c("*" = "surface: {.val {x$surface}}"))
  }
  if (!is.null(x$source)) {
    cli::cli_bullets(c("*" = "source: {x$source}"))
  }
  invisible(x)
}


#' Build a mesh that describes itself
#'
#' Assembles vertices, faces and a [mesh_space()] into one object, checking
#' they agree. Reading a surface file and assembling the pieces by hand is
#' done in several places across the ecosystem, and each one decided
#' independently whether faces were counted from 0 or from 1 -- which is why
#' `ggseg.formats` inflated surfaces are 0-based, `ggseg.meshes` cortical
#' surfaces are 1-based, and consumers carry code to cope. Declaring the base
#' and having it checked makes that disagreement impossible to introduce
#' again.
#'
#' @details
#' `face_index_base` has no default on purpose. A default would be a fourth
#' independent decision, and the point is that the caller states what their
#' file actually contains.
#'
#' The faces are checked against the base rather than taken on trust: the
#' smallest index must equal the base and the largest must be the last vertex
#' counted from it. A mesh that declares 0 while holding 1-based indices
#' renders with one vertex silently misplaced and the last face out of range,
#' which is the failure this refuses.
#'
#' @param vertices A data.frame of `x`, `y`, `z`.
#' @param faces A data.frame of `i`, `j`, `k`.
#' @param space A [mesh_space()] describing what the coordinates mean.
#' @param face_index_base `0L` or `1L` -- the number the file's face indices
#'   count from. Required.
#'
#' @return A list of `vertices` and `faces`, carrying `mesh_space` and
#'   `face_index_base` attributes.
#' @family mesh spaces
#' @export
#' @examples
#' brain_mesh(
#'   vertices = data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0)),
#'   faces = data.frame(i = 0L, j = 1L, k = 2L),
#'   space = mesh_space("fsaverage5", "left", anatomical = FALSE),
#'   face_index_base = 0L
#' )
brain_mesh <- function(vertices, faces, space, face_index_base) {
  check_mesh_vertices(vertices)
  check_mesh_faces(faces)
  base <- check_face_index_base(face_index_base)
  check_faces_match_base(faces, vertices, base)

  mesh <- list(vertices = vertices, faces = faces)
  attr(mesh, "face_index_base") <- base
  set_mesh_space(mesh, space)
}


#' Version of the mesh_space schema
#'
#' Recorded on every object so a reader can tell which fields to expect rather
#' than testing each one for absence.
#' @noRd
mesh_space_schema_version <- function() {
  1L
}


#' @noRd
check_vertex_space <- function(space, call = rlang::caller_env()) {
  if (
    !is.character(space) ||
      length(space) != 1L ||
      is.na(space) ||
      !nzchar(space)
  ) {
    cli::cli_abort(
      c(
        "{.arg vertex_space} must be a single non-empty string.",
        "i" = "Atlas vertex indices only mean something against a named
               space, such as {.val fsaverage5}."
      ),
      call = call
    )
  }
  invisible(space)
}


#' @noRd
check_mesh_hemi <- function(hemi, call = rlang::caller_env()) {
  allowed <- c("left", "right", "midline")
  if (!is.character(hemi) || length(hemi) != 1L || !hemi %in% allowed) {
    cli::cli_abort(
      c(
        "{.arg hemi} must be one of {.val {allowed}}.",
        "i" = "A mesh that cannot state its own side cannot be checked
               against the data drawn on it."
      ),
      call = call
    )
  }
  invisible(hemi)
}


#' @noRd
check_anatomical <- function(anatomical, call = rlang::caller_env()) {
  if (
    !is.logical(anatomical) || length(anatomical) != 1L || is.na(anatomical)
  ) {
    cli::cli_abort(
      "{.arg anatomical} must be {.val {TRUE}} or {.val {FALSE}}.",
      call = call
    )
  }
  invisible(anatomical)
}


#' @noRd
check_units <- function(units, call = rlang::caller_env()) {
  if (!identical(units, "mm")) {
    cli::cli_abort(
      "{.arg units} must be {.val mm}; the ecosystem has no other unit.",
      call = call
    )
  }
  invisible(units)
}


#' @noRd
check_optional_string <- function(x, arg, call = rlang::caller_env()) {
  if (is.null(x)) {
    return(invisible(NULL))
  }
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single string or {.code NULL}.",
      call = call
    )
  }
  invisible(x)
}


#' @noRd
check_to_mni305 <- function(to_mni305, anatomical, call = rlang::caller_env()) {
  if (!isTRUE(anatomical)) {
    if (!is.null(to_mni305)) {
      cli::cli_abort(
        c(
          "{.arg to_mni305} must be {.code NULL} when {.arg anatomical} is
           {.val {FALSE}}.",
          "x" = "Inflation and spherical registration move every vertex, so
                 these surfaces have no anatomical position to map to.",
          "i" = "A matrix here would be a number that looks usable."
        ),
        call = call
      )
    }
    return(NULL)
  }

  if (is.null(to_mni305)) {
    cli::cli_abort(
      c(
        "{.arg to_mni305} is required when {.arg anatomical} is {.val {TRUE}}.",
        "i" = "Without it a consumer has to infer the mapping, and a mesh
               mapped wrongly still renders."
      ),
      call = call
    )
  }

  if (!is.matrix(to_mni305) || !identical(dim(to_mni305), c(4L, 4L))) {
    cli::cli_abort(
      "{.arg to_mni305} must be a 4x4 matrix.",
      call = call
    )
  }

  if (!is.numeric(to_mni305) || anyNA(to_mni305)) {
    cli::cli_abort(
      "{.arg to_mni305} must be numeric and complete.",
      call = call
    )
  }

  if (!isTRUE(all.equal(to_mni305[4L, ], c(0, 0, 0, 1)))) {
    cli::cli_abort(
      c(
        "{.arg to_mni305} must have {.code c(0, 0, 0, 1)} as its last row.",
        "i" = "An affine whose last row differs is not a coordinate
               transform."
      ),
      call = call
    )
  }

  if (isTRUE(all.equal(det(to_mni305[1:3, 1:3]), 0))) {
    cli::cli_abort(
      c(
        "{.arg to_mni305} must be invertible.",
        "x" = "Its rotation block is singular, so it collapses the mesh onto
               a plane or a line and cannot be inverted to place a point."
      ),
      call = call
    )
  }

  to_mni305
}


#' @noRd
check_mesh_vertices <- function(vertices, call = rlang::caller_env()) {
  if (!is.data.frame(vertices) || !all(c("x", "y", "z") %in% names(vertices))) {
    cli::cli_abort(
      "{.arg vertices} must be a data frame with {.field x}, {.field y} and
       {.field z}.",
      call = call
    )
  }
  if (!nrow(vertices)) {
    cli::cli_abort("{.arg vertices} must have at least one row.", call = call)
  }
  invisible(vertices)
}


#' @noRd
check_mesh_faces <- function(faces, call = rlang::caller_env()) {
  if (!is.data.frame(faces) || !all(c("i", "j", "k") %in% names(faces))) {
    cli::cli_abort(
      "{.arg faces} must be a data frame with {.field i}, {.field j} and
       {.field k}.",
      call = call
    )
  }
  if (!nrow(faces)) {
    cli::cli_abort("{.arg faces} must have at least one row.", call = call)
  }
  invisible(faces)
}


#' @noRd
check_face_index_base <- function(base, call = rlang::caller_env()) {
  if (length(base) != 1L || is.na(base) || !base %in% c(0L, 1L)) {
    cli::cli_abort(
      c(
        "{.arg face_index_base} must be {.val {0L}} or {.val {1L}}.",
        "i" = "There is no default: the ecosystem genuinely holds both, and
               guessing is what made them disagree."
      ),
      call = call
    )
  }
  as.integer(base)
}


#' @noRd
check_faces_match_base <- function(
  faces,
  vertices,
  base,
  call = rlang::caller_env()
) {
  indices <- unlist(faces[c("i", "j", "k")], use.names = FALSE)
  lowest <- min(indices)
  highest <- max(indices)
  expected_highest <- nrow(vertices) - 1L + base

  if (lowest != base || highest != expected_highest) {
    cli::cli_abort(
      c(
        "The faces do not count from {.val {base}}.",
        "x" = "They run {lowest} to {highest}; {.val {base}}-based faces over
               {nrow(vertices)} vertices run {base} to {expected_highest}.",
        "i" = "Declaring the wrong base misplaces a vertex and puts the last
               face out of range."
      ),
      call = call
    )
  }
  invisible(faces)
}
