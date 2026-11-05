# camp_suitability() requires weights

    Code
      camp_suitability(list(a = const(1)), exclusions = list())
    Condition
      Error in `camp_suitability()`:
      ! `weights` is required.
      i There is no default: choose how much each score matters, e.g. `weights = c(flat = 2, water = 1)`.

# camp_suitability() requires exclusions

    Code
      camp_suitability(list(a = const(1)), c(a = 1))
    Condition
      Error in `camp_suitability()`:
      ! `exclusions` is required.
      i Pass hazard masks such as `channel_exclusion()` and `water_exclusion()`, or `list()` to apply none.

# camp_suitability() rejects mismatched weight names

    Code
      camp_suitability(list(a = const(1)), c(b = 1), list())
    Condition
      Error in `camp_suitability()`:
      ! `weights` names must match `scores` names exactly.
      x No weight for "a".
      x No score named "b".
      i Scores: "a".

# camp_suitability() rejects scores outside 0--1

    Code
      camp_suitability(list(sx = const(12)), c(sx = 1), list())
    Condition
      Error in `camp_suitability()`:
      ! Score "sx" must be in 0--1, but ranges from 12 to 12.
      i Convert raw indexes first, e.g. `shelter_score()` for Sx.

# camp_suitability() rejects layers on different grids

    Code
      camp_suitability(list(a = const(1), b = const(1, n = 4)), c(a = 1, b = 1), list())
    Condition
      Error in `camp_suitability()`:
      ! All `scores` and `exclusions` must share one grid.
      x "b" does not match "a" in extent, resolution, or CRS.
      i Build every layer from the same DEM, or align them with `terra::resample()`.

# camp_suitability() rejects a numeric exclusion

    Code
      camp_suitability(list(a = const(1)), c(a = 1), list(const(0)))
    Condition
      Error in `camp_suitability()`:
      ! Exclusion 1 ("lyr.1") must be logical.
      i Use a comparison, e.g. `dist < 61`, or an `*_exclusion()` function.

# candidate_areas() rejects a bad min_score

    Code
      candidate_areas(suit, min_score = 2)
    Condition
      Error in `candidate_areas()`:
      ! `min_score` must be a single number from 0 to 1.

