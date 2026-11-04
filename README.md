# leeward

> Find sheltered, flat, legal, well-drained places to camp, built on a
> transparent, well-documented terrain wind exposure model.

**Status:** early development (v0.1 in progress). Only
`wind_direction_freq()` is implemented so far.

## What it does (planned)

1. **Wind exposure (v0.1).** Computes terrain-based exposure from a DEM and a
   local wind climatology: the Winstral *Sx* upwind-slope index (default) and
   TOPEX, combined across directions weighted by frequency.
2. **Terrain and water (v0.2).** Adds slope/flatness, aspect, and distance to water with a setback.
3. **Suitability (v0.3).** Adds canopy, soil drainage, and a user-supplied land-status
   mask, combined with explicit user-chosen weights.

## Direction convention

Degrees, the direction the wind blows **from**, 0 = north, clockwise.

## Safety and legal framing

- Output marks **candidate areas to scout**, never "safe campsites".
- Sheltered terrain has hazards of its own: flash floods in drainages, cold-air
  pooling, and dead trees or widowmakers under canopy. Exposed ridges carry
  lightning risk.
- Camping rules vary by district and season, and fire restrictions change. The
  land-status layer is a user-supplied filter, **not** an authoritative
  source. Check with the managing agency.

## Related tools

leeward aims to be a lightweight, pure-R (terra) alternative, not a
duplicate:

- SAGA GIS Wind Effect / Wind Exposition Index (via Rsagacmd); RSAGA's
  `wind.shelter()` (Plattner et al. wind shelter index)
- ExposR: topographic exposure to hurricane winds
- windscape: landscape connectivity by wind
- openair (wind roses), extRemes (extreme winds), cffdrs (fire weather)
- ForestGALES: mechanistic windthrow risk (no current CRAN package found)

## License

MIT © Mark Oleson
