from __future__ import annotations

import json
import math
from dataclasses import dataclass, field
from enum import Enum
from importlib import resources
from pathlib import Path
from typing import Any, Iterable

from bd_offline_geocoder.place import (
    city_name,
    locality_from_city,
    lookup_postcode,
    postcode_candidates,
    split_road,
    thana_upazila_name,
)
from bd_offline_geocoder.streets import AddressIndex, RoadIndex


class LayerType(str, Enum):
    DIVISION = "division"
    DISTRICT = "district"
    UPAZILA = "upazila"
    UNION = "union"
    LOCALITY = "locality"
    CUSTOM = "custom"


DEFAULT_NAME_KEYS = (
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
    "shapeNameEn",
)

BANGLADESH_ONLY_MESSAGE = "This geocoder only supports locations inside Bangladesh."


def _blank(value: str | None) -> str:
    return value if isinstance(value, str) and value.strip() else ""


@dataclass(frozen=True)
class AddressResult:
    country: str
    house_number: str | None = None
    road_number: str | None = None
    road_name: str | None = None
    area_village: str | None = None
    union_ward: str | None = None
    thana_upazila: str | None = None
    district: str | None = None
    division: str | None = None
    postal_code: str | None = None
    city: str | None = None
    message: str | None = None
    matched_layers: dict[str, dict[str, Any]] = field(default_factory=dict)

    @property
    def found(self) -> bool:
        return bool(self.matched_layers)

    @property
    def formatted(self) -> str:
        if not self.found and self.message:
            return self.message

        house = f"House {self.house_number}" if self.house_number else None
        road_number = (
            f"Road {self.road_number}"
            if self.road_number and not self.road_number.casefold().startswith("road")
            else self.road_number
        )
        place = self.city or self.district
        if place and self.postal_code:
            place = f"{place} {self.postal_code}"
        elif self.postal_code:
            place = self.postal_code
        division = self.division
        if division and place and division.casefold() == (self.city or self.district or "").casefold():
            division = None
        return _format_address(
            [
                house,
                road_number,
                self.road_name,
                self.area_village,
                self.union_ward,
                self.thana_upazila,
                place,
                division,
                self.country,
            ]
        )

    def to_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {
            "house_number": _blank(self.house_number),
            "road_number": _blank(self.road_number),
            "road_name": _blank(self.road_name),
            "area_village": _blank(self.area_village),
            "union_ward": _blank(self.union_ward),
            "thana_upazila": _blank(self.thana_upazila),
            "district": _blank(self.district),
            "division": _blank(self.division),
            "postal_code": _blank(self.postal_code),
            "city": _blank(self.city),
            "country": self.country,
            "found": self.found,
            "formatted": self.formatted,
            "matched_layers": self.matched_layers,
        }
        if self.message:
            result["message"] = self.message
        return result


@dataclass(frozen=True)
class _Bounds:
    min_latitude: float
    min_longitude: float
    max_latitude: float
    max_longitude: float

    def contains(self, latitude: float, longitude: float) -> bool:
        return (
            self.min_latitude <= latitude <= self.max_latitude
            and self.min_longitude <= longitude <= self.max_longitude
        )

    @classmethod
    def from_ring(cls, ring: list[list[float]]) -> "_Bounds":
        longitudes = [point[0] for point in ring]
        latitudes = [point[1] for point in ring]
        return cls(min(latitudes), min(longitudes), max(latitudes), max(longitudes))

    def expand(self, other: "_Bounds") -> "_Bounds":
        return _Bounds(
            min(self.min_latitude, other.min_latitude),
            min(self.min_longitude, other.min_longitude),
            max(self.max_latitude, other.max_latitude),
            max(self.max_longitude, other.max_longitude),
        )


@dataclass(frozen=True)
class _Polygon:
    rings: list[list[list[float]]]
    bounds: _Bounds

    def contains(self, latitude: float, longitude: float) -> bool:
        if not self.bounds.contains(latitude, longitude) or not self.rings:
            return False
        if not _ring_contains(self.rings[0], latitude, longitude):
            return False
        return not any(_ring_contains(hole, latitude, longitude) for hole in self.rings[1:])


@dataclass(frozen=True)
class _Feature:
    properties: dict[str, Any]
    polygons: list[_Polygon]
    bounds: _Bounds

    def contains(self, latitude: float, longitude: float) -> bool:
        if not self.bounds.contains(latitude, longitude):
            return False
        return any(polygon.contains(latitude, longitude) for polygon in self.polygons)


@dataclass(frozen=True)
class BoundaryLayer:
    id: str
    type: LayerType
    features: list[_Feature]
    name_property_candidates: tuple[str, ...] = DEFAULT_NAME_KEYS

    @classmethod
    def from_file(
        cls,
        path: str | Path,
        *,
        id: str,
        type: LayerType,
        name_property_candidates: tuple[str, ...] = DEFAULT_NAME_KEYS,
    ) -> "BoundaryLayer":
        with Path(path).open("r", encoding="utf-8") as file:
            return cls.from_geojson(
                json.load(file),
                id=id,
                type=type,
                name_property_candidates=name_property_candidates,
            )

    @classmethod
    def from_geojson(
        cls,
        geojson: dict[str, Any],
        *,
        id: str,
        type: LayerType,
        name_property_candidates: tuple[str, ...] = DEFAULT_NAME_KEYS,
    ) -> "BoundaryLayer":
        features = [
            feature
            for raw in geojson.get("features", [])
            if (feature := _parse_feature(raw)) is not None
        ]
        return cls(id, type, features, name_property_candidates)

    def match(self, latitude: float, longitude: float) -> _Feature | None:
        for feature in self.features:
            if feature.contains(latitude, longitude):
                return feature
        return None

    def display_name_for(self, feature: _Feature) -> str | None:
        for key in self.name_property_candidates:
            value = feature.properties.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
        return None


_INCLUDED_GEOCODER: BdOfflineGeocoder | None = None


class BdOfflineGeocoder:
    """Offline reverse geocoder for Bangladesh administrative boundaries."""

    def __init__(
        self,
        layers: list[BoundaryLayer],
        country_name: str = "Bangladesh",
        road_index: RoadIndex | None = None,
        address_index: AddressIndex | None = None,
    ):
        self.layers = tuple(layers)
        self.country_name = country_name
        self.road_index = road_index
        self.address_index = address_index

    @classmethod
    def from_included_data(cls, *, reload: bool = False) -> "BdOfflineGeocoder":
        """Load bundled ADM1-ADM4 layers plus Dhaka street/address indexes."""
        global _INCLUDED_GEOCODER
        if _INCLUDED_GEOCODER is None or reload:
            _INCLUDED_GEOCODER = cls(
                [
                    _included_layer(
                        "bgd_admin1.geojson", "divisions", LayerType.DIVISION, ("adm1_name",)
                    ),
                    _included_layer(
                        "bgd_admin2.geojson", "districts", LayerType.DISTRICT, ("adm2_name",)
                    ),
                    _included_layer(
                        "bgd_admin3.geojson", "upazilas", LayerType.UPAZILA, ("adm3_name",)
                    ),
                    _included_layer(
                        "bgd_admin4_simplified.geojson",
                        "unions",
                        LayerType.UNION,
                        ("shapeName",),
                    ),
                ],
                road_index=RoadIndex.from_geojson(
                    _included_json("dhaka_named_roads.geojson", package="bd_offline_geocoder.data.roads")
                ),
                address_index=AddressIndex.from_geojson(
                    _included_json(
                        "dhaka_address_points.geojson",
                        package="bd_offline_geocoder.data.addresses",
                    )
                ),
            )
        return _INCLUDED_GEOCODER

    def reverse(self, *, latitude: float, longitude: float) -> AddressResult:
        _validate_coordinate(latitude, longitude)

        division = district = upazila = union = locality = None
        matched_layers: dict[str, dict[str, Any]] = {}

        for layer in self.layers:
            feature = layer.match(latitude, longitude)
            if feature is None:
                continue

            name = layer.display_name_for(feature)
            matched_layers[layer.id] = feature.properties

            if layer.type == LayerType.DIVISION:
                division = name
            elif layer.type == LayerType.DISTRICT:
                district = name
            elif layer.type == LayerType.UPAZILA:
                upazila = name
            elif layer.type == LayerType.UNION:
                union = name
            else:
                locality = name

        road = house_number = None
        city = None
        address_match = self.address_index.nearest(latitude, longitude) if self.address_index else None
        road_match = self.road_index.nearest(latitude, longitude) if self.road_index else None
        if address_match:
            house_number = address_match.housenumber
            road = address_match.street
            city = address_match.properties.get("city")
            if isinstance(city, str) and city.strip():
                city = city.strip()
            else:
                city = None
            if locality is None:
                locality = locality_from_city(city, district, division, upazila)
            matched_layers["dhaka_addresses"] = address_match.properties
        if road_match and not road:
            road = road_match.name
        if road_match:
            matched_layers["dhaka_roads"] = road_match.properties

        postal_code = lookup_postcode(
            district, *postcode_candidates(locality, city, union, upazila)
        )
        road_number, road_name = split_road(road)

        return AddressResult(
            country=self.country_name,
            house_number=house_number,
            road_number=road_number,
            road_name=road_name,
            area_village=locality,
            union_ward=union,
            thana_upazila=thana_upazila_name(upazila, locality),
            district=district,
            division=division,
            postal_code=postal_code,
            city=city_name(upazila, district),
            message=BANGLADESH_ONLY_MESSAGE if not matched_layers else None,
            matched_layers=matched_layers,
        )


def _included_json(filename: str, *, package: str) -> dict[str, Any]:
    path = resources.files(package).joinpath(filename)
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def _included_layer(
    filename: str,
    layer_id: str,
    layer_type: LayerType,
    name_keys: tuple[str, ...],
) -> BoundaryLayer:
    path = resources.files("bd_offline_geocoder.data.boundaries").joinpath(filename)
    with path.open("r", encoding="utf-8") as file:
        geojson = json.load(file)
    return BoundaryLayer.from_geojson(
        geojson,
        id=layer_id,
        type=layer_type,
        name_property_candidates=name_keys,
    )


def _parse_feature(raw: dict[str, Any]) -> _Feature | None:
    geometry = raw.get("geometry")
    if not isinstance(geometry, dict):
        return None

    polygons = _parse_geometry(geometry)
    if not polygons:
        return None

    bounds = polygons[0].bounds
    for polygon in polygons[1:]:
        bounds = bounds.expand(polygon.bounds)

    properties = raw.get("properties")
    return _Feature(properties if isinstance(properties, dict) else {}, polygons, bounds)


def _parse_geometry(geometry: dict[str, Any]) -> list[_Polygon]:
    geometry_type = geometry.get("type")
    coordinates = geometry.get("coordinates")
    if not isinstance(coordinates, list):
        return []

    if geometry_type == "Polygon":
        return [_parse_polygon(coordinates)]
    if geometry_type == "MultiPolygon":
        return [_parse_polygon(polygon) for polygon in coordinates]
    return []


def _parse_polygon(coordinates: list[Any]) -> _Polygon:
    rings = [
        [[float(point[0]), float(point[1])] for point in ring]
        for ring in coordinates
    ]
    bounds = _Bounds.from_ring(rings[0])
    for ring in rings[1:]:
        bounds = bounds.expand(_Bounds.from_ring(ring))
    return _Polygon(rings, bounds)


def _ring_contains(ring: list[list[float]], latitude: float, longitude: float) -> bool:
    inside = False
    previous = len(ring) - 1

    for current, point in enumerate(ring):
        current_longitude, current_latitude = point
        previous_longitude, previous_latitude = ring[previous]

        if (current_latitude > latitude) != (previous_latitude > latitude):
            crossing_longitude = (
                (previous_longitude - current_longitude)
                * (latitude - current_latitude)
                / (previous_latitude - current_latitude)
                + current_longitude
            )
            if longitude < crossing_longitude:
                inside = not inside
        previous = current

    return inside


def _format_address(parts: Iterable[str | None]) -> str:
    formatted: list[str] = []
    for part in parts:
        if not isinstance(part, str):
            continue
        cleaned = part.strip()
        if not cleaned:
            continue
        if formatted and formatted[-1].casefold() == cleaned.casefold():
            continue
        formatted.append(cleaned)
    return ", ".join(formatted)


def _is_finite_number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def _validate_coordinate(latitude: float, longitude: float) -> None:
    if not _is_finite_number(latitude) or latitude < -90 or latitude > 90:
        raise ValueError("latitude must be a finite number between -90 and 90")
    if not _is_finite_number(longitude) or longitude < -180 or longitude > 180:
        raise ValueError("longitude must be a finite number between -180 and 180")
