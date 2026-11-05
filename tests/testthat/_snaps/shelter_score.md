# shelter_score() rejects reversed breakpoints

    Code
      shelter_score(tilted_plane(1), exposed = 10, sheltered = 0)
    Condition
      Error in `shelter_score()`:
      ! `exposed` and `sheltered` must be single numbers with `exposed` < `sheltered`.

# shelter_score() rejects a non-raster

    Code
      shelter_score(1:3)
    Condition
      Error in `shelter_score()`:
      ! `shelter` must be a single-layer <SpatRaster>.
      i Create one with `wind_exposure()` or `topex()`.

