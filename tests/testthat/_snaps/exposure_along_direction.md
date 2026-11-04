# invalid inputs give informative errors

    Code
      exposure_along_direction(matrix(1, 3, 3), 0, 10)
    Condition
      Error in `exposure_along_direction()`:
      ! `dem` must be a <SpatRaster>, not a double matrix.

---

    Code
      exposure_along_direction(c(dem, dem), 0, 10)
    Condition
      Error in `exposure_along_direction()`:
      ! `dem` must have one layer, not 2.

---

    Code
      exposure_along_direction(lonlat, 0, 10)
    Condition
      Error in `exposure_along_direction()`:
      ! `dem` must use a projected CRS with meter units.
      i Reproject with `terra::project(dem, "EPSG:<utm zone>")`.

---

    Code
      exposure_along_direction(dem, NA, 10)
    Condition
      Error in `exposure_along_direction()`:
      ! `direction` must be a single finite number of degrees, not NA.

---

    Code
      exposure_along_direction(dem, 0, 5)
    Condition
      Error in `exposure_along_direction()`:
      ! `max_dist` must be a single number >= the DEM resolution (10 m), not 5.

