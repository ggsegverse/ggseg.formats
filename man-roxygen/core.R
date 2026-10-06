#' @section Core columns:
#' `core` carries one row per atlas region with the columns `hemi`, `region`,
#' `label` and `names`, plus the atlas's own grouping column. `label` is the
#' stable atlas identifier and the key the palette and the geometry are keyed
#' on; `region` is a short, hemisphere-free key derived from it; `names` is the
#' curated long-form display name, spelled out to read well in a figure legend.
#'
#' `region` held the long-form name until version 0.1.0. `names` is not a record
#' of those old values -- use [legacy_region_map()] to translate them.
