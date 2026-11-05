# canopy_score() rejects NLCD no-data codes

    Code
      canopy_score(canopy)
    Condition
      Error in `canopy_score()`:
      ! `canopy` must be percent cover, 0--100, but ranges from 50 to 255.
      i NLCD uses 254 and 255 for no data. Set them to `NA` first, e.g. `terra::classify(canopy, cbind(c(254, 255), NA))`.

# canopy_score() rejects reversed breakpoints

    Code
      canopy_score(canopy_row(), open = 70, closed = 20)
    Condition
      Error in `canopy_score()`:
      ! `open` and `closed` must be percentages with 0 <= `open` < `closed` <= 100.

