# Atlas migration helper for downstream maintainers ----

#' Migrate atlas `.rda` files to the sf-optional polygon format
#'
#' Walks a directory of `.rda` files, finds every `ggseg_atlas` object inside
#' them, and rewrites their 2D geometry into the single `geom` slot. By default
#' the geometry is stored as `brain_polygons` (sf-optional); any legacy `sf` /
#' `polygons` slots are dropped. Pass `keep_sf = TRUE` to store the geometry as
#' sf instead.
#'
#' Intended for downstream atlas-package maintainers across the ggsegverse
#' ecosystem: run once against your `data/` directory, then drop `sf` from
#' DESCRIPTION Imports.
#'
#' @param path Directory containing `.rda` files to migrate. Defaults to
#'   `"data"`, the conventional location in R packages.
#' @param keep_sf If `TRUE`, the geometry is stored in `geom` as sf. Default
#'   `FALSE` — the geometry is stored as `brain_polygons` (sf-optional).
#' @param quiet If `TRUE`, suppress per-file status messages.
#' @param force If `TRUE`, migrate even when the conversion cannot carry every
#'   geometry column across. The default `FALSE` aborts instead, naming the
#'   columns and the file, because the files are rewritten in place.
#'
#' @return Invisibly, a character vector of paths to the files that were
#'   rewritten.
#' @export
#' @examplesIf requireNamespace("sf", quietly = TRUE)
#' # In an atlas package you would call this on the package's own data/
#' # directory. Here it runs against a throwaway copy, since it rewrites the
#' # files it is pointed at. Producing an sf atlas to migrate needs sf.
#' dir <- file.path(tempdir(), "data")
#' dir.create(dir, showWarnings = FALSE)
#' dk_atlas <- as_sf_atlas(dk())
#' save(dk_atlas, file = file.path(dir, "dk_atlas.rda"))
#'
#' migrate_atlas_files(dir, quiet = TRUE)
#'
#' load(file.path(dir, "dk_atlas.rda"))
#' is_atlas_polygon(dk_atlas) # TRUE
#' unlink(dir, recursive = TRUE)
migrate_atlas_files <- function(
  path = "data",
  keep_sf = FALSE,
  quiet = FALSE,
  force = FALSE
) {
  if (!dir.exists(path)) {
    cli::cli_abort("Directory {.path {path}} does not exist.")
  }

  rda_files <- list.files(path, pattern = "\\.rda$", full.names = TRUE)
  if (length(rda_files) == 0) {
    if (!quiet) {
      cli::cli_warn("No {.code .rda} files found in {.path {path}}.")
    }
    return(invisible(character()))
  }

  migrated <- character()
  for (f in rda_files) {
    if (migrate_rda_file(f, keep_sf, force = force)) {
      migrated <- c(migrated, f)
      if (!quiet) {
        cli::cli_alert_success("Migrated {.file {basename(f)}}.")
      }
    } else if (!quiet) {
      cli::cli_alert_info(
        "Skipped {.file {basename(f)}} (nothing to migrate)."
      )
    }
  }

  invisible(migrated)
}


#' Geometry representation a migration should write
#'
#' `keep_sf` stores sf; otherwise `brain_polygons`. Geometry already in the
#' target representation is returned unchanged.
#' @noRd
#' @keywords internal
migration_target_geom <- function(geom, keep_sf) {
  if (keep_sf) {
    if (inherits(geom, "brain_polygons")) polygons_to_sf(geom) else geom
  } else {
    # check_migration_loss() has already reported the dropped columns, with the
    # file and object named, so the converter's own warning is redundant here.
    withCallingHandlers(
      if (inherits(geom, "sf")) sf_to_polygons(geom) else geom,
      ggseg_dropped_columns = function(w) {
        invokeRestart("muffleWarning")
      }
    )
  }
}


#' Migrate one loaded object to the single `geom` slot
#'
#' Returns the rewritten object, or `NULL` when the object is not a migratable
#' atlas, has no 2D geometry, or is already in the target form.
#' @noRd
#' @keywords internal
migrate_atlas_object <- function(obj, keep_sf) {
  if (!is_atlas_for_migration(obj)) {
    return(NULL)
  }
  geom <- geom_from_data(obj$data)
  if (is.null(geom)) {
    return(NULL)
  }
  target <- migration_target_geom(geom, keep_sf)
  already_migrated <- identical(obj$data$geom, target) &&
    is.null(obj$data$sf) &&
    is.null(obj$data$polygons)
  if (already_migrated) {
    return(NULL)
  }
  obj$data$geom <- target
  obj$data$sf <- NULL
  obj$data$polygons <- NULL
  obj
}


#' Migrate every atlas object in one `.rda` file in place
#'
#' Returns `TRUE` if the file was rewritten, `FALSE` if nothing changed.
#' @noRd
#' @keywords internal
migrate_rda_file <- function(f, keep_sf, force = FALSE) {
  env <- new.env(parent = emptyenv())
  nms <- load(f, envir = env)
  changed <- FALSE
  for (nm in nms) {
    check_migration_loss(
      migration_lost_columns(env[[nm]], keep_sf),
      file = f,
      object = nm,
      force = force
    )
    migrated <- migrate_atlas_object(env[[nm]], keep_sf)
    if (!is.null(migrated)) {
      env[[nm]] <- migrated
      changed <- TRUE
    }
  }
  if (changed) {
    save(list = nms, file = f, envir = env, compress = "xz")
  }
  changed
}


#' Lightweight class check used by migrate_atlas_files()
#'
#' Avoids the structural revalidation in [is_ggseg_atlas()] so that legacy
#' cached objects can be migrated even if their layout has drifted.
#' @noRd
#' @keywords internal
is_atlas_for_migration <- function(x) {
  is_atlas_class(x) &&
    is.list(x) &&
    !is.null(x$data) &&
    is.list(x$data)
}


#' Columns a migration of one loaded object cannot carry across
#'
#' Returns `character()` for objects the migration skips anyway.
#' @noRd
#' @keywords internal
migration_lost_columns <- function(obj, keep_sf) {
  if (!is_atlas_for_migration(obj)) {
    return(character())
  }
  geom <- geom_from_data(obj$data)
  if (is.null(geom)) {
    return(character())
  }
  if (!keep_sf && inherits(geom, "sf")) {
    return(reserved_coord_columns(geom))
  }
  if (keep_sf && inherits(geom, "brain_polygons")) {
    return(varying_feature_columns(geom))
  }
  character()
}


#' Nested polygon columns that vary within one label x view feature
#'
#' An sf row covers a whole feature, so such a column cannot survive the
#' conversion to sf intact.
#' @noRd
#' @keywords internal
varying_feature_columns <- function(polygons) {
  extras <- setdiff(
    unique(unlist(lapply(polygons$geometry, names))),
    c("view", polygon_coord_columns())
  )
  if (!length(extras)) {
    return(character())
  }
  varies <- vapply(
    extras,
    function(nm) {
      any(vapply(polygons$geometry, varies_within_view, logical(1), nm))
    },
    logical(1)
  )
  extras[varies]
}


#' Does `nm` take more than one value within any view of one nested table?
#' @noRd
#' @keywords internal
varies_within_view <- function(geom, nm) {
  if (!nm %in% names(geom)) {
    return(FALSE)
  }
  counts <- tapply(
    seq_len(nrow(geom)),
    geom$view,
    function(i) length(unique(geom[[nm]][i]))
  )
  any(unlist(counts) > 1L)
}


#' Refuse, or warn about, a migration that would lose columns
#' @noRd
#' @keywords internal
check_migration_loss <- function(lost, file, object, force) {
  if (!length(lost)) {
    return(invisible(NULL))
  }
  msg <- "Migrating {.field {object}} in {.file {basename(file)}} would lose
          column{?s} {.field {lost}}."
  if (!force) {
    cli::cli_abort(c(
      msg,
      "i" = "Pass {.code force = TRUE} to migrate anyway;
             {.file {basename(file)}} is rewritten in place."
    ))
  }
  cli::cli_warn(c(msg, "i" = "Migrating anyway because {.code force = TRUE}."))
  invisible(NULL)
}
