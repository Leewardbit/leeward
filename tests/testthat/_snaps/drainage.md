# height_above_channel() rejects a bad min_area

    Code
      height_above_channel(tilted_plane(1), min_area = -1)
    Condition
      Error in `height_above_channel()`:
      ! `min_area` must be a single positive number of square meters.

# channel_exclusion() rejects a non-raster height

    Code
      channel_exclusion(1:3)
    Condition
      Error in `channel_exclusion()`:
      ! `height` must be a single-layer <SpatRaster>.
      i Create one with `height_above_channel()`.

# channel_exclusion() rejects a negative min_height

    Code
      channel_exclusion(tilted_plane(1), min_height = -1)
    Condition
      Error in `channel_exclusion()`:
      ! `min_height` must be a single non-negative number.

