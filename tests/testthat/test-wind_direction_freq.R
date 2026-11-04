test_that("frequencies sum to 1 and wrap around north", {
  f <- wind_direction_freq(c(350, 10, 5, 355))
  expect_equal(nrow(f), 16)
  expect_equal(sum(f$frequency), 1)
  expect_equal(f$frequency[1], 1)
})

test_that("360 and negative directions wrap into the right sector", {
  expect_equal(wind_direction_freq(c(360, -5, 720), n_sectors = 8)$count[1], 3)
  f <- wind_direction_freq(-90, n_sectors = 4)
  expect_equal(f$count[f$sector_center == 270], 1)
})

test_that("sector boundaries are half-open on the clockwise side", {
  # 8 sectors: sector 1 = [337.5, 22.5), sector 2 = [22.5, 67.5)
  f <- wind_direction_freq(c(22.5, 337.5, 22.4999), n_sectors = 8)
  expect_equal(f$count[1:2], c(2, 1))
})

test_that("sector centres step by 360 / n_sectors from north", {
  expect_equal(
    wind_direction_freq(0, n_sectors = 8)$sector_center,
    seq(0, 315, by = 45)
  )
})

test_that("NA directions are dropped", {
  f <- wind_direction_freq(c(NA, 90, 90), n_sectors = 4)
  expect_equal(f$count, c(0, 2, 0, 0))
})

test_that("speed classes split counts and frequencies still sum to 1", {
  f <- wind_direction_freq(
    dir = c(0, 90, 90, 270),
    speed = c(2, 6, 12, 4),
    speed_breaks = c(0, 5, 10, Inf),
    n_sectors = 4
  )
  expect_equal(nrow(f), 12)
  expect_equal(sum(f$frequency), 1)
  expect_equal(f$count[f$sector_center == 90], c(0, 1, 1))
})

test_that("speeds outside the breaks are dropped with a warning", {
  expect_snapshot(
    f <- wind_direction_freq(
      c(0, 90),
      speed = c(1, 50), speed_breaks = c(0, 10)
    )
  )
  expect_equal(sum(f$count), 1)
})

test_that("invalid inputs give informative errors", {
  expect_snapshot(wind_direction_freq("north"), error = TRUE)
  expect_snapshot(wind_direction_freq(10, n_sectors = 7.5), error = TRUE)
  expect_snapshot(wind_direction_freq(Inf), error = TRUE)
  expect_snapshot(wind_direction_freq(c(NA_real_, NA_real_)), error = TRUE)
  expect_snapshot(wind_direction_freq(c(0, 90), speed = 1), error = TRUE)
  expect_snapshot(wind_direction_freq(0, speed = 1), error = TRUE)
})

test_that("speed_breaks without speed warns", {
  expect_snapshot(wind_direction_freq(0, speed_breaks = c(0, 1)))
})
