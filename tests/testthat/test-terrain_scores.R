test_that("flatness ramps linearly between flat and steep", {
  # drop / 10 m cell: tan(5 deg) * 10 and tan(10 deg) * 10.
  gentle <- tilted_plane(10 * tan(5 * pi / 180))
  mid <- tilted_plane(10 * tan(10 * pi / 180))
  steep <- tilted_plane(10 * tan(20 * pi / 180))
  expect_equal(sx_values(flatness_score(gentle))[4, 4], 1)
  expect_equal(sx_values(flatness_score(mid))[4, 4], 0.5)
  expect_equal(sx_values(flatness_score(steep))[4, 4], 0)
})

test_that("flatness is NA on the outer ring and named", {
  s <- flatness_score(dem_from_matrix(matrix(1, 5, 5)))
  v <- sx_values(s)
  expect_equal(names(s), "flatness_score")
  expect_true(all(is.na(v[c(1, 5), ])) && all(is.na(v[, c(1, 5)])))
  expect_equal(v[2:4, 2:4], matrix(1, 3, 3))
})

test_that("aspect score is 1 facing the preferred direction and 0 opposite", {
  east <- tilted_plane(5)
  expect_equal(sx_values(aspect_score(east, preferred_aspect = 90))[4, 4], 1)
  expect_equal(sx_values(aspect_score(east, preferred_aspect = 270))[4, 4], 0)
  south <- tilted_plane(5, "south")
  expect_equal(sx_values(aspect_score(south, preferred_aspect = 180))[4, 4], 1)
})

test_that("aspect score is neutral on flat ground", {
  # terra reports aspect 90 on flat cells; the slope weight must cancel it.
  flat <- dem_from_matrix(matrix(100, 5, 5))
  expect_equal(sx_values(aspect_score(flat, preferred_aspect = 90))[3, 3], 0.5)
})

test_that("aspect effect scales with slope below full_effect_slope", {
  half <- tilted_plane(10 * tan(5 * pi / 180))
  s <- aspect_score(half, preferred_aspect = 90, full_effect_slope = 10)
  s <- sx_values(s)
  expect_equal(s[4, 4], 0.75)
})

test_that("invalid inputs give informative errors", {
  dem <- dem_from_matrix(matrix(1, 5, 5))
  expect_snapshot(flatness_score(dem, flat = 15, steep = 5), error = TRUE)
  expect_snapshot(aspect_score(dem, preferred_aspect = NA), error = TRUE)
  expect_snapshot(aspect_score(dem, full_effect_slope = 0), error = TRUE)
})
