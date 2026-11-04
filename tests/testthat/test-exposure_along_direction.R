test_that("a flat plane has zero shelter", {
  dem <- dem_from_matrix(matrix(100, 5, 10))
  sx <- sx_values(exposure_along_direction(dem, 270, max_dist = 30))
  expect_equal(sx[, 4:10], matrix(0, 5, 7))
})

test_that("cells whose upwind line leaves the DEM are NA", {
  dem <- dem_from_matrix(matrix(100, 5, 10))
  sx <- sx_values(exposure_along_direction(dem, 270, max_dist = 30))
  expect_true(all(is.na(sx[, 1:3])))
  sx_north <- sx_values(exposure_along_direction(dem, 0, max_dist = 20))
  expect_true(all(is.na(sx_north[1:2, ])))
  expect_false(anyNA(sx_north[3:5, ]))
})

test_that("Sx matches a hand-computed angle", {
  z <- matrix(0, 3, 5)
  z[2, 2] <- 10
  dem <- dem_from_matrix(z)
  sx <- sx_values(exposure_along_direction(dem, 270, max_dist = 10))
  expect_equal(sx[2, 3], 45)
  expect_equal(sx[2, 2], atan(-10 / 10) * 180 / pi)
})

test_that("the lee of a ridge is sheltered and the windward slope exposed", {
  x <- seq_len(41)
  z <- matrix(rep(pmax(0, 100 - 5 * abs(x - 21)), each = 5), nrow = 5)
  dem <- dem_from_matrix(z)
  sx <- sx_values(exposure_along_direction(dem, 270, max_dist = 100))
  expect_gt(sx[3, 25], 0)
  expect_lt(sx[3, 18], 0)
})

test_that("mirroring the DEM mirrors the wind direction", {
  set.seed(1)
  z <- matrix(stats::runif(15 * 15, 0, 50), 15, 15)
  east <- sx_values(exposure_along_direction(dem_from_matrix(z), 90, 50))
  west <- sx_values(
    exposure_along_direction(dem_from_matrix(z[, 15:1]), 270, 50)
  )
  expect_equal(east, west[, 15:1])
})

test_that("output keeps the DEM grid and is named sx", {
  dem <- dem_from_matrix(matrix(1, 4, 6))
  sx <- exposure_along_direction(dem, 45, max_dist = 10)
  expect_true(terra::compareGeom(dem, sx))
  expect_equal(names(sx), "sx")
})

test_that("missing max_dist uses a terrain-based default with a message", {
  dem <- dem_from_matrix(matrix(100, 10, 30))
  expect_message(
    exposure_along_direction(dem, 270),
    class = "leeward_max_dist_default"
  )
})

test_that("invalid inputs give informative errors", {
  dem <- dem_from_matrix(matrix(1, 4, 6))
  lonlat <- terra::rast(matrix(1, 4, 6), crs = "EPSG:4326")
  expect_snapshot(
    exposure_along_direction(matrix(1, 3, 3), 0, 10),
    error = TRUE
  )
  expect_snapshot(exposure_along_direction(c(dem, dem), 0, 10), error = TRUE)
  expect_snapshot(exposure_along_direction(lonlat, 0, 10), error = TRUE)
  expect_snapshot(exposure_along_direction(dem, NA, 10), error = TRUE)
  expect_snapshot(exposure_along_direction(dem, 0, 5), error = TRUE)
})
