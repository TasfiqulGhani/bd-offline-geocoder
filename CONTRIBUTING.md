# Contributing

Thanks for helping improve `bd-offline-geocoder`.

## Layout

- Canonical GeoJSON: `data/boundaries/`
- Implementations: `packages/python`, `packages/npm`, `packages/flutter`
- After changing boundaries, run `sh tools/sync_boundary_data.sh`

Keep the three SDKs aligned: same public method names where the language allows, same test coordinate (`23.771, 90.355`), same outside-Bangladesh message.

## Tests

```sh
cd packages/python && python -m pip install ".[test]" && python -m pytest
cd packages/npm && npm test
cd packages/flutter && flutter pub get && dart analyze && flutter test
```

## Pull requests

1. Add or update tests for the behavior you change.
2. Update package CHANGELOGs if you change a published API.
3. Do not commit `node_modules`, `.venv`, or `build/` artifacts.

## GitHub topics (repo Settings → Topics)

Add these so people can find the repo:

`bangladesh` `geocoder` `reverse-geocoding` `offline` `geojson` `flutter` `python` `typescript` `gis` `dhaka`
