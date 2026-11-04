# speeds outside the breaks are dropped with a warning

    Code
      f <- wind_direction_freq(c(0, 90), speed = c(1, 50), speed_breaks = c(0, 10))
    Condition
      Warning in `wind_direction_freq()`:
      Dropped 1 observation with speed outside `speed_breaks`.

# invalid inputs give informative errors

    Code
      wind_direction_freq("north")
    Condition
      Error in `wind_direction_freq()`:
      ! `dir` must be numeric, not a string.

---

    Code
      wind_direction_freq(10, n_sectors = 7.5)
    Condition
      Error in `wind_direction_freq()`:
      ! `n_sectors` must be a single whole number >= 4, not 7.5.

---

    Code
      wind_direction_freq(Inf)
    Condition
      Error in `wind_direction_freq()`:
      ! `dir` must not contain infinite values.

---

    Code
      wind_direction_freq(c(NA_real_, NA_real_))
    Condition
      Error in `wind_direction_freq()`:
      ! No usable observations: all are missing or out of range.

---

    Code
      wind_direction_freq(c(0, 90), speed = 1)
    Condition
      Error in `wind_direction_freq()`:
      ! `speed` must have the same length as `dir` (2), not 1.

---

    Code
      wind_direction_freq(0, speed = 1)
    Condition
      Error in `wind_direction_freq()`:
      ! `speed_breaks` must be a strictly increasing numeric vector of length >= 2.
      i It is required when `speed` is supplied.

# speed_breaks without speed warns

    Code
      wind_direction_freq(0, speed_breaks = c(0, 1))
    Condition
      Warning:
      `speed_breaks` is ignored when `speed` is NULL.
    Output
         sector sector_center count frequency
      1       1           0.0     1         1
      2       2          22.5     0         0
      3       3          45.0     0         0
      4       4          67.5     0         0
      5       5          90.0     0         0
      6       6         112.5     0         0
      7       7         135.0     0         0
      8       8         157.5     0         0
      9       9         180.0     0         0
      10     10         202.5     0         0
      11     11         225.0     0         0
      12     12         247.5     0         0
      13     13         270.0     0         0
      14     14         292.5     0         0
      15     15         315.0     0         0
      16     16         337.5     0         0

