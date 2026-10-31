# Create white-matter atlas data

Creates a data object for white-matter brain atlases. A white-matter
atlas stores what a subcortical one stores – sf polygons for the 2D slab
views and a mesh per structure for 3D – so this is the subcortical shape
under a name of its own, and the object inherits
`ggseg_data_subcortical` so the methods written for it apply unchanged.

## Usage

``` r
ggseg_data_wm(geom = NULL, meshes = NULL, ...)
```

## Arguments

- geom:

  An sf data frame of polygons, or `NULL`.

- meshes:

  A data frame of per-structure meshes, or `NULL`.

- ...:

  Passed to the shared geometry resolver.

## Value

A `ggseg_data_wm` object.

## Details

White-matter *tracts* are a different thing:
[`ggseg_data_tract()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_tract.md)
also carries centerlines, which a white-matter label map has none of.

## See also

[`ggseg_data_subcortical()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_subcortical.md),
[`ggseg_data_tract()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_data_tract.md)

## Examples

``` r
ggseg_data_wm(
  meshes = data.frame(
    label = "cst_left",
    mesh = I(list(list(
      vertices = data.frame(x = 1:10, y = 1:10, z = 1:10),
      faces = data.frame(i = 1:3, j = 2:4, k = 3:5)
    )))
  )
)
#> 
#> ── ggseg_data_subcortical ──
#> 
#> 3D (ggseg3d): meshes
#>      label vertices faces
#> 1 cst_left       10     3
```
