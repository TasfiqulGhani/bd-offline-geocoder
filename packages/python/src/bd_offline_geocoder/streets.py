"""Nearest named road and house-number lookup for Dhaka OSM extracts."""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Any

METERS_PER_DEG_LAT = 110540.0
MAX_ROAD_DISTANCE_M = 80.0
MAX_ADDRESS_DISTANCE_M = 50.0


def _meters_per_deg_lon(latitude: float) -> float:
    return 111320.0 * math.cos(math.radians(latitude))


def _point_distance_m(
    latitude: float, longitude: float, point_lat: float, point_lon: float
) -> float:
    dx = (point_lon - longitude) * _meters_per_deg_lon(latitude)
    dy = (point_lat - latitude) * METERS_PER_DEG_LAT
    return math.hypot(dx, dy)


def _point_to_segment_m(
    latitude: float,
    longitude: float,
    lon1: float,
    lat1: float,
    lon2: float,
    lat2: float,
) -> float:
    kx = _meters_per_deg_lon(latitude)
    px, py = longitude * kx, latitude * METERS_PER_DEG_LAT
    ax, ay = lon1 * kx, lat1 * METERS_PER_DEG_LAT
    bx, by = lon2 * kx, lat2 * METERS_PER_DEG_LAT
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay)
    t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


@dataclass(frozen=True)
class StreetMatch:
    name: str
    distance_m: float
    properties: dict[str, Any]


@dataclass(frozen=True)
class AddressMatch:
    housenumber: str
    street: str | None
    distance_m: float
    properties: dict[str, Any]


class RoadIndex:
    def __init__(self, features: list[dict[str, Any]]):
        self._features = features

    @classmethod
    def from_geojson(cls, geojson: dict[str, Any]) -> "RoadIndex":
        return cls([f for f in geojson.get("features", []) if f.get("geometry")])

    @classmethod
    def from_file(cls, path: str | Path) -> "RoadIndex":
        with Path(path).open("r", encoding="utf-8") as file:
            return cls.from_geojson(json.load(file))

    def nearest(self, latitude: float, longitude: float) -> StreetMatch | None:
        best: StreetMatch | None = None
        for feature in self._features:
            geometry = feature.get("geometry") or {}
            coords = geometry.get("coordinates") or []
            if geometry.get("type") != "LineString" or len(coords) < 2:
                continue
            name = (feature.get("properties") or {}).get("name")
            if not isinstance(name, str) or not name.strip():
                continue
            for start, end in zip(coords, coords[1:]):
                distance = _point_to_segment_m(
                    latitude, longitude, start[0], start[1], end[0], end[1]
                )
                if distance > MAX_ROAD_DISTANCE_M:
                    continue
                if best is None or distance < best.distance_m:
                    best = StreetMatch(name.strip(), distance, feature.get("properties") or {})
        return best


class AddressIndex:
    def __init__(self, features: list[dict[str, Any]]):
        self._features = features

    @classmethod
    def from_geojson(cls, geojson: dict[str, Any]) -> "AddressIndex":
        return cls([f for f in geojson.get("features", []) if f.get("geometry")])

    @classmethod
    def from_file(cls, path: str | Path) -> "AddressIndex":
        with Path(path).open("r", encoding="utf-8") as file:
            return cls.from_geojson(json.load(file))

    def nearest(self, latitude: float, longitude: float) -> AddressMatch | None:
        best: AddressMatch | None = None
        for feature in self._features:
            geometry = feature.get("geometry") or {}
            coords = geometry.get("coordinates") or []
            if geometry.get("type") != "Point" or len(coords) < 2:
                continue
            props = feature.get("properties") or {}
            number = props.get("housenumber")
            if not isinstance(number, str) or not number.strip():
                continue
            distance = _point_distance_m(latitude, longitude, coords[1], coords[0])
            if distance > MAX_ADDRESS_DISTANCE_M:
                continue
            if best is None or distance < best.distance_m:
                street = props.get("street")
                best = AddressMatch(
                    number.strip(),
                    street.strip() if isinstance(street, str) and street.strip() else None,
                    distance,
                    props,
                )
        return best
