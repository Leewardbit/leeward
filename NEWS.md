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
