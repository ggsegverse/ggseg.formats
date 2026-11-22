#' Every method this package puts on a base generic
#'
#' Collected in one file, and in the file that collates last, because a
#' top-level `S7::method()` call resolves the function it is given at source
#' time: registering `print_mesh_space` from a file that sorts before
#' `mesh_space.R` fails with "object not found".
#'
#' They are all registered through S7, including the ones for plain S3
#' classes. That is not a style choice. A package must use one mechanism per
#' base generic: S7 leaves a sentinel named `print` in the namespace when it
#' registers a method there, and `pkgload`'s unregister path resolves the
#' generic for every `S3method()` entry it finds, hits the sentinel, and
#' aborts `load_all()` with "`fn` must be a function, not a
#' <S7_generic_sentinel> object". Either mechanism alone is fine; mixing them
#' on one generic is what breaks. Verified against S7 1.0.0 and pkgload
#' 1.5.3, reduced to a two-line package.
#'
#' Registering the atlas methods against both the S7 class and the S3 class
#' means a current atlas and a legacy list atlas find the same function, and
#' that dispatch no longer depends on the order of the class vector.
#' @name atlas_methods
#' @noRd
NULL

#' The methods every atlas gets, whichever representation it is in
#'
#' Registered twice through `S7::method()`: once against the S7 class, for the
#' object this release builds, and once against the S3 class `ggseg_atlas`,
#' for the tagged list every atlas package still ships. Both point at the same
#' function, so the two representations are indistinguishable from outside.
#'
#' All of it goes through `S7::method()` rather than roxygen's `@export` on a
#' `print.ggseg_atlas()` definition. A package cannot mix the two on one base
#' generic: with an S7 method present, the `S3method()` directive lands in the
#' package's own method table and never reaches base's, where dispatch looks.
#' Nothing warns, and the symptom is quiet -- `plot()` on a legacy atlas fell
#' through to `plot.default()`, and `print()` dumped 520 lines of raw list
#' where it had shown a 22-line summary.
#'
#' Registering against an S3 class needs S7 >= 1.0.0; 0.2.x refused it, which
#' is why this was a pair of plain S3 methods and a reordered class vector
#' until now.
#' @noRd
NULL

legacy_atlas_s3 <- S7::new_S3_class("ggseg_atlas")

S7::method(print, ggseg_atlas_class) <- print_ggseg_atlas
S7::method(print, legacy_atlas_s3) <- print_ggseg_atlas

S7::method(plot, ggseg_atlas_class) <- plot_ggseg_atlas
S7::method(plot, legacy_atlas_s3) <- plot_ggseg_atlas

# nolint start: object_name_linter.
S7::method(as.list, ggseg_atlas_class) <- as_list_ggseg_atlas
S7::method(as.list, legacy_atlas_s3) <- as_list_ggseg_atlas

S7::method(as.data.frame, ggseg_atlas_class) <- as_data_frame_ggseg_atlas
S7::method(as.data.frame, legacy_atlas_s3) <- as_data_frame_ggseg_atlas
# nolint end.

S7::method(names, ggseg_atlas_class) <- function(x) S7::prop_names(x)


#' The payload classes print through S7 too
#'
#' Not because they are S7 -- they are plain tagged data frames -- but because
#' a package must use one mechanism per base generic. S7 leaves a sentinel
#' named `print` in the namespace when it registers a method there, and
#' `pkgload`'s unregister path resolves the generic for every `S3method()`
#' entry it finds, hits that sentinel and aborts `load_all()` with "`fn` must
#' be a function, not a <S7_generic_sentinel> object". One mechanism either
#' way is fine; the mix is what breaks. Verified against S7 1.0.0 and pkgload
#' 1.5.3, reduced to a two-line package.
#'
#' Registering them here rather than with `@export` also means dispatch no
#' longer depends on the order of the class vector.
#' @noRd
NULL

S7::method(print, S7::new_S3_class("brain_polygons")) <- print_brain_polygons
S7::method(print, S7::new_S3_class("ggseg_sf")) <- print_ggseg_sf
S7::method(print, S7::new_S3_class("ggseg_vertices")) <- print_ggseg_vertices
S7::method(print, S7::new_S3_class("ggseg_meshes")) <- print_ggseg_meshes
S7::method(print, S7::new_S3_class("mesh_space")) <- print_mesh_space
S7::method(print, S7::new_S3_class("ggseg_centerlines")) <-
  print_ggseg_centerlines
S7::method(print, S7::new_S3_class("ggseg_data_cortical")) <-
  print_ggseg_data_cortical
S7::method(print, S7::new_S3_class("ggseg_data_subcortical")) <-
  print_ggseg_data_subcortical
S7::method(print, S7::new_S3_class("ggseg_data_cerebellar")) <-
  print_ggseg_data_cerebellar
S7::method(print, S7::new_S3_class("ggseg_data_tract")) <-
  print_ggseg_data_tract
