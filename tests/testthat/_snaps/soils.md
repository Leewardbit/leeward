# drainage_score() rejects classes missing from scores

    Code
      drainage_score(grid_4x4(), soils)
    Condition
      Error in `drainage_score()`:
      ! Unknown class in `soils`: "Soggy".
      i Add the missing classes to `scores`, or recode the column.

# drainage_score() rejects a missing column

    Code
      drainage_score(grid_4x4(), two_soils(), column = "drainage")
    Condition
      Error in `drainage_score()`:
      ! `soils` has no column "drainage".
      i Columns: "drclassdcd" and "flodfreqmax".

# flood_exclusion() rejects classes outside the NRCS list

    Code
      flood_exclusion(grid_4x4(), soils)
    Condition
      Error in `flood_exclusion()`:
      ! Unknown class in `soils`: "Sometimes".
      i Recode the column to NRCS class names: "None", "Very rare", "Rare", "Occasional", "Common", "Frequent", and "Very frequent".

# flood_exclusion() rejects an unknown exclude class

    Code
      flood_exclusion(grid_4x4(), two_soils(), exclude = "Often")
    Condition
      Error in `flood_exclusion()`:
      ! `exclude` must contain flooding frequency classes.
      i Classes: "None", "Very rare", "Rare", "Occasional", "Common", "Frequent", and "Very frequent".

