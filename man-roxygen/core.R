#' @section Core columns:
#' `core` carries one row per atlas region with the columns `hemi`, `region`,
#' `label` and `names`, plus the atlas's own grouping column. `label` is the
#' stable atlas identifier and the key the palette and the geometry are keyed
#' on; `region` is a short, hemisphere-free key derived from it; `names` is the
#' long-form display name, and is also the `region` value this atlas shipped
#' before version 0.1.0 (see [legacy_region_map()]).
