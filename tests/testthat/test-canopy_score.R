test_that("canopy_score rises with cover between open and closed", {
  out <- canopy_score(canopy_row(), open = 20, closed = 70)
  expect_equal(names(out), "canopy_score")
  expect_equal(as.vector(terra::values(out)), c(0, 0, 0.5, 1, 1))
})

test_that("prefer = 'open' reverses the score", {
  out <- canopy_score(canopy_row(), open = 20, closed = 70, prefer = "open")
  expect_equal(as.vector(terra::values(out)), c(1, 1, 0.5, 0, 0))
})

test_that("canopy_score() rejects NLCD no-data codes", {
  canopy <- dem_from_matrix(matrix(c(50, 255), 1))
  expect_snapshot(canopy_score(canopy), error = TRUE)
})

test_that("canopy_score() rejects reversed breakpoints", {
  expect_snapshot(canopy_score(canopy_row(), open = 70, closed = 20),
    error = TRUE
  )
})
