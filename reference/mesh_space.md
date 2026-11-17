# Record what a mesh's coordinates mean

A surface mesh on its own is just numbers: nothing in `vertices` says
which hemisphere it is, which vertex space an atlas must have been built
against to index it, or how to get from its coordinates to a standard
space. Without that, consumers infer those things, and a mesh inferred
wrongly still renders perfectly – a brain mirrored left-to-right, or
regions painted at the wrong vertices, looks like a brain.
`mesh_space()` makes the mesh state them.

## Usage

``` r
mesh_space(
  vertex_space,
  hemi,
  anatomical,
  to_mni305 = NULL,
  units = "mm",
  surface = NULL,
  source = NULL
)
```

## Arguments

- vertex_space:

  Vertex space the mesh is in, such as `"fsaverage5"`. Atlas vertex
  indices are only meaningful against a named space.

- hemi:

  `"left"`, `"right"` or `"midline"`.

- anatomical:

  Whether the coordinates correspond to positions in a brain. `FALSE`
  for inflated and spherical surfaces.

- to_mni305:

  A 4x4 matrix mapping vertex coordinates to MNI305, or `NULL` when
  `anatomical` is `FALSE`.

- units:

  Coordinate units. Millimetres throughout the ecosystem.

- surface:

  Optional surface name, such as `"pial"`.

- source:

  Optional free-text note on where the mesh came from, for
  reproducibility. Never read by code;
  [`atlas_provenance()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_provenance.md)
  remains the authoritative record.

## Value

A `mesh_space` object, to be attached with
[`set_mesh_space()`](https://ggsegverse.github.io/ggseg.formats/reference/set_mesh_space.md).

## Details

`vertex_space` is the mesh's identity as far as atlases are concerned.
Atlases key regions to vertex indices, so an atlas built against one
vertex space and drawn on another puts every region somewhere else.
Checking that indices merely fit catches only the case where the other
mesh is smaller.

Name a *numbered* space – `"fsaverage5"`, `"fsaverage6"` – because those
are fixed templates and stable across FreeSurfer releases: `fsaverage5`
is vertex-for-vertex the same mesh in 7.4.1 and 8.2.0, which is what
makes an atlas's indices portable. Unnumbered `"fsaverage"` is not a
stable identifier: it is whichever densest mesh that release ships, so
the same string can mean different vertex counts and different indices.
Record `source` if you must use it.

`hemi` is recorded because left and right are the one distinction this
ecosystem must never get wrong, and a mesh that cannot state its own
side cannot be checked against the data drawn on it.

`to_mni305` is a 4x4 affine mapping the mesh's own vertex coordinates to
MNI305, collapsing any axis permutation, sign flip and translation into
one matrix. It is required when `anatomical` is `TRUE` and must be
`NULL` otherwise: inflation and spherical registration move every
vertex, so those surfaces have no anatomical position to map to and a
matrix for them would be a number that looks usable.

Positioning a mesh for display – moving a hemisphere to meet the
midline, say – is the renderer's decision, not a property of the mesh,
so it is deliberately not recorded here.

## See also

Other mesh spaces:
[`brain_mesh()`](https://ggsegverse.github.io/ggseg.formats/reference/brain_mesh.md),
[`set_mesh_space()`](https://ggsegverse.github.io/ggseg.formats/reference/set_mesh_space.md)

## Examples

``` r
mesh_space(
  vertex_space = "fsaverage5",
  hemi = "left",
  anatomical = FALSE
)
#> <mesh_space> (v1)
#> • vertex space: "fsaverage5"
#> • hemisphere: "left"
#> • not anatomical, no MNI305 mapping
#> • units: "mm"
```
