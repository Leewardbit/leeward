test_that("distance to a line is measured from cell centers", {
  d <- sx_values(water_distance(water_grid(), stream()))
  expect_equal(d[10, 8:13], c(25, 15, 5, 5, 15, 25))
})

test_that("cells inside a waterbody have distance 0", {
  d <- sx_values(water_distance(water_grid(), pond()))
  expect_equal(d[16:17, 3:6], matrix(0, 2, 4))
})

test_that("a list of lines and polygons takes the nearest feature", {
  d <- sx_values(water_distance(water_grid(), list(stream(), pond())))
  expect_equal(d[10, 11], 5)
  expect_equal(d[17, 4], 0)
})

test_that("sf input is accepted", {
  skip_if_not_installed("sf")
  d <- water_distance(water_grid(), sf::st_as_sf(stream()))
  expect_equal(sx_values(d)[10, 10], 5)
})

test_that("water score is 0 inside the setback and ramps to 0 at reach", {
  d <- dem_from_matrix(matrix(c(10, 60, 61, 430.5, 800, 900), 1))
  s <- sx_values(water_score(d, setback = 61, reach = 800))
  expect_equal(as.vector(s), c(0, 0, 1, 0.5, 0, 0))
})

test_that("water exclusion is TRUE strictly inside the setback", {
  d <- dem_from_matrix(matrix(c(0, 60.9, 61, 100), 1))
  e <- water_exclusion(d, setback = 61)
  expect_equal(names(e), "water_exclusion")
  expect_equal(as.vector(sx_values(e)), c(TRUE, TRUE, FALSE, FALSE))
})

test_that("invalid inputs give informative errors", {
  wrong_crs <- terra::vect("LINESTRING (0 0, 1 1)", crs = "EPSG:4326")
  expect_snapshot(water_distance(water_grid(), wrong_crs), error = TRUE)
  expect_snapshot(water_distance(water_grid(), "creek"), error = TRUE)
  expect_snapshot(water_score(matrix(1)), error = TRUE)
  expect_snapshot(
    water_score(water_grid(), setback = 100, reach = 50),
    error = TRUE
  )
})
