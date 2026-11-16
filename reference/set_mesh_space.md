# Attach or read a mesh's coordinate record

Attach or read a mesh's coordinate record

## Usage

``` r
set_mesh_space(mesh, space)

get_mesh_space(mesh)
```

## Arguments

- mesh:

  A list with `vertices` and `faces`.

- space:

  A
  [`mesh_space()`](https://ggsegverse.github.io/ggseg.formats/reference/mesh_space.md)
  object.

## Value

`set_mesh_space()` returns `mesh` with the record attached.
`get_mesh_space()` returns the record, or `NULL` when the mesh carries
none – meshes from outside the core packages legitimately do not.

## See also

Other mesh spaces:
[`mesh_space()`](https://ggsegverse.github.io/ggseg.formats/reference/mesh_space.md)

## Examples

``` r
mesh <- get_brain_mesh("lh")
space <- mesh_space("fsaverage5", "left", anatomical = FALSE)
mesh <- set_mesh_space(mesh, space)
get_mesh_space(mesh)$vertex_space
#> [1] "fsaverage5"
```
