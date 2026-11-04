test_that("a flat plane has zero topex", {
  dem <- dem_from_matrix(matrix(100, 9, 9))
  tx <- sx_values(topex(dem, max_dist = 20))
  expect_equal(tx[3:7, 3:7], matrix(0, 5, 5))
})

test_that("topex is the sum of skyline angles over directions", {
  set.seed(4)
  dem <- dem_from_matrix(matrix(stats::runif(121, 0, 20), 11, 11))
  by_direction <- lapply(
    c(0, 90, 180, 270),
    function(d) sx_values(exposure_along_direction(dem, d, max_dist = 20))
  )
  expect_equal(
    sx_values(topex(dem, max_dist = 20, n_directions = 4)),
    Reduce(`+`, by_direction)
  )
})

test_that("a bowl is sheltered and a peak is exposed", {
  d <- outer(-5:5, -5:5, function(x, y) sqrt(x^2 + y^2))
  bowl <- sx_values(topex(dem_from_matrix(d * 10), max_dist = 30))
  peak <- sx_values(topex(dem_from_matrix(-d * 10), max_dist = 30))
  expect_gt(bowl[6, 6], 0)
  expect_lt(peak[6, 6], 0)
})

test_that("declination = FALSE clamps negative angles to zero", {
  d <- outer(-5:5, -5:5, function(x, y) sqrt(x^2 + y^2))
  peak <- dem_from_matrix(-d * 10)
  expect_equal(sx_values(topex(peak, 30, declination = FALSE))[6, 6], 0)
})

test_that("output is named topex and NA where the search leaves the DEM", {
  dem <- dem_from_matrix(matrix(1, 8, 8))
  tx <- topex(dem, max_dist = 20)
  expect_equal(names(tx), "topex")
  expect_true(all(is.na(sx_values(tx)[1:2, ])))
})

test_that("invalid inputs give informative errors", {
  dem <- dem_from_matrix(matrix(1, 8, 8))
  expect_snapshot(topex(dem, max_dist = 20, n_directions = 3), error = TRUE)
  expect_snapshot(topex(dem, max_dist = 5), error = TRUE)
})
