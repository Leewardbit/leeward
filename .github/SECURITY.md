# Security policy

## Reporting a vulnerability

Please report security issues privately, not in public issues:

- Use GitHub's [private vulnerability reporting](https://github.com/Leewardbit/leeward/security/advisories/new), or
- email leewardMaintain@proton.me.

Include the leeward version, a minimal reproducible example, and the
impact you expect. You should get a reply within 14 days.

## Scope

leeward runs locally on data you supply and makes no network requests.
Scripts in `data-raw/` download public data over HTTPS and are not part of
the installed package. Reading untrusted raster or vector files goes
through GDAL via terra. Report GDAL parsing issues to those projects.

## Supported versions

Only the latest release receives fixes.
