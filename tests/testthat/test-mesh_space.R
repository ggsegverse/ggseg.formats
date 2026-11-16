identity_affine <- function() {
  diag(4)
}

describe("mesh_space()", {
  it("records the core fields and stamps the schema version", {
    space <- mesh_space(
      vertex_space = "fsaverage5",
      hemi = "left",
      anatomical = TRUE,
      to_mni305 = identity_affine()
    )
    expect_s3_class(space, "mesh_space")
    expect_identical(space$vertex_space, "fsaverage5")
    expect_identical(space$hemi, "left")
    expect_true(space$anatomical)
    expect_identical(space$units, "mm")
    expect_identical(space$schema_version, 1L)
  })

  it("defaults the optional fields to NULL", {
    space <- mesh_space("fsaverage5", "left", anatomical = FALSE)
    expect_null(space$surface)
    expect_null(space$source)
    expect_null(space$to_mni305)
  })

  it("keeps the optional fields when given", {
    space <- mesh_space(
      "fsaverage5",
      "right",
      anatomical = FALSE,
      surface = "inflated",
      source = "FreeSurfer 7.4.1 fsaverage5"
    )
    expect_identical(space$surface, "inflated")
    expect_identical(space$source, "FreeSurfer 7.4.1 fsaverage5")
  })
})

describe("mesh_space() rejects what it cannot record honestly", {
  it("requires a named vertex space", {
    expect_error(
      mesh_space("", "left", anatomical = FALSE),
      "non-empty string"
    )
    expect_error(
      mesh_space(NA_character_, "left", anatomical = FALSE),
      "non-empty string"
    )
  })

  it("requires a hemisphere from the closed vocabulary", {
    expect_error(
      mesh_space("fsaverage5", "lh", anatomical = FALSE),
      "must be one of"
    )
    expect_error(
      mesh_space("fsaverage5", "both", anatomical = FALSE),
      "must be one of"
    )
  })

  it("requires anatomical to be a single TRUE or FALSE", {
    expect_error(mesh_space("fsaverage5", "left", anatomical = NA), "TRUE")
    expect_error(mesh_space("fsaverage5", "left", anatomical = "yes"), "TRUE")
  })

  it("requires an affine for an anatomical mesh", {
    expect_error(
      mesh_space("fsaverage5", "left", anatomical = TRUE),
      "required when"
    )
  })

  it("refuses an affine for a non-anatomical mesh", {
    expect_error(
      mesh_space(
        "fsaverage5",
        "left",
        anatomical = FALSE,
        to_mni305 = identity_affine()
      ),
      "must be `NULL`"
    )
  })

  it("requires the affine to be a complete numeric 4x4", {
    expect_error(
      mesh_space("fsaverage5", "left", anatomical = TRUE, to_mni305 = diag(3)),
      "4x4 matrix"
    )
    bad <- identity_affine()
    bad[1, 1] <- NA
    expect_error(
      mesh_space("fsaverage5", "left", anatomical = TRUE, to_mni305 = bad),
      "numeric and complete"
    )
  })

  it("requires the affine's last row to be c(0, 0, 0, 1)", {
    bad <- identity_affine()
    bad[4, ] <- c(0, 0, 1, 1)
    expect_error(
      mesh_space("fsaverage5", "left", anatomical = TRUE, to_mni305 = bad),
      "last row"
    )
  })

  it("refuses a singular affine, which cannot place a point back", {
    bad <- identity_affine()
    bad[3, 3] <- 0
    expect_error(
      mesh_space("fsaverage5", "left", anatomical = TRUE, to_mni305 = bad),
      "invertible"
    )
  })

  it("refuses units other than millimetres", {
    expect_error(
      mesh_space("fsaverage5", "left", anatomical = FALSE, units = "cm"),
      "must be"
    )
  })

  it("refuses a non-string surface or source", {
    expect_error(
      mesh_space("fsaverage5", "left", anatomical = FALSE, surface = 1),
      "single string"
    )
    expect_error(
      mesh_space(
        "fsaverage5",
        "left",
        anatomical = FALSE,
        source = c("a", "b")
      ),
      "single string"
    )
  })
})

describe("set_mesh_space() and get_mesh_space()", {
  it("round-trips the record on a mesh", {
    mesh <- get_brain_mesh("lh")
    space <- mesh_space("fsaverage5", "left", anatomical = FALSE)
    mesh <- set_mesh_space(mesh, space)
    expect_identical(get_mesh_space(mesh), space)
  })

  it("leaves the mesh's own contents untouched", {
    mesh <- get_brain_mesh("lh")
    tagged <- set_mesh_space(
      mesh,
      mesh_space("fsaverage5", "left", anatomical = FALSE)
    )
    expect_identical(tagged$vertices, mesh$vertices)
    expect_identical(tagged$faces, mesh$faces)
  })

  it("returns NULL for a mesh carrying no record", {
    expect_null(get_mesh_space(get_brain_mesh("lh")))
  })

  it("refuses anything that is not a mesh_space", {
    expect_error(
      set_mesh_space(get_brain_mesh("lh"), list(vertex_space = "fsaverage5")),
      "must be a"
    )
  })
})

describe("print.mesh_space()", {
  it("prints an anatomical record", {
    expect_snapshot(print(mesh_space(
      "fsaverage5",
      "left",
      anatomical = TRUE,
      to_mni305 = identity_affine(),
      surface = "pial",
      source = "FreeSurfer 7.4.1 fsaverage5"
    )))
  })

  it("prints a non-anatomical record", {
    expect_snapshot(print(mesh_space(
      "fsaverage5",
      "right",
      anatomical = FALSE
    )))
  })
})
