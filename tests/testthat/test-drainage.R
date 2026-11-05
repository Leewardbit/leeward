test_that("a pit fills to its spill level", {
  z <- matrix(10, 5, 5)
  z[2:4, 2:4] <- 8
  z[3, 3] <- 2
  z[1, 3] <- 5
  filled <- fill_depressions(z, c(10, 10))
  expect_equal(filled[3, 3], 8, tolerance = 1e-3)
  expect_gt(filled[3, 3], 8)
  expect_equal(filled[1, 3], 5)
})

test_that("every cell drains to an outlet", {
  z <- matrix(10, 5, 5)
  z[2:4, 2:4] <- 8
  z[3, 3] <- 2
  z[1, 3] <- 5
  routing <- route_flow(dem_from_matrix(z))
  expect_equal(max(routing$area), 25 * 100)
  terminal <- vapply(seq_along(routing$down), function(i) {
    while (routing$down[i] > 0) i <- routing$down[i]
    i
  }, integer(1))
  expect_equal(unique(terminal), 11L)
})

test_that("contributing area accumulates down a plane", {
  area <- sx_values(contributing_area(tilted_plane(1)))
  expect_equal(area[4, ], seq_len(7) * 100)
})

test_that("the channel follows the valley floor", {
  z <- outer(seq_len(9), seq_len(9), function(i, j) i + 5 * abs(j - 5))
  dem <- dem_from_matrix(z)
  area <- sx_values(contributing_area(dem))
  channel_cols <- unique(col(area)[area >= 1500])
  expect_equal(channel_cols, 5)
})

test_that("height above channel rises up the valley sides", {
  z <- outer(seq_len(9), seq_len(9), function(i, j) i + 5 * abs(j - 5))
  hand <- sx_values(height_above_channel(dem_from_matrix(z), min_area = 1500))
  expect_equal(hand[5, 5], 0)
  expect_gt(min(diff(hand[5, 5:9])), 0)
  expect_gt(min(diff(hand[5, 5:1])), 0)
})

test_that("NA cells stay NA and act as outlets", {
  z <- outer(seq_len(9), seq_len(9), function(i, j) i + 5 * abs(j - 5))
  z[1:3, 1:3] <- NA
  area <- sx_values(contributing_area(dem_from_matrix(z)))
  expect_equal(is.na(area), is.na(z))
  expect_equal(sum(area[!is.na(area)] > 0), sum(!is.na(z)))
})

test_that("cells draining off the DEM without a channel are NA", {
  hand <- height_above_channel(tilted_plane(1), min_area = 1e6)
  expect_equal(unique(is.na(terra::values(hand))[, 1]), TRUE)
})

test_that("channel_exclusion marks low ground and the channel itself", {
  height <- dem_from_matrix(matrix(c(0, 1, 3, 3.5, NA), 1))
  out <- channel_exclusion(height, min_height = 3)
  expect_equal(names(out), "channel_exclusion")
  expect_equal(
    as.vector(terra::values(out)),
    c(TRUE, TRUE, TRUE, FALSE, NA)
  )
})

test_that("height_above_channel() rejects a bad min_area", {
  expect_snapshot(height_above_channel(tilted_plane(1), min_area = -1),
    error = TRUE
  )
})

test_that("channel_exclusion() rejects a non-raster height", {
  expect_snapshot(channel_exclusion(1:3), error = TRUE)
})

test_that("channel_exclusion() rejects a negative min_height", {
  expect_snapshot(
    channel_exclusion(tilted_plane(1), min_height = -1),
    error = TRUE
  )
})
