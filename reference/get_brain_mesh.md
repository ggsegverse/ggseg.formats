# Get brain surface mesh

Retrieves a brain surface mesh for the specified hemisphere and surface
type. By default, provides the inflated fsaverage5 surface from internal
data. Other surfaces (pial, white, semi-inflated) require the ggseg3d
package.

## Usage

``` r
get_brain_mesh(
  hemisphere = c("lh", "rh"),
  surface = "inflated",
  brain_meshes = NULL
)
```

## Arguments

- hemisphere:

  `"lh"` or `"rh"`

- surface:

  Surface type (default `"inflated"`). Other surfaces require ggseg3d or
  a custom `brain_meshes` argument.

- brain_meshes:

  Optional user-supplied mesh data. Accepts either
  `list(lh = list(vertices, faces), rh = ...)` or the legacy
  `list(lh_inflated = list(vertices, faces), ...)` format.

## Value

A list with `vertices` (data.frame with x, y, z) and `faces` (data.frame
with i, j, k), or NULL if the mesh is not available. The face indices of
the bundled inflated surfaces are **0-based** (0 to
`nrow(vertices) - 1`), matching
[`get_cerebellar_mesh()`](https://ggsegverse.github.io/ggseg.formats/reference/get_cerebellar_mesh.md).
Per-region subcortical meshes from
[`ggseg_data_subcortical()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_subcortical.md)
are 1-based instead, and a user-supplied `brain_meshes` is returned
exactly as given, so a consumer must not assume a single base across
mesh sources.

## Examples

``` r
mesh <- get_brain_mesh("lh")
head(mesh$vertices)
#>            x         y         z
#> 1  -5.838037   2.50201 57.647400
#> 2  16.432404 -64.17524 54.938030
#> 3  30.062569  16.55329 43.195202
#> 4   5.290642  92.21619 13.272218
#> 5 -36.140617  24.74327 -2.762159
#> 6 -28.666910 -40.43227 32.491753
```
