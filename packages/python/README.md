# bd-offline-geocoder

[![PyPI](https://img.shields.io/pypi/v/bd-offline-geocoder.svg)](https://pypi.org/project/bd-offline-geocoder/)
[![Python](https://img.shields.io/pypi/pyversions/bd-offline-geocoder.svg)](https://pypi.org/project/bd-offline-geocoder/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/TasfiqulGhani/bd-offline-geocoder/blob/main/LICENSE)

**Offline Bangladesh reverse geocoder for Python.**

GPS → Bangladesh address parts: house, road, area/village, union/ward, thana/upazila, district, division, postal code, city.

No API key. No network. Same data as [npm](https://www.npmjs.com/package/bd-offline-geocoder) and [Flutter](https://pub.dev/packages/bd_offline_geocoder).

Keywords: Bangladesh reverse geocoder, offline geocoding, upazila, thana, ward, Dhaka street, GIS Python.

```python
from bd_offline_geocoder import BdOfflineGeocoder

geocoder = BdOfflineGeocoder.from_included_data()
result = geocoder.reverse(latitude=23.74015, longitude=90.38286)
print(result.formatted)
# House 3, Road 3, Dhanmondi, Ward No-49, Dhanmondi Thana, Dhaka 1209, Bangladesh
print(result.to_dict())
# {
#   "house_number": "3",
#   "road_number": "3",
#   "road_name": "",
#   "area_village": "Dhanmondi",
#   "union_ward": "Ward No-49",
#   "thana_upazila": "Dhanmondi Thana",
#   "district": "Dhaka",
#   "division": "Dhaka",
#   "postal_code": "1209",
#   "city": "Dhaka"
# }
```

## Install

```bash
pip install bd-offline-geocoder
```

Python **3.9+**. Zero runtime dependencies.

`from_included_data()` parses bundled GeoJSON once and **caches** the instance. Reuse it in Celery workers, FastAPI lifespan, or Gunicorn preload.

Published wheel is large (~admin polygons + Dhaka streets) because the feature is offline.

## Usage

```python
result = geocoder.reverse(latitude=23.74015, longitude=90.38286)
result.house_number   # 3
result.road_number    # 3
result.road_name      # None unless OSM has a named street
result.area_village   # Dhanmondi
result.union_ward     # Ward No-49
result.thana_upazila  # Dhanmondi Thana
result.district       # Dhaka
result.division       # Dhaka
result.postal_code    # 1209
result.city           # Dhaka
result.formatted
result.to_dict()
```

Outside Bangladesh: `found is False` and `formatted` is  
`This geocoder only supports locations inside Bangladesh.`

Invalid / NaN coordinates raise `ValueError`.

## Custom layers

```python
from bd_offline_geocoder import BdOfflineGeocoder, BoundaryLayer, LayerType

layer = BoundaryLayer.from_file(
    "my_localities.geojson",
    id="localities",
    type=LayerType.LOCALITY,
    name_property_candidates=("name", "NAME"),
)
geocoder = BdOfflineGeocoder([layer])
```

## Limits

- Nationwide: administrative polygons only (ADM4 is simplified).
- Roads / house numbers: **central Dhaka OSM only**; house numbers are sparse.
- Not a Google Maps replacement for every rooftop.

## Links

| | |
|--|--|
| Source | https://github.com/TasfiqulGhani/bd-offline-geocoder |
| Architecture | https://github.com/TasfiqulGhani/bd-offline-geocoder/blob/main/docs/ARCHITECTURE.md |
| Flutter | https://pub.dev/packages/bd_offline_geocoder |
| npm | https://www.npmjs.com/package/bd-offline-geocoder |

Author: [Tasfiqul Ghani](https://github.com/TasfiqulGhani). MIT code; see [notices](https://github.com/TasfiqulGhani/bd-offline-geocoder/blob/main/THIRD_PARTY_NOTICES.md) for HDX / OSM.
