# Changelog

## 0.1.2

- Switch `AddressResult` to the Bangladesh address schema (`houseNumber`, `roadNumber`, `areaVillage`, `unionWard`, `thanaUpazila`, `city`, …).
- Declare `license: MIT` in `pubspec.yaml` and use a standard `LICENSE` file for pub.dev scoring.

## 0.1.1

- Add `BdOfflineGeocoder.fromBundledAssets()`.
- Deduplicate consecutive names in `formatted`.
- Reject NaN and non-finite coordinates.
- Keep `fromFile` off the web compiler via conditional imports.

## 0.1.0

- Initial public release with bundled ADM1–ADM4 assets.
