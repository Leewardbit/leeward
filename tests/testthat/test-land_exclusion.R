test_that("cells count as allowed only when their center is inside", {
  out <- sx_values(land_exclusion(grid_4x4(), allowed = square(21)))
  expected <- matrix(TRUE, 4, 4)
  expected[3:4, 1:2] <- FALSE
  expect_equal(out, expected, ignore_attr = TRUE)
})

test_that("cells touching a prohibited polygon are excluded", {
  out <- sx_values(land_exclusion(grid_4x4(), prohibited = square(21)))
  expected <- matrix(FALSE, 4, 4)
  expected[2:4, 1:3] <- TRUE
  expect_equal(out, expected, ignore_attr = TRUE)
})

test_that("allowed and prohibited combine", {
  out <- land_exclusion(
    grid_4x4(),
    allowed = square(40), prohibited = square(9)
  )
  expect_equal(sum(terra::values(out)), 1)
})

test_that("NA cells in the DEM stay NA", {
  dem <- grid_4x4()
  dem[1] <- NA
  out <- terra::values(land_exclusion(dem, allowed = square(40)))
  expect_equal(is.na(out[, 1]), c(TRUE, rep(FALSE, 15)))
})

test_that("land_exclusion() needs at least one polygon set", {
  expect_snapshot(land_exclusion(grid_4x4()), error = TRUE)
})

test_that("land_exclusion() rejects lines", {
  expect_snapshot(land_exclusion(grid_4x4(), allowed = stream()), error = TRUE)
})

test_that("land_exclusion() rejects a CRS mismatch", {
  other <- terra::project(square(21), "EPSG:4326")
  expect_snapshot(land_exclusion(grid_4x4(), prohibited = other), error = TRUE)
})
