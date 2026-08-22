# bd-offline-geocoder

[![npm](https://img.shields.io/npm/v/bd-offline-geocoder.svg)](https://www.npmjs.com/package/bd-offline-geocoder)
[![Node](https://img.shields.io/node/v/bd-offline-geocoder.svg)](https://www.npmjs.com/package/bd-offline-geocoder)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/TasfiqulGhani/bd-offline-geocoder/blob/main/LICENSE)

**Offline Bangladesh reverse geocoder for Node.js and TypeScript.**

GPS → Bangladesh address parts: house, road, area/village, union/ward, thana/upazila, district, division, postal code, city.

No API key. No network. Same data as [Python](https://pypi.org/project/bd-offline-geocoder/) and [Flutter](https://pub.dev/packages/bd_offline_geocoder).

Keywords: Bangladesh reverse geocoder, offline geocoding, upazila, thana, ward, Dhaka street, Node GIS.

```ts
import { BdOfflineGeocoder } from "bd-offline-geocoder";

const geocoder = BdOfflineGeocoder.fromIncludedData();
const result = geocoder.reverse({ latitude: 23.74015, longitude: 90.38286 });
console.log(result.formatted);
// House 3, Road 3, Dhanmondi, Ward No-49, Dhanmondi Thana, Dhaka 1209, Bangladesh
console.log(result.toJSON());
```

## Install

```bash
npm install bd-offline-geocoder
```

**Node.js 18+**. No runtime dependencies.

Call `fromIncludedData()` **once** at process start (Express, Nest, Next.js Route Handlers). Do not parse the GeoJSON on every request.

Keep the token off the browser. Resolve GPS on the server, return `formatted` to the client.

Tarball is ~29 MB+ because admin polygons and Dhaka OSM streets ship with the module.

## Usage

```ts
result.houseNumber;   // 3
result.roadNumber;    // 3
result.roadName;      // named street, if OSM has one
result.areaVillage;   // Dhanmondi
result.unionWard;     // Ward No-49
result.thanaUpazila;  // Dhanmondi Thana
result.district;      // Dhaka
result.division;      // Dhaka
result.postalCode;    // 1209
result.city;          // Dhaka
result.toJSON();
```

Outside Bangladesh: `found === false` and the Bangladesh-only message.

Invalid / `NaN` coordinates throw `RangeError`.

## Custom layers

```js
import { BdOfflineGeocoder, BoundaryLayer, LayerType } from "bd-offline-geocoder";

const localities = BoundaryLayer.fromFile("./localities.geojson", {
  id: "localities",
  type: LayerType.LOCALITY,
  namePropertyCandidates: ["name"]
});
const geocoder = new BdOfflineGeocoder({ layers: [localities] });
```

## Limits

- Nationwide: administrative polygons (ADM4 simplified).
- Roads / house numbers: central Dhaka OSM only.
- Not street-complete for every building.

## Links

| | |
|--|--|
| Source | https://github.com/TasfiqulGhani/bd-offline-geocoder |
| Architecture | https://github.com/TasfiqulGhani/bd-offline-geocoder/blob/main/docs/ARCHITECTURE.md |
| Python | https://pypi.org/project/bd-offline-geocoder/ |
| Flutter | https://pub.dev/packages/bd_offline_geocoder |

Author: [Tasfiqul Ghani](https://github.com/TasfiqulGhani). MIT code; OSM / HDX attribution in [notices](https://github.com/TasfiqulGhani/bd-offline-geocoder/blob/main/THIRD_PARTY_NOTICES.md).
