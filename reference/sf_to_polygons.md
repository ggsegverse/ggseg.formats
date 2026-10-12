# Convert an sf atlas geometry to the sf-optional polygon format

Extracts coordinates from an sf-backed atlas geometry table and returns
a nested data.frame keyed by `label`. Each row carries a `geometry`
list-column containing the per-view, per-ring point coordinates needed
to render with
[`graphics::polypath()`](https://rdrr.io/r/graphics/polypath.html)
(using the `subgroup` ring index for holes).

## Usage

``` r
sf_to_polygons(sf_data)
```

## Arguments

- sf_data:

  An sf-class data.frame with columns `label`, `view`, `geometry` (sfc
  of MULTIPOLYGON).

## Value

A data.frame with one row per `label` and a `geometry` list-column. Each
nested element is a data.frame with columns `view`, `x`, `y`, `group`
(disjoint polygon piece within a label/view), `subgroup` (ring within a
piece; first = exterior, rest = holes), plus any extra columns carried
over from `sf_data`.

Internal conversion primitive. For the atlas-level public API use
[`as_polygon_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_polygon_atlas.md)
/
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md).

## Details

Columns beyond `label`, `view` and `geometry` are carried into the
nested table, repeated down the rows of the feature they came from. Only
columns whose names collide with the nested coordinate columns (`x`,
`y`, `group`, `subgroup`) cannot be carried; those are dropped with a
warning.
