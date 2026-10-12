# ggseg.formats

ggseg.formats provides the `ggseg_atlas` S3 class that powers the
[ggsegverse](https://ggsegverse.github.io/ggseg/) ecosystem for 2D and
3D brain visualisation. It ships four bundled atlases, a set of accessor
functions for querying atlas contents, and a pipe-friendly manipulation
API for subsetting, renaming, and enriching atlas objects.

## Bundled atlases

The package includes four atlases covering the main atlas types:

- **dk** — Desikan-Killiany cortical parcellation (68 regions)
- **aseg** — FreeSurfer automatic subcortical segmentation
- **tracula** — TRACULA white matter tract atlas
- **suit** — SUIT cerebellar lobular atlas

``` r

library(ggseg.formats)
```

``` r

plot(dk())
```

![](reference/figures/README-plot-dk-1.png)

``` r

plot(aseg())
```

![](reference/figures/README-plot-aseg-1.png)

``` r

plot(tracula())
```

![](reference/figures/README-plot-tracula-1.png)

``` r

plot(suit())
```

![](reference/figures/README-plot-suit-1.png)

## Quick example

Atlas objects are designed for exploration and customisation. You can
query regions, filter views, and pipe operations together:

``` r

aseg_small <- aseg() |>
  atlas_region_keep("hippocampus|amygdala|thalamus") |>
  atlas_view_keep("coronal_2|axial_3") |>
  atlas_view_gather()
plot(aseg_small)
```

![](reference/figures/README-subset-aseg-1.png)

## Installation

Install from the ggsegverse r-universe:

``` r

options(repos = c(
    ggsegverse = 'https://ggsegverse.r-universe.dev',
    CRAN = 'https://cloud.r-project.org'))

install.packages('ggseg.formats')
```

Or install the development version from GitHub:

``` r

# install.packages("devtools")
devtools::install_github("ggsegverse/ggseg.formats")
```

## Learn more

- [`vignette("ggseg.formats")`](https://ggsegverse.github.io/ggseg.formats/articles/ggseg.formats.md)
  — understanding atlas structure and accessors
- [`vignette("atlas-manipulation")`](https://ggsegverse.github.io/ggseg.formats/articles/atlas-manipulation.md)
  — region, view, and metadata manipulation
