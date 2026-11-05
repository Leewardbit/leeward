# invalid inputs give informative errors

    Code
      water_distance(water_grid(), wrong_crs)
    Condition
      Error in `water_distance()`:
      ! `water` must use the same CRS as `dem`.
      i Reproject with `terra::project(water, dem)`.

---

    Code
      water_distance(water_grid(), "creek")
    Condition
      Error in `water_distance()`:
      ! `water` must be a <SpatVector>, an <sf> object, or a list of them.

---

    Code
      water_score(matrix(1))
    Condition
      Error in `water_score()`:
      ! `distance` must be a single-layer <SpatRaster>.
      i Create one with `water_distance()`.

---

    Code
      water_score(water_grid(), setback = 100, reach = 50)
    Condition
      Error in `water_score()`:
      ! `setback` and `reach` must be single numbers with 0 <= `setback` < `reach`.

