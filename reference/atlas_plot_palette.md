# Get a plottable palette for an atlas

Returns the atlas `palette` when it can tell the atlas's regions apart,
and otherwise a palette of automatically assigned, distinguishable
colours. Use this instead of reading `atlas$palette` directly whenever
the palette is about to be drawn: some atlases are built from colour
lookup tables that give every region the same colour (often black), and
rendering those faithfully produces a solid silhouette in which no
region can be told from its neighbours.

## Usage

``` r
atlas_plot_palette(atlas)
```

## Arguments

- atlas:

  a `ggseg_atlas` object

## Value

Named character vector of colours keyed by label.

## Details

A palette is treated as unusable when every one of the atlas's regions
resolves to a single colour. Contextual geometry – the `cortex_`
silhouette and the `unknown` medial wall – is excluded from that
judgement and keeps its conventional grey in the fallback, so backdrop
is never mistaken for a parcel. Atlases with a single region, and
palettes that are merely dark but varied, are left untouched: this
replaces palettes that cannot be read, not palettes that are unusual.

Falling back warns, naming the atlas, because the fix belongs in the
atlas's colour lookup table. An atlas carrying no palette at all is a
supported, expected state rather than a broken table, so it falls back
silently.

## See also

[`atlas_palette()`](https://ggsegverse.github.io/ggseg.formats/reference/atlas_palette.md)
for the palette exactly as stored.

## Examples

``` r
# A well-formed palette comes back untouched
identical(atlas_plot_palette(dk()), atlas_palette(dk()))
#> [1] TRUE
```
