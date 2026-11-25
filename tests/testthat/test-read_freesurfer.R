describe("read_freesurfer_stats()", {
  it("reads aseg.stats file with renamed columns", {
    aseg_file <- test_path("data/bert/stats/aseg.stats")
    aseg_stats <- read_freesurfer_stats(aseg_file)

    expect_named(
      aseg_stats,
      c(
        "Index",
        "SegId",
        "NVoxels",
        "Volume_mm3",
        "label",
        "normMean",
        "normStdDev",
        "normMin",
        "normMax",
        "normRange"
      )
    )
    expect_identical(nrow(aseg_stats), 45L)
  })

  it("reads aseg.stats file without renaming when rename = FALSE", {
    aseg_file <- test_path("data/bert/stats/aseg.stats")
    expect_named(
      read_freesurfer_stats(aseg_file, FALSE),
      c(
        "Index",
        "SegId",
        "NVoxels",
        "Volume_mm3",
        "StructName",
        "normMean",
        "normStdDev",
        "normMin",
        "normMax",
        "normRange"
      )
    )
  })

  it("reads aparc.stats file with renamed columns", {
    dkt_file <- test_path("data/bert/stats/lh.aparc.stats")
    dkt_stats <- read_freesurfer_stats(dkt_file)

    expect_named(
      dkt_stats,
      c(
        "label",
        "NumVert",
        "SurfArea",
        "GrayVol",
        "ThickAvg",
        "ThickStd",
        "MeanCurv",
        "GausCurv",
        "FoldInd",
        "CurvInd"
      )
    )
    expect_identical(nrow(dkt_stats), 34L)
  })

  it("reads aparc.stats file without renaming when rename = FALSE", {
    dkt_file <- test_path("data/bert/stats/lh.aparc.stats")
    expect_named(
      read_freesurfer_stats(dkt_file, FALSE),
      c(
        "StructName",
        "NumVert",
        "SurfArea",
        "GrayVol",
        "ThickAvg",
        "ThickStd",
        "MeanCurv",
        "GausCurv",
        "FoldInd",
        "CurvInd"
      )
    )
  })
})

describe("read_atlas_files()", {
  it("reads all aparc stats files from subjects directory", {
    dat <- read_atlas_files(test_path("data"), "aparc")

    expect_named(
      dat,
      c(
        "subject",
        "label",
        "NumVert",
        "SurfArea",
        "GrayVol",
        "ThickAvg",
        "ThickStd",
        "MeanCurv",
        "GausCurv",
        "FoldInd",
        "CurvInd"
      )
    )
    expect_identical(nrow(dat), 68L)
  })

  it("combines hemispheres with correct label prefixes", {
    dat <- read_atlas_files(test_path("data"), "aparc")
    expect_identical(
      unique(dat$label)[1:10],
      c(
        "lh_bankssts",
        "lh_caudalanteriorcingulate",
        "lh_caudalmiddlefrontal",
        "lh_cuneus",
        "lh_entorhinal",
        "lh_fusiform",
        "lh_inferiorparietal",
        "lh_inferiortemporal",
        "lh_isthmuscingulate",
        "lh_lateraloccipital"
      )
    )
  })
})

describe("read_freesurfer_table()", {
  it("reads table file with default column names", {
    file <- test_path("data/aparc.volume.table")
    dat <- read_freesurfer_table(file)

    expect_named(dat, c("subject", "label", "value"))
    expect_identical(nrow(dat), 36L)
    expect_true(any(grepl("volume$", dat$label)))
  })

  it("strips measure suffix from labels when measure is specified", {
    file <- test_path("data/aparc.volume.table")
    dat <- read_freesurfer_table(file, measure = "volume")

    expect_named(dat, c("subject", "label", "volume"))
    expect_false(any(grepl("volume$", dat$label)))
  })

  it("strips the measure only from the end, not mid-label", {
    tmp <- tempfile(fileext = ".table")
    # `_area` appears twice in the first column; only the trailing one is the
    # measure suffix. A global (or regex) strip would also remove the mid one.
    writeLines(
      c(
        "subject\tx_area_y_area\tlh_area",
        "bert\t1\t2"
      ),
      tmp
    )

    dat <- read_freesurfer_table(tmp, measure = "area")

    expect_setequal(dat$label, c("x_area_y", "lh"))
    unlink(tmp)
  })

  it("keeps the dots in TRACULA labels, so the table still joins", {
    tmp <- tempfile(fileext = ".table")
    # TRACULA's own labels carry dots, and FreeSurfer's structure names carry
    # dashes. read.table() mangles both to dots, and that cannot be undone.
    writeLines(
      c(
        "subject\tacomm.bbr.prep\tcc.genu.bbr.prep\tLeft-Thalamus",
        "bert\t1.5\t2.5\t3.5"
      ),
      tmp
    )

    dat <- read_freesurfer_table(tmp)

    expect_identical(
      dat$label,
      c("acomm.bbr.prep", "cc.genu.bbr.prep", "Left-Thalamus")
    )
    expect_true(
      all(head(dat$label, 2) %in% atlas_labels(tracula()))
    )

    unlink(tmp)
  })
})


describe("read_atlas_files() with aseg", {
  it("reads aseg stats files without hemisphere prefixes", {
    dat <- read_atlas_files(test_path("data"), "aseg.stats")

    expect_true("subject" %in% names(dat))
    expect_true("label" %in% names(dat))
    expect_false("hemi" %in% names(dat))
    expect_identical(unique(dat$subject), "bert")
  })
})


describe("find_subject_fromdir", {
  it("extracts subject from path", {
    result <- find_subject_fromdir("/bert/stats/aseg.stats")
    expect_identical(result, "bert")
  })
})


describe("read_atlas_files() path handling", {
  it("extracts the subject when subjects_dir has regex metacharacters", {
    base <- withr::local_tempdir()
    # '+' is a regex metacharacter: a regex-based prefix strip would not match
    sdir <- file.path(base, "a+b")
    dir.create(file.path(sdir, "bert", "stats"), recursive = TRUE)
    for (f in c("lh.aparc.stats", "rh.aparc.stats")) {
      file.copy(
        test_path(file.path("data/bert/stats", f)),
        file.path(sdir, "bert", "stats", f)
      )
    }

    dat <- read_atlas_files(sdir, "aparc")
    expect_identical(unique(dat$subject), "bert")
  })

  it("extracts the subject despite a trailing slash on subjects_dir", {
    dat <- read_atlas_files(paste0(test_path("data"), "/"), "aseg.stats")
    expect_identical(unique(dat$subject), "bert")
  })
})


describe("find_hemi_fromfile", {
  it("extracts hemisphere from lh file", {
    result <- find_hemi_fromfile("/path/to/lh.aparc.stats")
    expect_identical(result, "lh")
  })

  it("extracts hemisphere from rh file", {
    result <- find_hemi_fromfile("/path/to/rh.aparc.stats")
    expect_identical(result, "rh")
  })

  it("extracts first element for non-hemispheric files", {
    result <- find_hemi_fromfile("/path/to/aseg.stats")
    expect_identical(result, "aseg")
  })
})


describe("read_atlas_files() on a directory that matches nothing", {
  it("names subjects_dir and the pattern instead of failing in strsplit", {
    empty <- withr::local_tempdir()
    expect_error(
      read_atlas_files(empty, "aseg.stats"),
      "No FreeSurfer stats files found"
    )
    expect_error(read_atlas_files(empty, "aseg.stats"), "aseg.stats")
  })

  it("reports a typo'd subjects_dir rather than a type error", {
    expect_error(
      read_atlas_files(file.path(test_path("data"), "no_such_dir"), "aseg"),
      "No FreeSurfer stats files found"
    )
  })
})


describe("read_freesurfer_stats() header/column mismatch", {
  it("reports both counts and the path", {
    path <- withr::local_tempfile(fileext = ".stats")
    writeLines(
      c(
        "# Title Segmentation Statistics",
        "# ColHeaders  Index SegId NVoxels StructName",
        "1 2 3 4 Left-Thalamus",
        "2 3 4 5 Left-Caudate"
      ),
      path
    )
    expect_error(read_freesurfer_stats(path), "4 column headers")
    expect_error(read_freesurfer_stats(path), "5 data columns")
    expect_error(read_freesurfer_stats(path), basename(path), fixed = TRUE)
  })
})


describe("read_freesurfer_table() header handling", {
  it("refuses a repeated column name instead of dropping its values", {
    # Keeping names verbatim means duplicates survive read.table, and the long
    # format cannot represent two columns with one label: the second column's
    # values vanished silently.
    path <- withr::local_tempfile(fileext = ".txt")
    writeLines(
      c("subject\tLeft-Caudate\tLeft-Caudate", "bert\t1\t2"),
      path
    )

    expect_error(read_freesurfer_table(path), "Left-Caudate")
  })

  it("refuses check.names through ... rather than failing on a double match", {
    # `check.names` is fixed FALSE on purpose, so passing it used to abort with
    # R's "matched by multiple actual arguments" instead of saying why.
    path <- withr::local_tempfile(fileext = ".txt")
    writeLines(c("subject\tLeft-Caudate", "bert\t1"), path)

    expect_error(
      read_freesurfer_table(path, check.names = TRUE),
      "cannot be set here"
    )
  })
})
