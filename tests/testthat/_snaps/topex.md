# invalid inputs give informative errors

    Code
      topex(dem, max_dist = 20, n_directions = 3)
    Condition
      Error in `topex()`:
      ! `n_directions` must be a single whole number >= 4, not 3.

---

    Code
      topex(dem, max_dist = 5)
    Condition
      Error in `topex()`:
      ! `max_dist` must be a single number >= the DEM resolution (10 m), not 5.

