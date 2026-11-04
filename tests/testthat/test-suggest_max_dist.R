test_that("relief tiers map to suggested distances", {
  flat <- dem_from_matrix(matrix(100, 50, 50), res = 30)
  expect_equal(suggest_max_dist(flat)$max_dist, 200)

  x <- seq_len(50)
  steep <- matrix(rep(abs(x - 25) * 40, each = 50), nrow = 50)
  expect_equal(suggest_max_dist(dem_from_matrix(steep, res = 30))$max_dist, 500)
})
