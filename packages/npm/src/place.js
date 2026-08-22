import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const SKIP = new Set([
  "bangladesh",
  "dhaka",
  "dhaka city",
  "dhaka city corporation",
  "dhaka north city corporation",
  "dhaka south city corporation"
]);

const packageRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
let postcodeTable = null;

export function normalizePlaceName(value) {
  let cleaned = value.trim().toLowerCase().replace(/\s+/g, " ");
  if (cleaned.includes("(")) {
    cleaned = cleaned.split("(")[0].trim();
  }
  return cleaned;
}

export function localityFromCity(city, ...skipNames) {
  if (typeof city !== "string" || !city.trim()) return null;
  const skip = new Set(SKIP);
  for (const name of skipNames) {
    if (typeof name === "string" && name.trim()) {
      skip.add(normalizePlaceName(name));
      skip.add(name.trim().toLowerCase());
    }
  }
  for (const part of city.split(/[,/|]/)) {
    const cleaned = part.trim();
    if (!cleaned) continue;
    if (skip.has(cleaned.toLowerCase()) || skip.has(normalizePlaceName(cleaned))) {
      continue;
    }
    return cleaned;
  }
  return null;
}

export function lookupPostcode(district, ...names) {
  if (!district) return null;
  const table = loadPostcodeTable()[normalizePlaceName(district)];
  if (!table) return null;
  for (const name of names) {
    if (typeof name !== "string" || !name.trim()) continue;
    const folded = name.trim().toLowerCase();
    if (folded.startsWith("ward") || folded.includes("city corporation")) continue;
    const key = normalizePlaceName(name);
    if (SKIP.has(key)) continue;
    if (table[key]) return table[key];
  }
  return null;
}

export function postcodeCandidates(locality, city, union, upazila) {
  const names = [];
  for (const value of [locality, city, union, upazila]) {
    if (typeof value !== "string" || !value.trim()) continue;
    names.push(value.trim());
    for (const part of value.split(/[,/|]/)) {
      const cleaned = part.trim();
      if (cleaned && !names.includes(cleaned)) names.push(cleaned);
    }
  }
  return names;
}

export function isCityCorporation(name) {
  return typeof name === "string" && name.toLowerCase().includes("city corporation");
}

export function splitRoad(road) {
  if (typeof road !== "string" || !road.trim()) return { roadNumber: null, roadName: null };
  const value = road.trim();
  const prefixed = /^(?:road|rd)\s*[#:]?\s*(.+)$/i.exec(value);
  if (prefixed) return { roadNumber: prefixed[1].trim(), roadName: null };
  if (/^[\d০-৯][\d০-৯/\-]*$/.test(value)) return { roadNumber: value, roadName: null };
  const named = /^(.*?\broad)\s+([\d০-৯][\d০-৯/\-]*)$/i.exec(value);
  if (named) return { roadNumber: named[2].trim(), roadName: named[1].trim() };
  return { roadNumber: null, roadName: value };
}

export function thanaUpazilaName(upazila, areaVillage) {
  if (typeof upazila === "string" && upazila.trim() && !isCityCorporation(upazila)) {
    return upazila.trim();
  }
  if (typeof areaVillage !== "string" || !areaVillage.trim()) return null;
  const area = areaVillage.trim();
  const folded = area.toLowerCase();
  if (folded.includes("thana") || folded.includes("upazila")) return area;
  return `${area} Thana`;
}

export function cityName(upazila, district) {
  if (isCityCorporation(upazila) && typeof district === "string" && district.trim()) {
    return district.trim();
  }
  return null;
}

function loadPostcodeTable() {
  if (!postcodeTable) {
    const payload = JSON.parse(
      readFileSync(join(packageRoot, "data/postcodes/unique_area_postcodes.json"), "utf8")
    );
    postcodeTable = payload.districts ?? {};
  }
  return postcodeTable;
}
