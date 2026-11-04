# Builds man/figures/README-vesuvius.png from the bundled example data.

pkgload::load_all()

dem <- terra::rast("inst/extdata/vesuvius_dem.tif")
wind <- utils::read.csv("inst/extdata/hts_wind.csv")
freq <- wind_direction_freq(wind$drct[wind$month %in% 5:10], n_sectors = 16)
sx <- wind_exposure(dem, freq, max_dist = 300)

sx <- terra::trim(sx)
hill <- terra::shade(
  terra::terrain(dem, "slope", unit = "radians"),
  terra::terrain(dem, "aspect", unit = "radians")
)
hill <- terra::crop(hill, sx)
# A few cliff-edge cells reach |Sx| > 25; clamp so the bulk keeps contrast.
lim <- ceiling(stats::quantile(abs(terra::values(sx)), 0.99, na.rm = TRUE))
sx_plot <- terra::clamp(sx, -lim, lim)
pal <- grDevices::hcl.colors(101, "Blue-Red 3", rev = TRUE)

grDevices::png("man/figures/README-vesuvius.png", 1600, 760, res = 150)
graphics::par(mfrow = c(1, 2))
terra::plot(hill, col = grDevices::grey(0:100 / 100), legend = FALSE,
            axes = FALSE, mar = c(1, 1, 2.5, 4),
            main = "Lake Vesuvius area, Wayne NF")
terra::plot(sx_plot, col = pal, range = c(-lim, lim), axes = FALSE,
            mar = c(1, 1, 2.5, 4), type = "continuous",
            main = "Sx (deg), May-Oct winds at HTS")
terra::plot(hill, col = grDevices::grey(0:100 / 100, alpha = 0.3),
            legend = FALSE, axes = FALSE, add = TRUE)
grDevices::dev.off()
