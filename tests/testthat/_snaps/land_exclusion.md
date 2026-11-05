# land_exclusion() needs at least one polygon set

    Code
      land_exclusion(grid_4x4())
    Condition
      Error in `land_exclusion()`:
      ! Supply `allowed`, `prohibited`, or both.

# land_exclusion() rejects lines

    Code
      land_exclusion(grid_4x4(), allowed = stream())
    Condition
      Error in `land_exclusion()`:
      ! `allowed` must contain polygons, not lines.

# land_exclusion() rejects a CRS mismatch

    Code
      land_exclusion(grid_4x4(), prohibited = other)
    Condition
      Error in `land_exclusion()`:
      ! `prohibited` must use the same CRS as `dem`.
      i Reproject with `terra::project(prohibited, dem)`.

