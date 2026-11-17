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
    # Built here rather than taken from the package: the bundled meshes now
    # carry a record, and meshes from outside the core packages are exactly
    # the case this has to keep handling.
    bare <- list(
      vertices = data.frame(x = 0, y = 0, z = 0),
      faces = data.frame(i = 0L, j = 0L, k = 0L)
    )
    expect_null(get_mesh_space(bare))
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

describe("the bundled inflated meshes describe themselves", {
  # Pinned because the alternative is inference. A consumer that guesses a
  # mesh's vertex space or hemisphere gets it right until a rebuild changes
  # something, and a mesh guessed wrongly still renders a convincing brain.
  it("records vertex space, hemisphere and that they are not anatomical", {
    expected_hemi <- c(lh = "left", rh = "right")
    for (hemi in names(expected_hemi)) {
      space <- get_mesh_space(get_brain_mesh(hemi))
      expect_s3_class(space, "mesh_space")
      expect_identical(space$vertex_space, "fsaverage5")
      expect_identical(space$hemi, expected_hemi[[hemi]])
      expect_false(space$anatomical)
      expect_null(space$to_mni305)
      expect_identical(space$surface, "inflated")
    }
  })

  it("records the face index base rather than leaving it to be inferred", {
    for (hemi in c("lh", "rh")) {
      expect_identical(
        attr(get_brain_mesh(hemi), "face_index_base"),
        0L
      )
    }
  })

  it("keeps the face indices consistent with the base it claims", {
    for (hemi in c("lh", "rh")) {
      mesh <- get_brain_mesh(hemi)
      indices <- unlist(mesh$faces, use.names = FALSE)
      expect_identical(min(indices), attr(mesh, "face_index_base"))
      expect_identical(max(indices), nrow(mesh$vertices) - 1L)
    }
  })
})

describe("brain_mesh()", {
  tri_vertices <- function(n = 3) {
    data.frame(x = seq_len(n) * 1, y = seq_len(n) * 2, z = seq_len(n) * 3)
  }
  flat_space <- function() {
    mesh_space("fsaverage5", "left", anatomical = FALSE)
  }

  it("assembles a mesh carrying both its space and its face base", {
    mesh <- brain_mesh(
      vertices = tri_vertices(),
      faces = data.frame(i = 0L, j = 1L, k = 2L),
      space = flat_space(),
      face_index_base = 0L
    )
    expect_named(mesh, c("vertices", "faces"))
    expect_identical(attr(mesh, "face_index_base"), 0L)
    expect_s3_class(get_mesh_space(mesh), "mesh_space")
  })

  it("accepts 1-based faces, which the ecosystem also holds", {
    mesh <- brain_mesh(
      vertices = tri_vertices(),
      faces = data.frame(i = 1L, j = 2L, k = 3L),
      space = flat_space(),
      face_index_base = 1L
    )
    expect_identical(attr(mesh, "face_index_base"), 1L)
  })

  it("refuses faces that do not count from the base declared", {
    # The whole point: 1-based indices declared as 0-based put the last face
    # out of range and silently misplace a vertex.
    expect_error(
      brain_mesh(
        vertices = tri_vertices(),
        faces = data.frame(i = 1L, j = 2L, k = 3L),
        space = flat_space(),
        face_index_base = 0L
      ),
      "do not count from"
    )
    expect_error(
      brain_mesh(
        vertices = tri_vertices(),
        faces = data.frame(i = 0L, j = 1L, k = 2L),
        space = flat_space(),
        face_index_base = 1L
      ),
      "do not count from"
    )
  })

  it("refuses a face index beyond the vertices", {
    expect_error(
      brain_mesh(
        vertices = tri_vertices(),
        faces = data.frame(i = 0L, j = 1L, k = 99L),
        space = flat_space(),
        face_index_base = 0L
      ),
      "do not count from"
    )
  })

  it("requires the base to be stated, with no default to guess", {
    expect_error(
      brain_mesh(
        vertices = tri_vertices(),
        faces = data.frame(i = 0L, j = 1L, k = 2L),
        space = flat_space()
      ),
      'argument "face_index_base" is missing'
    )
    expect_error(
      brain_mesh(
        vertices = tri_vertices(),
        faces = data.frame(i = 0L, j = 1L, k = 2L),
        space = flat_space(),
        face_index_base = 2L
      ),
      "must be"
    )
  })

  it("refuses malformed vertices or faces", {
    expect_error(
      brain_mesh(
        vertices = data.frame(a = 1, b = 2, c = 3),
        faces = data.frame(i = 0L, j = 1L, k = 2L),
        space = flat_space(),
        face_index_base = 0L
      ),
      "must be a data frame"
    )
    expect_error(
      brain_mesh(
        vertices = tri_vertices(),
        faces = data.frame(a = 0L),
        space = flat_space(),
        face_index_base = 0L
      ),
      "must be a data frame"
    )
    expect_error(
      brain_mesh(
        vertices = tri_vertices()[0, ],
        faces = data.frame(i = 0L, j = 1L, k = 2L),
        space = flat_space(),
        face_index_base = 0L
      ),
      "at least one row"
    )
  })

  it("refuses a space that is not a mesh_space", {
    expect_error(
      brain_mesh(
        vertices = tri_vertices(),
        faces = data.frame(i = 0L, j = 1L, k = 2L),
        space = list(vertex_space = "fsaverage5"),
        face_index_base = 0L
      ),
      "must be a"
    )
  })
})
