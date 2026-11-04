test_that("frequencies sum to 1 and wrap around north", {
  f <- wind_direction_freq(c(350, 10, 5, 355))
  expect_equal(sum(f$frequency), 1)
  expect_equal(f$frequency[1], 1)
  expect_equal(nrow(f), 16)
})

test_that("360 and negative directions wrap into the right sector", {
  f <- wind_direction_freq(c(360, -5, 720), n_sectors = 8)
  expect_equal(f$count[1], 3)
  g <- wind_direction_freq(-90, n_sectors = 4)
  expect_equal(g$count[g$sector_center == 270], 1)
})

test_that("sector boundaries follow the half-open convention", {
  # 8 sectors: width 45, sector 1 = [337.5, 22.5), sector 2 = [22.5, 67.5)
  f <- wind_direction_freq(c(22.5, 337.5, 22.4999), n_sectors = 8)
  expect_equal(f$count[2], 1)
  expect_equal(f$count[1], 2)
})

test_that("sector centres are correct", {
  f <- wind_direction_freq(0, n_sectors = 8)
  expect_equal(f$sector_center, seq(0, 315, by = 45))
})

test_that("NA directions are dropped", {
  f <- wind_direction_freq(c(NA, 90, 90), n_sectors = 4)
  expect_equal(sum(f$count), 2)
  expect_equal(f$frequency[2], 1)
})

test_that("invalid inputs give clear errors", {
  expect_error(wind_direction_freq("north"), "numeric")
  expect_error(wind_direction_freq(c(NA_real_, NA_real_)), "No usable")
  expect_error(wind_direction_freq(10, n_sectors = 3), "whole number")
  expect_error(wind_direction_freq(10, n_sectors = 7.5), "whole number")
  expect_error(wind_direction_freq(10, n_sectors = c(8, 16)), "whole number")
  expect_error(wind_direction_freq(Inf), "infinite")
})

test_that("speed classes split frequencies and still sum to 1", {
  f <- wind_direction_freq(
    dir = c(0, 90, 90, 270), speed = c(2, 6, 12, 4),
    speed_breaks = c(0, 5, 10, Inf), n_sectors = 4
  )
  expect_equal(nrow(f), 4 * 3)
  expect_equal(sum(f$frequency), 1)
  expect_s3_class(f$speed_class, "factor")
  east <- f[f$sector_center == 90, ]
  expect_equal(east$count, c(0, 1, 1))
})

test_that("speed validation and out-of-range speeds", {
  expect_error(wind_direction_freq(c(0, 90), speed = 1), "same length")
  expect_error(wind_direction_freq(0, speed = 1), "speed_breaks")
  expect_error(
    wind_direction_freq(0, speed = 1, speed_breaks = c(5, 0)), "increasing"
  )
  expect_warning(
    f <- wind_direction_freq(c(0, 90), speed = c(1, 50),
                             speed_breaks = c(0, 10)),
    "dropped"
  )
  expect_equal(sum(f$count), 1)
  expect_warning(wind_direction_freq(0, speed_breaks = c(0, 1)), "ignored")
})
