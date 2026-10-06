## R CMD check results

0 errors | 0 warnings | 0 notes

Checked with `R CMD check --no-manual --as-cran` on macOS
(aarch64-apple-darwin23), R 4.6.1.

## This is a breaking release

0.1.0 re-keys the `region` column of the four bundled atlases from a long-form
display name to a short identifier derived from `label`, and adds a `names`
column holding the long form. Against the current CRAN release (0.0.4) every
`label` value is unchanged, so the documented stable join key still holds.

The change is marked under `### Breaking changes` in NEWS.md with the
per-atlas recoverability figures, and the package ships `legacy_region_map()`
plus a warning on a zero-match region pattern, so affected code gets an
actionable message rather than a blank figure.

## Reverse dependencies

Three CRAN packages depend on ggseg.formats -- ggseg, ggseg3d and
ggseg.meshes -- all of which we maintain, and which are being updated in step
with this release.

The only external CRAN package in the ecosystem is neuroimaGene, which depends
on ggseg rather than on ggseg.formats directly. We checked it against this
version: it joins on `label` and has no `region` column anywhere, so the
re-keying does not reach it, and its plots are unchanged or improved. We are
contacting its maintainer as a courtesy notification.
