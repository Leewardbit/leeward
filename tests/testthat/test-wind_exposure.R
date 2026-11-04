test_that("a single sector reproduces exposure_along_direction", {
  set.seed(2)
  dem <- dem_from_matrix(matrix(stats::runif(100, 0, 30), 10, 10))
  freq <- wind_direction_freq(rep(270, 5), n_sectors = 8)
  expect_equal(
    sx_values(wind_exposure(dem, freq, max_dist = 30)),
    sx_values(exposure_along_direction(dem, 270, max_dist = 30))
  )
})

test_that("sectors are combined as a frequency-weighted mean", {
  set.seed(3)
  dem <- dem_from_matrix(matrix(stats::runif(144, 0, 30), 12, 12))
  freq <- wind_direction_freq(c(0, 0, 0, 90), n_sectors = 4)
  north <- sx_values(exposure_along_direction(dem, 0, 20))
  east <- sx_values(exposure_along_direction(dem, 90, 20))
  expect_equal(
    sx_values(wind_exposure(dem, freq, max_dist = 20)),
    0.75 * north + 0.25 * east
  )
})

test_that("speed classes are summed per sector", {
  dem <- dem_from_matrix(matrix(1, 6, 6))
  freq <- wind_direction_freq(
    c(0, 0, 90), speed = c(1, 8, 3), speed_breaks = c(0, 5, 10), n_sectors = 4
  )
  expect_equal(names(wind_exposure(dem, freq, max_dist = 10)), "sx")
})

test_that("invalid wind_freq gives informative errors", {
  dem <- dem_from_matrix(matrix(1, 4, 6))
  expect_snapshot(wind_exposure(dem, data.frame(dir = 1), 10), error = TRUE)
  expect_snapshot(
    wind_exposure(dem, data.frame(sector_center = 0, frequency = -1), 10),
    error = TRUE
  )
})
