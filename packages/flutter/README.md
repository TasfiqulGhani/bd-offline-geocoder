# bd_offline_geocoder

[![pub package](https://img.shields.io/pub/v/bd_offline_geocoder.svg)](https://pub.dev/packages/bd_offline_geocoder)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/TasfiqulGhani/bd-offline-geocoder/blob/main/LICENSE)

**Offline Bangladesh reverse geocoder for Flutter.**

GPS → Bangladesh address parts: house, road, area/village, union/ward, thana/upazila, district, division, postal code, city.

No API key. No network. Same data as [Python](https://pypi.org/project/bd-offline-geocoder/) and [npm](https://www.npmjs.com/package/bd-offline-geocoder).

Keywords: Bangladesh geocoder, Flutter offline location, GPS to upazila, ward, thana, Dhaka street.

```dart
final geocoder = await BdOfflineGeocoder.fromBundledAssets();
final result = geocoder.reverse(latitude: 23.74015, longitude: 90.38286);
print(result.formatted);
// House 3, Road 3, Dhanmondi, Ward No-49, Dhanmondi Thana, Dhaka 1209, Bangladesh
print(result.toJson());
```

## Features

- Offline after install — no Maps SDK
- Bundled ADM1–ADM4 GeoJSON
- Dhaka named roads + house-number points (OSM)
- `Polygon` / `MultiPolygon` with holes
- Bounding-box filter, then ray-casting
- `fromBundledAssets()` loads layers in parallel
- Web-safe: `fromFile` is stubbed; use assets or `fromString`

## Install

```yaml
dependencies:
  bd_offline_geocoder: ^0.1.1
```

```bash
flutter pub add bd_offline_geocoder
```

Dart 3.4+ · Flutter 3.16+. Archive is large because the full boundary set is included.

Load the geocoder **once** (`initState`, Riverpod, GetIt) and reuse it.

## Usage

```dart
import 'package:bd_offline_geocoder/bd_offline_geocoder.dart';

final geocoder = await BdOfflineGeocoder.fromBundledAssets();
final result = geocoder.reverse(latitude: 23.74015, longitude: 90.38286);

result.houseNumber;   // 3
result.roadNumber;    // 3
result.roadName;
result.areaVillage;   // Dhanmondi
result.unionWard;     // Ward No-49
result.thanaUpazila;  // Dhanmondi Thana
result.district;      // Dhaka
result.division;      // Dhaka
result.postalCode;    // 1209
result.city;          // Dhaka
result.toJson();
```

Outside Bangladesh: `found == false` and  
`This geocoder only supports locations inside Bangladesh.`

## Dart CLI / files

```dart
final divisions = await GeoJsonBoundarySource.fromFile(
  'assets/boundaries/bgd_admin1.geojson',
  id: 'divisions',
  type: GeocoderLayerType.division,
  namePropertyCandidates: ['adm1_name'],
);
final geocoder = BdOfflineGeocoder(layers: [divisions]);
```

On web, `fromFile` throws. Use `fromBundledAssets()` or `fromString`.

## Example app

https://github.com/TasfiqulGhani/bd-offline-geocoder/tree/main/examples/flutter_app

```bash
cd examples/flutter_app && flutter pub get && flutter run
```

## Limits

- Nationwide: administrative polygons (ADM4 simplified).
- Road / house: central Dhaka OSM only; house numbers are sparse.

## Links

| | |
|--|--|
| Source | https://github.com/TasfiqulGhani/bd-offline-geocoder |
| Architecture | https://github.com/TasfiqulGhani/bd-offline-geocoder/blob/main/docs/ARCHITECTURE.md |
| Python | https://pypi.org/project/bd-offline-geocoder/ |
| npm | https://www.npmjs.com/package/bd-offline-geocoder |

Author: [Tasfiqul Ghani](https://github.com/TasfiqulGhani). MIT code; see [notices](https://github.com/TasfiqulGhani/bd-offline-geocoder/blob/main/THIRD_PARTY_NOTICES.md).
