# The schema version an atlas was built against

A serialized S7 object carries a frozen copy of its class: the
properties, the constructor and the validator as they stood when the
object was built. That is what lets an atlas saved by one release load
under another, and it is also the trap. Add a property to `ggseg_atlas`
and an atlas built before it does not merely lack the property – reading
it is a hard error, while
[`S7::validate()`](https://rconsortium.github.io/S7/reference/validate.html)
still passes, because the validator it runs is the one frozen inside it.
The atlas looks fine, dispatches fine, and fails only when something
touches the new property.

## Usage

``` r
atlas_schema_version()

atlas_schema(atlas)

atlas_schema_is_current(atlas)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

## Value

`atlas_schema_version()` returns a single integer. `atlas_schema()`
returns the version an atlas was built against, or `0L` for an atlas
built before the stamp existed – including every legacy list atlas.
`atlas_schema_is_current()` returns a logical scalar.

## Details

Nothing in S7 detects that, so the atlas carries its own stamp. Every
atlas records the schema version it was built against;
`atlas_schema_version()` is what the installed `ggseg.formats` builds
today. When the two differ,
[`as_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_ggseg_atlas.md)
rebuilds the atlas through the current constructor, which fills in
whatever is new and revalidates against current rules.

This matters because atlases are published, not just made: roughly 150
of them live in `R/sysdata.rda` files across the atlas packages, each
built by whichever `ggseg.formats` was current that day, and r-universe
rebuilds them on its own schedule.

## When to bump

Bump `atlas_schema_version()` whenever an atlas built by the previous
version would be wrong, or incomplete, under the current one: a property
added or removed, an invariant tightened, a slot's meaning changed. Do
not bump for a new accessor, a new verb, or a bug fix that leaves stored
data alone – a bump costs every published atlas a rebuild or an upgrade.

## See also

[`as_ggseg_atlas()`](https://ggsegverse.github.io/ggseg.formats/reference/as_ggseg_atlas.md),
which upgrades a stale atlas.

Other atlas accessors:
[`atlas_centerlines()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_centerlines.md),
[`atlas_context()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_context.md),
[`atlas_core()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_core.md),
[`atlas_data()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_data.md),
[`atlas_display()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_display.md),
[`atlas_geom()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geom.md),
[`atlas_geometry_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_geometry_type.md),
[`atlas_hemi()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_hemi.md),
[`atlas_labels()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_labels.md),
[`atlas_meshes()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_meshes.md),
[`atlas_name()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_name.md),
[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md),
[`atlas_plot_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_plot_palette.md),
[`atlas_polygons()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_polygons.md),
[`atlas_provenance()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_provenance.md),
[`atlas_region_semantics()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_region_semantics.md),
[`atlas_regions()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_regions.md),
[`atlas_sf()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_sf.md),
[`atlas_type()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_type.md),
[`atlas_undrawn()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_undrawn.md),
[`atlas_vertices()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_vertices.md),
[`atlas_views()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views.md),
[`atlas_views_empty()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_views_empty.md),
[`has_atlas_geometry`](https://ggsegverse.github.io/ggseg.formats/reference/has_atlas_geometry.md),
[`legacy_region_map()`](https://ggsegverse.github.io/ggseg.formats/reference/legacy_region_map.md)

## Examples

``` r
atlas_schema_version()
#> [1] 1
atlas_schema(dk())
#> [1] 1
atlas_schema_is_current(dk())
#> [1] TRUE
```
