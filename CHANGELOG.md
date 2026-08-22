# Changelog

## 0.1.2

- Switch the public result to a Bangladesh address schema: `house_number`, `road_number`, `road_name`, `area_village`, `union_ward`, `thana_upazila`, `district`, `division`, `postal_code`, `city`.
- Use OSM `addr:city` as `area_village` and `{area} Thana` inside city corporations when OSM has a neighborhood.
- Add `postal_code` when the district + area has exactly one Bangladesh Post thana code.

## 0.1.1

- Cache bundled GeoJSON after the first load in Python and Node.
- Add `BdOfflineGeocoder.fromBundledAssets()` for Flutter.
- Deduplicate consecutive names in formatted addresses.
- Reject NaN and non-finite coordinates.
- Make `fromFile` web-safe with a conditional `dart:io` stub.
- Add GitHub Actions CI for all three packages.
- Rewrite repository and package READMEs.

## 0.1.0

- Initial monorepo: Flutter, npm, and PyPI packages with shared ADM1–ADM4 data.
