## R CMD check results

0 errors | 0 warnings | 0 notes

Checked with `R CMD check --as-cran` on macOS (R 4.5.1).

## This is a breaking release

0.1.0 re-keys the `region` column of the four bundled atlases from a long-form
display name to a short identifier derived from `label`, and adds a `names`
column holding the long form. `label`, the documented stable key, is unchanged.
The change is marked under `### Breaking changes` in NEWS.md, and the package
ships `legacy_region_map()` plus a warning on a zero-match region pattern so
affected code gets an actionable message rather than an empty figure.

## Reverse dependencies

The three CRAN packages depending on ggseg.formats (ggseg, ggseg3d,
ggseg.meshes) are maintained by us and were checked against this version; all
pass. The only external CRAN package in the ecosystem, neuroimaGene (via ggseg),
was also checked and passes: it joins on `label`, not `region`, so the re-keying
does not reach it. Its maintainer has been notified.
