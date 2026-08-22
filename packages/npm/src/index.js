import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  cityName,
  localityFromCity,
  lookupPostcode,
  postcodeCandidates,
  splitRoad,
  thanaUpazilaName
} from "./place.js";
import { nearestAddress, nearestRoad } from "./streets.js";

export const LayerType = Object.freeze({
  DIVISION: "division",
  DISTRICT: "district",
  UPAZILA: "upazila",
  UNION: "union",
  LOCALITY: "locality",
  CUSTOM: "custom"
});

export const DEFAULT_NAME_KEYS = Object.freeze([
  "name",
  "NAME",
  "Name",
  "adm1_name",
  "adm2_name",
  "adm3_name",
  "adm4_name",
  "ADM1_EN",
  "ADM2_EN",
  "ADM3_EN",
  "ADM4_EN",
  "shapeName",
  "shapeNameEn"
]);

export const BANGLADESH_ONLY_MESSAGE =
  "This geocoder only supports locations inside Bangladesh.";

const packageRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
let includedGeocoder = null;

export const BoundaryDataPaths = Object.freeze({
  divisions: join(packageRoot, "data/boundaries/bgd_admin1.geojson"),
  districts: join(packageRoot, "data/boundaries/bgd_admin2.geojson"),
  upazilas: join(packageRoot, "data/boundaries/bgd_admin3.geojson"),
  unions: join(packageRoot, "data/boundaries/bgd_admin4_simplified.geojson"),
  dhakaRoads: join(packageRoot, "data/roads/dhaka_named_roads.geojson"),
  dhakaAddresses: join(packageRoot, "data/addresses/dhaka_address_points.geojson")
});

function blank(value) {
  return typeof value === "string" && value.trim() ? value : "";
}

export class AddressResult {
  constructor({
    country,
    houseNumber = null,
    roadNumber = null,
    roadName = null,
    areaVillage = null,
    unionWard = null,
    thanaUpazila = null,
    district = null,
    division = null,
    postalCode = null,
    city = null,
    message = null,
    matchedLayers = {}
  }) {
    this.country = country;
    this.houseNumber = houseNumber;
    this.roadNumber = roadNumber;
    this.roadName = roadName;
    this.areaVillage = areaVillage;
    this.unionWard = unionWard;
    this.thanaUpazila = thanaUpazila;
    this.district = district;
    this.division = division;
    this.postalCode = postalCode;
    this.city = city;
    this.message = message;
    this.matchedLayers = matchedLayers;
  }

  get found() {
    return Object.keys(this.matchedLayers).length > 0;
  }

  get formatted() {
    if (!this.found && this.message) return this.message;

    const roadNumber = this.roadNumber && !this.roadNumber.toLowerCase().startsWith("road")
      ? `Road ${this.roadNumber}`
      : this.roadNumber;
    let place = this.city || this.district;
    if (place && this.postalCode) place = `${place} ${this.postalCode}`;
    else if (this.postalCode) place = this.postalCode;
    let division = this.division;
    const placeBase = this.city || this.district || "";
    if (division && placeBase && division.toLowerCase() === placeBase.toLowerCase()) {
      division = null;
    }
    return formatAddress([
      this.houseNumber ? `House ${this.houseNumber}` : null,
      roadNumber,
      this.roadName,
      this.areaVillage,
      this.unionWard,
      this.thanaUpazila,
      place,
      division,
      this.country
    ]);
  }

  toJSON() {
    const result = {
      house_number: blank(this.houseNumber),
      road_number: blank(this.roadNumber),
      road_name: blank(this.roadName),
      area_village: blank(this.areaVillage),
      union_ward: blank(this.unionWard),
      thana_upazila: blank(this.thanaUpazila),
      district: blank(this.district),
      division: blank(this.division),
      postal_code: blank(this.postalCode),
      city: blank(this.city),
      country: this.country,
      found: this.found,
      formatted: this.formatted,
      matchedLayers: this.matchedLayers
    };
    if (this.message) result.message = this.message;
    return result;
  }
}

export class BoundaryLayer {
  constructor({
    id,
    type,
    features,
    namePropertyCandidates = DEFAULT_NAME_KEYS
  }) {
    this.id = id;
    this.type = type;
    this.features = features;
    this.namePropertyCandidates = namePropertyCandidates;
  }

  static fromFile(path, options) {
    return BoundaryLayer.fromGeoJSON(
      JSON.parse(readFileSync(path, "utf8")),
      options
    );
  }

  static fromGeoJSON(geojson, {
    id,
    type,
    namePropertyCandidates = DEFAULT_NAME_KEYS
  }) {
    const features = (geojson.features ?? [])
      .map(parseFeature)
      .filter((feature) => feature !== null);

    return new BoundaryLayer({
      id,
      type,
      features,
      namePropertyCandidates
    });
  }

  match(latitude, longitude) {
    for (const feature of this.features) {
      if (featureContains(feature, latitude, longitude)) {
        return feature;
      }
    }
    return null;
  }

  displayNameFor(feature) {
    for (const key of this.namePropertyCandidates) {
      const value = feature.properties[key];
      if (typeof value === "string" && value.trim()) {
        return value.trim();
      }
    }
    return null;
  }
}

export class BdOfflineGeocoder {
  constructor({ layers, countryName = "Bangladesh", roadFeatures = [], addressFeatures = [] }) {
    this.layers = Object.freeze([...layers]);
    this.countryName = countryName;
    this.roadFeatures = roadFeatures;
    this.addressFeatures = addressFeatures;
  }

  static fromIncludedData({ reload = false } = {}) {
    if (!includedGeocoder || reload) {
      includedGeocoder = new BdOfflineGeocoder({
        layers: [
          BoundaryLayer.fromFile(BoundaryDataPaths.divisions, {
            id: "divisions",
            type: LayerType.DIVISION,
            namePropertyCandidates: ["adm1_name"]
          }),
          BoundaryLayer.fromFile(BoundaryDataPaths.districts, {
            id: "districts",
            type: LayerType.DISTRICT,
            namePropertyCandidates: ["adm2_name"]
          }),
          BoundaryLayer.fromFile(BoundaryDataPaths.upazilas, {
            id: "upazilas",
            type: LayerType.UPAZILA,
            namePropertyCandidates: ["adm3_name"]
          }),
          BoundaryLayer.fromFile(BoundaryDataPaths.unions, {
            id: "unions",
            type: LayerType.UNION,
            namePropertyCandidates: ["shapeName"]
          })
        ],
        roadFeatures: JSON.parse(readFileSync(BoundaryDataPaths.dhakaRoads, "utf8")).features ?? [],
        addressFeatures: JSON.parse(readFileSync(BoundaryDataPaths.dhakaAddresses, "utf8")).features ?? []
      });
    }
    return includedGeocoder;
  }

  reverse({ latitude, longitude }) {
    validateCoordinate(latitude, longitude);

    let division = null;
    let district = null;
    let upazila = null;
    let union = null;
    let locality = null;
    const matchedLayers = {};

    for (const layer of this.layers) {
      const feature = layer.match(latitude, longitude);
      if (!feature) continue;

      const name = layer.displayNameFor(feature);
      matchedLayers[layer.id] = feature.properties;

      switch (layer.type) {
        case LayerType.DIVISION:
          division = name;
          break;
        case LayerType.DISTRICT:
          district = name;
          break;
        case LayerType.UPAZILA:
          upazila = name;
          break;
        case LayerType.UNION:
          union = name;
          break;
        default:
          locality = name;
          break;
      }
    }

    const addressMatch = nearestAddress(this.addressFeatures, latitude, longitude);
    const roadMatch = nearestRoad(this.roadFeatures, latitude, longitude);
    let road = null;
    let houseNumber = null;
    let city = null;
    if (addressMatch) {
      houseNumber = addressMatch.housenumber;
      road = addressMatch.street;
      const rawCity = addressMatch.properties?.city;
      city = typeof rawCity === "string" && rawCity.trim() ? rawCity.trim() : null;
      if (!locality) {
        locality = localityFromCity(city, district, division, upazila);
      }
      matchedLayers.dhaka_addresses = addressMatch.properties;
    }
    if (roadMatch && !road) road = roadMatch.name;
    if (roadMatch) matchedLayers.dhaka_roads = roadMatch.properties;

    const postalCode = lookupPostcode(
      district,
      ...postcodeCandidates(locality, city, union, upazila)
    );
    const { roadNumber, roadName } = splitRoad(road);

    return new AddressResult({
      country: this.countryName,
      houseNumber,
      roadNumber,
      roadName,
      areaVillage: locality,
      unionWard: union,
      thanaUpazila: thanaUpazilaName(upazila, locality),
      district,
      division,
      postalCode,
      city: cityName(upazila, district),
      message: Object.keys(matchedLayers).length === 0 ? BANGLADESH_ONLY_MESSAGE : null,
      matchedLayers
    });
  }
}

function parseFeature(raw) {
  const geometry = raw.geometry;
  if (!geometry || typeof geometry !== "object") return null;

  const polygons = parseGeometry(geometry);
  if (polygons.length === 0) return null;

  let bounds = polygons[0].bounds;
  for (const polygon of polygons.slice(1)) {
    bounds = expandBounds(bounds, polygon.bounds);
  }

  return {
    properties: raw.properties ?? {},
    polygons,
    bounds
  };
}

function parseGeometry(geometry) {
  if (!Array.isArray(geometry.coordinates)) return [];
  if (geometry.type === "Polygon") {
    return [parsePolygon(geometry.coordinates)];
  }
  if (geometry.type === "MultiPolygon") {
    return geometry.coordinates.map(parsePolygon);
  }
  return [];
}

function parsePolygon(coordinates) {
  const rings = coordinates.map((ring) =>
    ring.map((point) => [Number(point[0]), Number(point[1])])
  );
  let bounds = boundsFromRing(rings[0]);
  for (const ring of rings.slice(1)) {
    bounds = expandBounds(bounds, boundsFromRing(ring));
  }
  return { rings, bounds };
}

function boundsFromRing(ring) {
  let minLatitude = Infinity;
  let minLongitude = Infinity;
  let maxLatitude = -Infinity;
  let maxLongitude = -Infinity;

  for (const [longitude, latitude] of ring) {
    minLatitude = Math.min(minLatitude, latitude);
    maxLatitude = Math.max(maxLatitude, latitude);
    minLongitude = Math.min(minLongitude, longitude);
    maxLongitude = Math.max(maxLongitude, longitude);
  }

  return { minLatitude, minLongitude, maxLatitude, maxLongitude };
}

function expandBounds(a, b) {
  return {
    minLatitude: Math.min(a.minLatitude, b.minLatitude),
    minLongitude: Math.min(a.minLongitude, b.minLongitude),
    maxLatitude: Math.max(a.maxLatitude, b.maxLatitude),
    maxLongitude: Math.max(a.maxLongitude, b.maxLongitude)
  };
}

function boundsContains(bounds, latitude, longitude) {
  return latitude >= bounds.minLatitude &&
    latitude <= bounds.maxLatitude &&
    longitude >= bounds.minLongitude &&
    longitude <= bounds.maxLongitude;
}

function featureContains(feature, latitude, longitude) {
  if (!boundsContains(feature.bounds, latitude, longitude)) return false;
  return feature.polygons.some((polygon) => polygonContains(polygon, latitude, longitude));
}

function polygonContains(polygon, latitude, longitude) {
  if (!boundsContains(polygon.bounds, latitude, longitude) || polygon.rings.length === 0) {
    return false;
  }
  if (!ringContains(polygon.rings[0], latitude, longitude)) return false;
  return !polygon.rings.slice(1).some((hole) => ringContains(hole, latitude, longitude));
}

function ringContains(ring, latitude, longitude) {
  let inside = false;
  let previous = ring.length - 1;

  for (let current = 0; current < ring.length; current += 1) {
    const [currentLongitude, currentLatitude] = ring[current];
    const [previousLongitude, previousLatitude] = ring[previous];

    const intersects = (currentLatitude > latitude) !== (previousLatitude > latitude) &&
      longitude < ((previousLongitude - currentLongitude) *
        (latitude - currentLatitude)) /
        (previousLatitude - currentLatitude) +
        currentLongitude;

    if (intersects) inside = !inside;
    previous = current;
  }

  return inside;
}

function formatAddress(parts) {
  const formatted = [];
  for (const part of parts) {
    if (typeof part !== "string") continue;
    const cleaned = part.trim();
    if (!cleaned) continue;
    if (formatted.length > 0 && formatted[formatted.length - 1].toLowerCase() === cleaned.toLowerCase()) {
      continue;
    }
    formatted.push(cleaned);
  }
  return formatted.join(", ");
}

function validateCoordinate(latitude, longitude) {
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
    throw new RangeError("latitude must be a finite number between -90 and 90");
  }
  if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
    throw new RangeError("longitude must be a finite number between -180 and 180");
  }
}
