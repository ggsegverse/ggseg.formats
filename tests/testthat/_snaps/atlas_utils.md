# atlas_region_rename / warns when a string matches labels but changes no region

    Code
      result <- atlas_region_rename(atlas, "^lh_", "left ")
    Condition
      Warning:
      No region was renamed.
      i "^lh_" matches 2 rows on label, but none of their regions contain it.
      i Pass a function as `replacement` to set those regions outright, or `match_on = "region"` to match the region text.

