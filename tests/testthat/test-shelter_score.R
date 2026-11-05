test_that("shelter_score rises with shelter and clamps to 0--1", {
  sx <- dem_from_matrix(matrix(c(-5, 0, 5, 10, 20), 1))
  out <- shelter_score(sx, exposed = 0, sheltered = 10)
  expect_equal(names(out), "shelter_score")
  expect_equal(as.vector(terra::values(out)), c(0, 0, 0.5, 1, 1))
})

test_that("negative breakpoints are allowed", {
  sx <- dem_from_matrix(matrix(c(-10, -5, 0), 1))
  out <- shelter_score(sx, exposed = -10, sheltered = 0)
  expect_equal(as.vector(terra::values(out)), c(0, 0.5, 1))
})

test_that("shelter_score() rejects reversed breakpoints", {
  expect_snapshot(
    shelter_score(tilted_plane(1), exposed = 10, sheltered = 0),
    error = TRUE
  )
})

test_that("shelter_score() rejects a non-raster", {
  expect_snapshot(shelter_score(1:3), error = TRUE)
})
