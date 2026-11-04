# invalid wind_freq gives informative errors

    Code
      wind_exposure(dem, data.frame(dir = 1), 10)
    Condition
      Error in `wind_exposure()`:
      ! `wind_freq` must be a data frame with columns sector_center and frequency.
      i Create one with `wind_direction_freq()`.

---

    Code
      wind_exposure(dem, data.frame(sector_center = 0, frequency = -1), 10)
    Condition
      Error in `wind_exposure()`:
      ! frequency must be non-negative with a positive sum.

