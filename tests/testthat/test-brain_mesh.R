describe("get_brain_mesh", {
  it("returns inflated mesh for lh", {
    mesh <- get_brain_mesh(hemisphere = "lh", surface = "inflated")

    expect_false(is.null(mesh))
    expect_true("vertices" %in% names(mesh))
    expect_true("faces" %in% names(mesh))
    expect_gt(nrow(mesh$vertices), 0)
    expect_gt(nrow(mesh$faces), 0)
    expect_identical(ncol(mesh$vertices), 3L)
    expect_identical(ncol(mesh$faces), 3L)
  })

  it("returns inflated mesh for rh", {
    mesh <- get_brain_mesh(hemisphere = "rh", surface = "inflated")

    expect_false(is.null(mesh))
    expect_identical(nrow(mesh$vertices), 10242L)
    expect_identical(nrow(mesh$faces), 20480L)
  })

  it("returns both hemispheres with same vertex count", {
    lh <- get_brain_mesh(hemisphere = "lh", surface = "inflated")
    rh <- get_brain_mesh(hemisphere = "rh", surface = "inflated")

    expect_identical(nrow(lh$vertices), nrow(rh$vertices))
  })

  it("validates hemisphere argument", {
    expect_error(get_brain_mesh(hemisphere = "invalid"))
  })

  it("errors for non-inflated surfaces without brain_meshes", {
    expect_error(
      get_brain_mesh(hemisphere = "lh", surface = "pial"),
      "not available"
    )
  })

  it("uses user-supplied brain_meshes with lh/rh format", {
    custom_mesh <- list(
      lh = list(
        vertices = data.frame(x = 1:3, y = 4:6, z = 7:9),
        faces = data.frame(i = 1, j = 2, k = 3)
      )
    )

    mesh <- get_brain_mesh(
      hemisphere = "lh",
      surface = "custom",
      brain_meshes = custom_mesh
    )

    expect_identical(mesh$vertices$x, 1:3)
  })

  it("uses user-supplied brain_meshes with lh_surface format", {
    custom_mesh <- list(
      lh_pial = list(
        vertices = data.frame(x = 10:12, y = 1:3, z = 1:3),
        faces = data.frame(i = 1, j = 2, k = 3)
      )
    )

    mesh <- get_brain_mesh(
      hemisphere = "lh",
      surface = "pial",
      brain_meshes = custom_mesh
    )

    expect_identical(mesh$vertices$x, 10:12)
  })

  it("returns NULL for missing hemisphere in user-supplied meshes", {
    custom_mesh <- list(
      lh = list(
        vertices = data.frame(x = 1:3, y = 1:3, z = 1:3),
        faces = data.frame(i = 1, j = 2, k = 3)
      )
    )

    mesh <- get_brain_mesh(
      hemisphere = "rh",
      surface = "inflated",
      brain_meshes = custom_mesh
    )

    expect_null(mesh)
  })
})


describe("get_cerebellar_mesh", {
  it("returns SUIT cerebellar surface mesh", {
    mesh <- get_cerebellar_mesh()

    expect_false(is.null(mesh))
    expect_true("vertices" %in% names(mesh))
    expect_true("faces" %in% names(mesh))
    expect_identical(nrow(mesh$vertices), 30013L)
    expect_identical(nrow(mesh$faces), 57665L)
  })

  it("has 0-based face indices", {
    mesh <- get_cerebellar_mesh()
    expect_identical(min(mesh$faces$i), 0L)
  })
})


describe("mesh face index bases", {
  it("documents get_brain_mesh() as 0-based for both hemispheres", {
    for (hemi in c("lh", "rh")) {
      mesh <- get_brain_mesh(hemi)
      idx <- unlist(mesh$faces[c("i", "j", "k")], use.names = FALSE)
      expect_identical(min(idx), 0L)
      expect_identical(max(idx), nrow(mesh$vertices) - 1L)
    }
  })

  it("returns a user-supplied mesh unchanged, whatever its base", {
    custom <- list(
      lh = list(
        vertices = data.frame(x = 1:3, y = 1:3, z = 1:3),
        faces = data.frame(i = 1L, j = 2L, k = 3L)
      )
    )
    expect_identical(get_brain_mesh("lh", brain_meshes = custom), custom$lh)
  })
})
