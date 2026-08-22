#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/data/boundaries"
FLUTTER_DIR="$ROOT_DIR/packages/flutter/assets/boundaries"
PYTHON_DIR="$ROOT_DIR/packages/python/src/bd_offline_geocoder/data/boundaries"
NPM_DIR="$ROOT_DIR/packages/npm/data/boundaries"

mkdir -p "$FLUTTER_DIR"
mkdir -p "$PYTHON_DIR"
mkdir -p "$NPM_DIR"

cp "$SOURCE_DIR/bgd_admin1.geojson" "$FLUTTER_DIR/bgd_admin1.geojson"
cp "$SOURCE_DIR/bgd_admin2.geojson" "$FLUTTER_DIR/bgd_admin2.geojson"
cp "$SOURCE_DIR/bgd_admin3.geojson" "$FLUTTER_DIR/bgd_admin3.geojson"
cp "$SOURCE_DIR/bgd_admin4_simplified.geojson" "$FLUTTER_DIR/bgd_admin4_simplified.geojson"

cp "$SOURCE_DIR/bgd_admin1.geojson" "$PYTHON_DIR/bgd_admin1.geojson"
cp "$SOURCE_DIR/bgd_admin2.geojson" "$PYTHON_DIR/bgd_admin2.geojson"
cp "$SOURCE_DIR/bgd_admin3.geojson" "$PYTHON_DIR/bgd_admin3.geojson"
cp "$SOURCE_DIR/bgd_admin4_simplified.geojson" "$PYTHON_DIR/bgd_admin4_simplified.geojson"

cp "$SOURCE_DIR/bgd_admin1.geojson" "$NPM_DIR/bgd_admin1.geojson"
cp "$SOURCE_DIR/bgd_admin2.geojson" "$NPM_DIR/bgd_admin2.geojson"
cp "$SOURCE_DIR/bgd_admin3.geojson" "$NPM_DIR/bgd_admin3.geojson"
cp "$SOURCE_DIR/bgd_admin4_simplified.geojson" "$NPM_DIR/bgd_admin4_simplified.geojson"

mkdir -p "$ROOT_DIR/packages/flutter/assets/roads" \
         "$ROOT_DIR/packages/flutter/assets/addresses" \
         "$ROOT_DIR/packages/python/src/bd_offline_geocoder/data/roads" \
         "$ROOT_DIR/packages/python/src/bd_offline_geocoder/data/addresses" \
         "$ROOT_DIR/packages/python/src/bd_offline_geocoder/data/postcodes" \
         "$ROOT_DIR/packages/npm/data/roads" \
         "$ROOT_DIR/packages/npm/data/addresses" \
         "$ROOT_DIR/packages/npm/data/postcodes"

cp "$ROOT_DIR/data/roads/dhaka_named_roads.geojson" "$ROOT_DIR/packages/flutter/assets/roads/"
cp "$ROOT_DIR/data/addresses/dhaka_address_points.geojson" "$ROOT_DIR/packages/flutter/assets/addresses/"
cp "$ROOT_DIR/data/roads/dhaka_named_roads.geojson" "$ROOT_DIR/packages/python/src/bd_offline_geocoder/data/roads/"
cp "$ROOT_DIR/data/addresses/dhaka_address_points.geojson" "$ROOT_DIR/packages/python/src/bd_offline_geocoder/data/addresses/"
cp "$ROOT_DIR/data/postcodes/unique_area_postcodes.json" "$ROOT_DIR/packages/python/src/bd_offline_geocoder/data/postcodes/"
cp "$ROOT_DIR/data/roads/dhaka_named_roads.geojson" "$ROOT_DIR/packages/npm/data/roads/"
cp "$ROOT_DIR/data/addresses/dhaka_address_points.geojson" "$ROOT_DIR/packages/npm/data/addresses/"
cp "$ROOT_DIR/data/postcodes/unique_area_postcodes.json" "$ROOT_DIR/packages/npm/data/postcodes/"

echo "Synced boundary data into package asset directories"
