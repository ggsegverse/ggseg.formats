# Convert legacy ggseg atlases to ggseg_atlas format

**\[superseded\]**

Convert old-style ggseg (2D) and ggseg3d (3D) atlases into the new
`ggseg_atlas` format. This is a bridge function for working with
existing atlases during the transition period.

For new atlases, use `ggsegExtra::create_cortical_atlas()` or
`ggsegExtra::create_subcortical_atlas()` instead - they produce better
results with proper vertex indices.

The function handles three scenarios:

- **Both 2D and 3D**: Merges geometry with vertex data

- **3D only**: Extracts vertices, infers indices from mesh coordinates

- **2D only**: Keeps geometry, 3D rendering unavailable

If the 3D atlas already contains vertex indices (newer ggseg3d atlases),
those are preserved. Otherwise, vertex indices are inferred from mesh
coordinates using hash-based matching (no FreeSurfer needed).

## Usage

``` r
convert_legacy_brain_atlas(
  atlas_2d = NULL,
  atlas_3d = NULL,
  atlas_name = NULL,
  type = NULL,
  surface = "inflated",
  brain_meshes = NULL
)

unify_legacy_atlases(
  atlas_2d = NULL,
  atlas_3d = NULL,
  atlas_name = NULL,
  type = NULL,
  surface = "inflated",
  brain_meshes = NULL
)
```

## Arguments

- atlas_2d:

  A `ggseg_atlas` (or legacy `brain_atlas`) with 2D geometry, or NULL.

- atlas_3d:

  A `ggseg3d_atlas` with mesh data, or NULL.

- atlas_name:

  Name for the output atlas. If NULL, derived from input.

- type:

  Atlas type, as accepted by
  [`ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/ggseg_atlas.md).
  If NULL, inferred from the input atlases.

- surface:

  Which surface to match against when inferring vertices (e.g.,
  `"inflated"`). Must match the 3D atlas surface exactly.

- brain_meshes:

  Optional user-supplied brain meshes for vertex inference.

## Value

A `ggseg_atlas` object.

## Examples

``` r
# \donttest{
new_atlas <- convert_legacy_brain_atlas(atlas_2d = dk())
#> ℹ Using existing vertex data from 2D atlas.
# }
```
