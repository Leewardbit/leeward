two_soils <- function(drainage = c("Well drained", "Poorly drained"),
                      flooding = c("None", "Frequent")) {
  left <- terra::vect(
    "POLYGON ((0 0, 28 0, 28 40, 0 40, 0 0))",
    crs = "EPSG:32617"
  )
  right <- terra::vect(
    "POLYGON ((28 0, 40 0, 40 40, 28 40, 28 0))",
    crs = "EPSG:32617"
  )
  soils <- rbind(left, right)
  soils$drclassdcd <- drainage
  soils$flodfreqmax <- flooding
  soils
}

test_that("drainage_score scores each cell by the class at its center", {
  out <- sx_values(drainage_score(grid_4x4(), two_soils()))
  expect_equal(unname(out[1, ]), c(1, 1, 1, 0.1))
})

test_that("cells with no drainage class have an unknown score", {
  soils <- two_soils(drainage = c("Well drained", NA))
  out <- sx_values(drainage_score(grid_4x4(), soils))
  expect_equal(is.na(unname(out[1, ])), c(FALSE, FALSE, FALSE, TRUE))
})

test_that("drainage_score() rejects classes missing from scores", {
  soils <- two_soils(drainage = c("Well drained", "Soggy"))
  expect_snapshot(drainage_score(grid_4x4(), soils), error = TRUE)
})

test_that("drainage_score() rejects a missing column", {
  expect_snapshot(
    drainage_score(grid_4x4(), two_soils(), column = "drainage"),
    error = TRUE
  )
})

test_that("flood_exclusion excludes cells touching a flooding soil", {
  out <- sx_values(flood_exclusion(grid_4x4(), two_soils()))
  expect_equal(unname(out[1, ]), c(FALSE, FALSE, TRUE, TRUE))
})

test_that("flood_exclusion works as a camp_suitability() exclusion", {
  dem <- grid_4x4()
  out <- camp_suitability(
    list(a = terra::init(dem, 1)), c(a = 1),
    list(flood_exclusion(dem, two_soils()))
  )
  expect_equal(sum(terra::values(out$excluded)), 8)
})

test_that("flood classes not in exclude are kept", {
  soils <- two_soils(flooding = c("None", "Rare"))
  out <- terra::values(flood_exclusion(grid_4x4(), soils))[, 1]
  expect_equal(unique(out), FALSE)
})

test_that("a missing flood class is NA, which counts as excluded later", {
  soils <- two_soils(flooding = c("None", NA))
  out <- sx_values(flood_exclusion(grid_4x4(), soils))
  expect_equal(is.na(unname(out[1, ])), c(FALSE, FALSE, FALSE, TRUE))
})

test_that("flood_exclusion() rejects classes outside the NRCS list", {
  soils <- two_soils(flooding = c("None", "Sometimes"))
  expect_snapshot(flood_exclusion(grid_4x4(), soils), error = TRUE)
})

test_that("flood_exclusion() rejects an unknown exclude class", {
  expect_snapshot(
    flood_exclusion(grid_4x4(), two_soils(), exclude = "Often"),
    error = TRUE
  )
})
