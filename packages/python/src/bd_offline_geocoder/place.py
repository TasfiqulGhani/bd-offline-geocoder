"""Locality and postal-code helpers from OSM city tags + unique thana codes."""

from __future__ import annotations

import json
import re
from functools import lru_cache
from importlib import resources
_SKIP = frozenset(
    {
        "bangladesh",
        "dhaka",
        "dhaka city",
        "dhaka city corporation",
        "dhaka north city corporation",
        "dhaka south city corporation",
    }
)
_SPLIT = re.compile(r"[,/|]")


def normalize_place_name(value: str) -> str:
    cleaned = " ".join(value.strip().casefold().split())
    if "(" in cleaned:
        cleaned = cleaned.split("(", 1)[0].strip()
    return cleaned


def locality_from_city(city: str | None, *skip_names: str | None) -> str | None:
    if not isinstance(city, str) or not city.strip():
        return None
    skip = set(_SKIP)
    for name in skip_names:
        if isinstance(name, str) and name.strip():
            skip.add(normalize_place_name(name))
            skip.add(name.strip().casefold())
    for part in _SPLIT.split(city):
        cleaned = part.strip()
        if not cleaned:
            continue
        if cleaned.casefold() in skip or normalize_place_name(cleaned) in skip:
            continue
        return cleaned
    return None


def lookup_postcode(district: str | None, *names: str | None) -> str | None:
    if not district:
        return None
    table = _postcode_table().get(normalize_place_name(district))
    if not table:
        return None
    for name in names:
        if not isinstance(name, str) or not name.strip():
            continue
        folded = name.strip().casefold()
        if folded.startswith("ward") or "city corporation" in folded:
            continue
        key = normalize_place_name(name)
        if key in _SKIP:
            continue
        code = table.get(key)
        if code:
            return code
    return None


def postcode_candidates(
    locality: str | None,
    city: str | None,
    union: str | None,
    upazila: str | None,
) -> list[str]:
    names: list[str] = []
    for value in (locality, city, union, upazila):
        if isinstance(value, str) and value.strip():
            names.append(value.strip())
            for part in _SPLIT.split(value):
                cleaned = part.strip()
                if cleaned and cleaned not in names:
                    names.append(cleaned)
    return names


@lru_cache(maxsize=1)
def _postcode_table() -> dict[str, dict[str, str]]:
    path = resources.files("bd_offline_geocoder.data.postcodes").joinpath(
        "unique_area_postcodes.json"
    )
    with path.open("r", encoding="utf-8") as file:
        payload = json.load(file)
    districts = payload.get("districts")
    return districts if isinstance(districts, dict) else {}


_ROAD_PREFIX = re.compile(r"^(?:road|rd)\s*[#:]?\s*(.+)$", re.IGNORECASE)
_NAMED_ROAD_NUMBER = re.compile(
    r"^(.*?\broad)\s+([\d০-৯][\d০-৯/\-]*)$", re.IGNORECASE
)
_NUMERIC_ROAD = re.compile(r"^[\d০-৯][\d০-৯/\-]*$")


def is_city_corporation(name: str | None) -> bool:
    return isinstance(name, str) and "city corporation" in name.casefold()


def split_road(road: str | None) -> tuple[str | None, str | None]:
    """Return ``(road_number, road_name)`` from an OSM street string."""
    if not isinstance(road, str) or not road.strip():
        return None, None
    value = road.strip()
    prefixed = _ROAD_PREFIX.match(value)
    if prefixed:
        return prefixed.group(1).strip(), None
    if _NUMERIC_ROAD.fullmatch(value):
        return value, None
    named = _NAMED_ROAD_NUMBER.match(value)
    if named:
        return named.group(2).strip(), named.group(1).strip()
    return None, value


def thana_upazila_name(upazila: str | None, area_village: str | None) -> str | None:
    if isinstance(upazila, str) and upazila.strip() and not is_city_corporation(upazila):
        return upazila.strip()
    if not isinstance(area_village, str) or not area_village.strip():
        return None
    area = area_village.strip()
    folded = area.casefold()
    if "thana" in folded or "upazila" in folded:
        return area
    return f"{area} Thana"


def city_name(upazila: str | None, district: str | None) -> str | None:
    if is_city_corporation(upazila) and isinstance(district, str) and district.strip():
        return district.strip()
    return None
