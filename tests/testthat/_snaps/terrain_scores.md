# invalid inputs give informative errors

    Code
      flatness_score(dem, flat = 15, steep = 5)
    Condition
      Error in `flatness_score()`:
      ! `flat` and `steep` must be single numbers with 0 <= `flat` < `steep`.

---

    Code
      aspect_score(dem, preferred_aspect = NA)
    Condition
      Error in `aspect_score()`:
      ! `direction` must be a single finite number of degrees, not NA.

---

    Code
      aspect_score(dem, full_effect_slope = 0)
    Condition
      Error in `aspect_score()`:
      ! `full_effect_slope` must be a single positive number of degrees.

