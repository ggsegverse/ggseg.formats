describe("dk atlas", {
  it("is a valid brain_atlas", {
    expect_true(is_ggseg_atlas(dk()))
    expect_s3_class(dk(), "ggseg_atlas")
  })

  it("has correct atlas name and type", {
    expect_identical(dk()$atlas, "dk")
    expect_identical(dk()$type, "cortical")
  })

  it("has required core columns", {
    expect_true(all(c("hemi", "region", "label") %in% names(dk()$core)))
  })

  it("has valid data structure", {
    expect_s3_class(dk()$data, "ggseg_atlas_data")
    expect_s3_class(dk()$data, "ggseg_data_cortical")
  })

  it("has both hemispheres", {
    hemis <- unique(dk()$core$hemi)
    expect_true("left" %in% hemis)
    expect_true("right" %in% hemis)
  })

  it("has expected number of regions", {
    regions <- atlas_regions(dk())
    expect_gt(length(regions), 30)
  })

  it("has polygon geometry for 2D rendering", {
    expect_false(is.null(atlas_geom(dk())))
    expect_s3_class(atlas_geom(dk()), "brain_polygons")
  })
})


describe("aseg atlas", {
  it("is a valid brain_atlas", {
    expect_true(is_ggseg_atlas(aseg()))
    expect_s3_class(aseg(), "ggseg_atlas")
  })

  it("has correct atlas name and type", {
    expect_identical(aseg()$atlas, "aseg")
    expect_identical(aseg()$type, "subcortical")
  })

  it("has required core columns", {
    expect_true(all(c("hemi", "region", "label") %in% names(aseg()$core)))
  })

  it("has valid data structure", {
    expect_s3_class(aseg()$data, "ggseg_atlas_data")
    expect_s3_class(aseg()$data, "ggseg_data_subcortical")
  })

  it("has expected subcortical regions", {
    regions <- atlas_regions(aseg())
    expect_gt(length(regions), 5)
  })

  it("has polygon geometry for 2D rendering", {
    expect_false(is.null(atlas_geom(aseg())))
    expect_s3_class(atlas_geom(aseg()), "brain_polygons")
  })
})


describe("suit atlas", {
  it("is a valid cerebellar ggseg_atlas", {
    expect_true(is_ggseg_atlas(suit()))
    expect_identical(suit()$atlas, "suit")
    expect_identical(suit()$type, "cerebellar")
    expect_s3_class(suit()$data, "ggseg_data_cerebellar")
  })

  it("has required core columns and several regions", {
    expect_true(all(c("hemi", "region", "label") %in% names(suit()$core)))
    expect_gt(length(atlas_regions(suit())), 5)
  })

  it("stores 2D geometry as sf-optional polygons in the geom slot", {
    expect_true(is_atlas_polygon(suit()))
    expect_identical(atlas_geometry_type(suit()), "polygon")
    expect_null(suit()$data$sf)
    expect_s3_class(atlas_geom(suit()), "brain_polygons")
  })

  it("carries 3D vertices (lobules) and meshes (deep nuclei)", {
    expect_false(is.null(suit()$data$vertices))
    expect_false(is.null(suit()$data$meshes))
  })

  it("renders to sf on demand via atlas_sf()", {
    skip_if_not_installed("sf")
    expect_s3_class(atlas_sf(suit()), "sf")
  })
})
