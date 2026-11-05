# leeward (development version)

* `flatness_score()` and `aspect_score()` score terrain from 0 to 1. The
  aspect score fades to neutral on flat ground, where terra's aspect is
  arbitrary.
* `water_distance()` measures distance to the nearest stream or waterbody.
  `water_score()` turns it into a 0--1 access score and `water_exclusion()`
  into a hard setback mask (default 61 m / 200 ft).
* Layers follow a convention: `*_score` (0--1, weighted later) and
  `*_exclusion` (logical, `TRUE` = excluded).
* `contributing_area()` fills depressions (Planchon and Darboux 2002) and
  routes flow by D8. `height_above_channel()` gives HAND, height above the
  DEM-derived channel each cell drains to, and `channel_exclusion()` masks
  low ground along channels (defaults: 1 ha channel start, 3 m). This
  covers the unmapped hollows that stream maps miss.
* `camp_suitability()` combines named 0--1 scores with explicit weights
  (no defaults) and applies every exclusion as a hard rule. `NA` in an
  exclusion counts as excluded. It returns `suitability` and `excluded`
  layers.
* `candidate_areas()` returns ranked polygons of the best patches: candidate
  areas to scout, not campsites.
* `shelter_score()` turns Sx or TOPEX into a 0--1 score.
* `drainage_score()` scores SSURGO drainage class, and `flood_exclusion()`
  excludes soils that flood (by default Occasional or more often, using the
  most frequent class of any component). Unknown classes are an error.
* `canopy_score()` scores percent tree canopy, toward cover or open ground.
* New example data: `vesuvius_soils.gpkg` (SSURGO) and `vesuvius_canopy.tif`
  (NLCD Tree Canopy Cover 2021).
* `land_exclusion()` builds an exclusion from user-supplied allowed and
  prohibited polygons. It errs toward exclusion and is a filter, not a
  statement of the law.
* New example data: `vesuvius_water.gpkg` (high-resolution NHD).

# leeward 0.1.0

First release: terrain wind exposure core.

* `wind_direction_freq()` bins wind directions into compass sectors, with
  optional speed classes.
* `exposure_along_direction()` computes the Winstral et al. (2002) Sx index
  for one wind direction.
* `wind_exposure()` combines Sx across sectors, weighted by wind frequency.
* `topex()` computes distance-limited TOPEX (Quine and White 1998).
* `suggest_max_dist()` proposes a search distance from DEM relief. Sx
  functions use it, with a message, when `max_dist` is not supplied.
* Example data: a 10 m DEM around Lake Vesuvius, Wayne National Forest, and
  2021–2025 hourly winds from Huntington, WV (HTS).
