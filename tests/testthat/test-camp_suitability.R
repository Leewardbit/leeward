test_that("suitability is the weighted mean of scores", {
  out <- camp_suitability(
    list(a = const(1), b = const(0)),
    weights = c(a = 3, b = 1),
    exclusions = list()
  )
  expect_equal(names(out), c("suitability", "excluded"))
  expect_equal(unique(terra::values(out$suitability)[, 1]), 0.75)
  expect_equal(unique(terra::values(out$excluded)[, 1]), FALSE)
})

test_that("weights are matched by name, not position", {
  out <- camp_suitability(
    list(a = const(1), b = const(0)),
    weights = c(b = 1, a = 3),
    exclusions = list()
  )
  expect_equal(unique(terra::values(out$suitability)[, 1]), 0.75)
})

test_that("an unnamed list uses layer names", {
  out <- camp_suitability(
    list(flatness_score(tilted_plane(1))),
    weights = c(flatness_score = 1),
    exclusions = list()
  )
  expect_equal(names(out)[1], "suitability")
})

test_that("a TRUE exclusion removes the cell", {
  excl <- no_exclusion()
  excl[5] <- TRUE
  out <- camp_suitability(list(a = const(1)), c(a = 1), list(excl))
  expect_equal(is.na(cell(out$suitability, 5)), TRUE)
  expect_equal(cell(out$excluded, 5), TRUE)
  expect_equal(sum(terra::values(out$excluded)), 1)
})

test_that("an NA exclusion counts as excluded", {
  excl <- no_exclusion()
  excl[5] <- NA
  out <- camp_suitability(list(a = const(1)), c(a = 1), list(excl))
  expect_equal(cell(out$excluded, 5), TRUE)
  expect_equal(is.na(cell(out$suitability, 5)), TRUE)
})

test_that("an NA score gives NA suitability without excluding", {
  score <- const(1)
  score[5] <- NA
  out <- camp_suitability(list(a = score), c(a = 1), list(no_exclusion()))
  expect_equal(is.na(cell(out$suitability, 5)), TRUE)
  expect_equal(cell(out$excluded, 5), FALSE)
})

test_that("a zero-weight score does not spread its NA cells", {
  unused <- const(1)
  unused[5] <- NA
  out <- camp_suitability(
    list(a = const(0.5), b = unused),
    weights = c(a = 1, b = 0),
    exclusions = list()
  )
  expect_equal(unique(terra::values(out$suitability)[, 1]), 0.5)
})

test_that("a multi-layer SpatRaster works for scores and exclusions", {
  scores <- c(const(1), const(0))
  names(scores) <- c("a", "b")
  excl <- c(no_exclusion(), no_exclusion())
  out <- camp_suitability(scores, c(a = 1, b = 1), excl)
  expect_equal(unique(terra::values(out$suitability)[, 1]), 0.5)
})

test_that("camp_suitability() requires weights", {
  expect_snapshot(
    camp_suitability(list(a = const(1)), exclusions = list()),
    error = TRUE
  )
})

test_that("camp_suitability() requires exclusions", {
  expect_snapshot(camp_suitability(list(a = const(1)), c(a = 1)), error = TRUE)
})

test_that("camp_suitability() rejects mismatched weight names", {
  expect_snapshot(
    camp_suitability(list(a = const(1)), c(b = 1), list()),
    error = TRUE
  )
})

test_that("camp_suitability() rejects scores outside 0--1", {
  expect_snapshot(
    camp_suitability(list(sx = const(12)), c(sx = 1), list()),
    error = TRUE
  )
})

test_that("camp_suitability() rejects layers on different grids", {
  expect_snapshot(
    camp_suitability(list(a = const(1), b = const(1, n = 4)),
      c(a = 1, b = 1), list()
    ),
    error = TRUE
  )
})

test_that("camp_suitability() rejects a numeric exclusion", {
  expect_snapshot(
    camp_suitability(list(a = const(1)), c(a = 1), list(const(0))),
    error = TRUE
  )
})

test_that("candidate areas are ranked patches above min_score", {
  z <- matrix(0, 5, 7)
  z[1:2, 1:2] <- 0.8
  z[4:5, 5:7] <- 0.95
  suit <- camp_suitability(list(a = dem_from_matrix(z)), c(a = 1), list())
  out <- candidate_areas(suit, min_score = 0.7, min_area = 0)
  expect_equal(out$rank, 1:2)
  expect_equal(out$area_m2, c(600, 400))
  expect_equal(out$mean_score, c(0.95, 0.8))
})

test_that("candidate areas drop small patches", {
  z <- matrix(0, 5, 7)
  z[1, 1] <- 1
  z[4:5, 5:7] <- 0.9
  suit <- camp_suitability(list(a = dem_from_matrix(z)), c(a = 1), list())
  out <- candidate_areas(suit, min_score = 0.7, min_area = 200)
  expect_equal(nrow(out), 1)
  expect_equal(out$area_m2, 600)
})

test_that("excluded cells never become candidates", {
  excl <- no_exclusion()
  excl[1:9] <- c(TRUE, NA, TRUE, TRUE, NA, TRUE, TRUE, TRUE, TRUE)
  suit <- camp_suitability(list(a = const(1)), c(a = 1), list(excl))
  out <- candidate_areas(suit, min_score = 0, min_area = 0)
  expect_equal(nrow(out), 0)
  expect_equal(names(out), c("rank", "area_m2", "mean_score", "max_score"))
})

test_that("candidate_areas() rejects a bad min_score", {
  suit <- camp_suitability(list(a = const(1)), c(a = 1), list())
  expect_snapshot(candidate_areas(suit, min_score = 2), error = TRUE)
})
