# Third-Party Notices

This repository includes Bangladesh administrative boundary data from:

https://github.com/meetshaks/bangladesh-administrative-boundaries-json

The source repository documents:

- ADM1-ADM3 boundary files as derived from HDX/OCHA COD-AB Bangladesh data.
- ADM4 simplified boundaries as derived from geoBoundaries.

Canonical data files:

- `data/boundaries/bgd_admin1.geojson`
- `data/boundaries/bgd_admin2.geojson`
- `data/boundaries/bgd_admin3.geojson`
- `data/boundaries/bgd_admin4_simplified.geojson`

Dhaka street names and house numbers are extracted from OpenStreetMap
and are © OpenStreetMap contributors, available under the ODbL.

Unique thana postcodes in `data/postcodes/` are derived from the public
Bangladesh Post Office code list via
[tlstanjim/bangladesh-postal-codes-database](https://github.com/tlstanjim/bangladesh-postal-codes-database).
Ambiguous thanas (more than one code) are omitted.

The package code is MIT licensed. Boundary and OSM data may have separate
attribution and share-alike terms. Keep attribution visible if you ship an app
that includes these assets.
