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
