# Build a mesh that describes itself

Assembles vertices, faces and a
[`mesh_space()`](https://ggsegverse.github.io/ggseg.formats/reference/mesh_space.md)
into one object, checking they agree. Reading a surface file and
assembling the pieces by hand is done in several places across the
ecosystem, and each one decided independently whether faces were counted
from 0 or from 1 – which is why `ggseg.formats` inflated surfaces are
0-based, `ggseg.meshes` cortical surfaces are 1-based, and consumers
carry code to cope. Declaring the base and having it checked makes that
disagreement impossible to introduce again.

## Usage

``` r
brain_mesh(vertices, faces, space, face_index_base)
```

## Arguments

- vertices:

  A data.frame of `x`, `y`, `z`.

- faces:

  A data.frame of `i`, `j`, `k`.

- space:

  A
  [`mesh_space()`](https://ggsegverse.github.io/ggseg.formats/reference/mesh_space.md)
  describing what the coordinates mean.

- face_index_base:

  `0L` or `1L` – the number the file's face indices count from.
  Required.

## Value

A list of `vertices` and `faces`, carrying `mesh_space` and
`face_index_base` attributes.

## Details

`face_index_base` has no default on purpose. A default would be a fourth
independent decision, and the point is that the caller states what their
file actually contains.

The faces are checked against the base rather than taken on trust: the
smallest index must equal the base and the largest must be the last
vertex counted from it. A mesh that declares 0 while holding 1-based
indices renders with one vertex silently misplaced and the last face out
of range, which is the failure this refuses.

## See also

Other mesh spaces:
[`mesh_space()`](https://ggsegverse.github.io/ggseg.formats/reference/mesh_space.md),
[`set_mesh_space()`](https://ggsegverse.github.io/ggseg.formats/reference/set_mesh_space.md)

## Examples

``` r
brain_mesh(
  vertices = data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0)),
  faces = data.frame(i = 0L, j = 1L, k = 2L),
  space = mesh_space("fsaverage5", "left", anatomical = FALSE),
  face_index_base = 0L
)
#> $vertices
#>   x y z
#> 1 0 0 0
#> 2 1 0 0
#> 3 0 1 0
#> 
#> $faces
#>   i j k
#> 1 0 1 2
#> 
#> attr(,"face_index_base")
#> [1] 0
#> attr(,"mesh_space")
#> <mesh_space> (v1)
#> • vertex space: "fsaverage5"
#> • hemisphere: "left"
#> • not anatomical, no MNI305 mapping
#> • units: "mm"
```
