#' Read in raw FreeSurfer stats file
#'
#' FreeSurfer atlas stats files have a format
#' that can be difficult to easily read in to R.
#' This function takes a raw stats-file from the
#' subjects directory and reads it in as a
#' data.frame.
#'
#' @param path path to stats file
#' @param rename logical. rename headers for ggseg compatibility
#' @importFrom utils read.table
#' @return data.frame with stats information for subjects from FreeSurfer
#' @export
#' @examplesIf FALSE
#' subj_dir <- "/path/to/freesurfer/7.2.0/subjects/"
#' aseg_stats <- file.path(subj_dir, "bert/stats/aseg.stats")
#' read_freesurfer_stats(aseg_stats)
read_freesurfer_stats <- function(path, rename = TRUE) {
  headers <- readLines(path)
  headers <- headers[grepl("^#", headers)]
  headers <- gsub("# ", "", headers, fixed = TRUE)[length(headers)]
  headers <- strsplit(headers, " ", fixed = TRUE)[[1]]

  headers <- headers[!grepl("ColHeaders", headers, fixed = TRUE)]
  headers <- headers[headers != ""]

  data <- as_tbl(read.table(path))
  if (length(headers) != ncol(data)) {
    cli::cli_abort(c(
      "{.path {path}} has {length(headers)} column header{?s} but
       {ncol(data)} data column{?s}.",
      "i" = "The {.code # ColHeaders} line and the table below it must agree."
    ))
  }
  names(data) <- headers

  if (rename) {
    names(data)[names(data) == "StructName"] <- "label"
  }

  data
}

#' Read in atlas data from all subjects
#'
#' Recursively reads in all stats files for
#' an atlas (given a unique character string),
#' for all subjects in the subjects directory.
#' Will add hemisphere and subject id to the data.
#'
#' @param subjects_dir FreeSurfer subject directory
#' @param atlas unique character combination identifying the atlas
#' @return data.frame with stats information for subjects from FreeSurfer
#' @export
#' @examplesIf FALSE
#' subj_dir <- "/path/to/freesurfer/7.2.0/subjects/"
#' read_atlas_files(subj_dir, "aseg.stats")
#' read_atlas_files(subj_dir, "lh.aparc.stats")
read_atlas_files <- function(subjects_dir, atlas) {
  stats_files <- list.files(
    subjects_dir,
    pattern = atlas,
    full.names = TRUE,
    recursive = TRUE
  )
  stats_files <- stats_files[grepl("stats$", stats_files)]

  if (length(stats_files) == 0) {
    cli::cli_abort(c(
      "No FreeSurfer stats files found.",
      "x" = "No file under {.arg subjects_dir} ({.path {subjects_dir}})
             matches {.arg atlas} ({.val {atlas}}) and ends in
             {.field .stats}.",
      "i" = "Check the directory path and the atlas pattern."
    ))
  }

  stats <- lapply(stats_files, read_freesurfer_stats)

  # Strip the `subjects_dir` prefix by length (not as a regex) so paths
  # containing regex metacharacters are handled, then take the first path
  # component — the subject directory — independent of a trailing slash.
  prefix <- sub("/+$", "", subjects_dir)
  rel <- substring(stats_files, nchar(prefix) + 1L)
  subject <- vapply(rel, find_subject_fromdir, character(1))
  hemi <- vapply(stats_files, find_hemi_fromfile, character(1))

  if (all(hemi %in% c("rh", "lh"))) {
    names(stats) <- paste(subject, hemi, sep = "___")
    stats <- df_bind_rows(stats, .id = "id")
    parts <- strsplit(stats$id, "___", fixed = TRUE)
    stats$subject <- vapply(parts, `[`, character(1), 1L)
    stats$label <- paste(
      vapply(parts, `[`, character(1), 2L),
      stats$label,
      sep = "_"
    )
    stats$id <- NULL
    stats <- as_tbl(stats[c("subject", setdiff(names(stats), "subject"))])
  } else {
    names(stats) <- subject
    stats <- df_bind_rows(stats, .id = "subject")
  }

  stats
}


#' Read in stats table from FreeSurfer
#'
#' FreeSurfer has functions to create
#' tables from raw stats files. If you have
#' data already merged using the \code{aparcstats2table}
#' or \code{asegstats2table} from FreeSurfer,
#' this function will read in the data and prepare it
#' for ggseg.
#'
#' @param path path to the table file
#' @param measure which measure is the table of
#' @param ... additional arguments to \code{read.table}
#' @importFrom utils read.table
#' @return data.frame with stats information for subjects from FreeSurfer
#' @export
#' @examplesIf FALSE
#' file_path <- "all_subj_aseg.txt"
#' read_freesurfer_table(file_path)
read_freesurfer_table <- function(path, measure = NULL, ...) {
  dat <- read.table(path, header = TRUE, ...)
  names(dat)[1] <- "subject"

  measure_cols <- setdiff(names(dat), "subject")
  dat <- data.frame(
    subject = rep(dat$subject, times = length(measure_cols)),
    label = rep(measure_cols, each = nrow(dat)),
    value = unlist(dat[measure_cols], use.names = FALSE)
  )

  if (!is.null(measure)) {
    # the measure is a trailing `_<measure>` suffix on the column name; strip
    # it literally from the end so a label containing the measure mid-string
    # (or a measure with regex metacharacters) is not over-stripped.
    suffix <- paste0("_", measure)
    has_suffix <- endsWith(dat$label, suffix)
    dat$label[has_suffix] <- substr(
      dat$label[has_suffix],
      1L,
      nchar(dat$label[has_suffix]) - nchar(suffix)
    )
    names(dat)[names(dat) == "value"] <- measure
  }

  if (any(grepl(".", dat$label, fixed = TRUE))) {
    dat$label <- gsub(".", "-", dat$label, fixed = TRUE)
  }

  as_tbl(dat)
}


#' helper function to easily grab subject information from directory path
#' @param path file path
#' @noRd
#' @keywords internal
find_subject_fromdir <- function(path) {
  parts <- strsplit(path, "/", fixed = TRUE)[[1]]
  parts <- parts[parts != ""]
  parts[1]
}

#' helper function to easily grab hemisphere information from file path
#'
#' @param path file path
#' @noRd
#' @keywords internal
find_hemi_fromfile <- function(path) {
  strsplit(basename(path), ".", fixed = TRUE)[[1]][1]
}
