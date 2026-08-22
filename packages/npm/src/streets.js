const METERS_PER_DEG_LAT = 110540;
export const MAX_ROAD_DISTANCE_M = 80;
export const MAX_ADDRESS_DISTANCE_M = 50;

function metersPerDegLon(latitude) {
  return 111320 * Math.cos((latitude * Math.PI) / 180);
}

export function pointDistanceM(latitude, longitude, pointLat, pointLon) {
  const dx = (pointLon - longitude) * metersPerDegLon(latitude);
  const dy = (pointLat - latitude) * METERS_PER_DEG_LAT;
  return Math.hypot(dx, dy);
}

export function pointToSegmentM(latitude, longitude, lon1, lat1, lon2, lat2) {
  const kx = metersPerDegLon(latitude);
  const px = longitude * kx;
  const py = latitude * METERS_PER_DEG_LAT;
  const ax = lon1 * kx;
  const ay = lat1 * METERS_PER_DEG_LAT;
  const bx = lon2 * kx;
  const by = lat2 * METERS_PER_DEG_LAT;
  const dx = bx - ax;
  const dy = by - ay;
  if (dx === 0 && dy === 0) return Math.hypot(px - ax, py - ay);
  const t = Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)));
  return Math.hypot(px - (ax + t * dx), py - (ay + t * dy));
}

export function nearestRoad(features, latitude, longitude) {
  let best = null;
  for (const feature of features) {
    const geometry = feature.geometry ?? {};
    const coords = geometry.coordinates ?? [];
    if (geometry.type !== "LineString" || coords.length < 2) continue;
    const name = feature.properties?.name;
    if (typeof name !== "string" || !name.trim()) continue;
    for (let i = 0; i < coords.length - 1; i += 1) {
      const distance = pointToSegmentM(
        latitude,
        longitude,
        coords[i][0],
        coords[i][1],
        coords[i + 1][0],
        coords[i + 1][1]
      );
      if (distance > MAX_ROAD_DISTANCE_M) continue;
      if (!best || distance < best.distanceM) {
        best = { name: name.trim(), distanceM: distance, properties: feature.properties ?? {} };
      }
    }
  }
  return best;
}

export function nearestAddress(features, latitude, longitude) {
  let best = null;
  for (const feature of features) {
    const geometry = feature.geometry ?? {};
    const coords = geometry.coordinates ?? [];
    if (geometry.type !== "Point" || coords.length < 2) continue;
    const number = feature.properties?.housenumber;
    if (typeof number !== "string" || !number.trim()) continue;
    const distance = pointDistanceM(latitude, longitude, coords[1], coords[0]);
    if (distance > MAX_ADDRESS_DISTANCE_M) continue;
    if (!best || distance < best.distanceM) {
      const street = feature.properties?.street;
      best = {
        housenumber: number.trim(),
        street: typeof street === "string" && street.trim() ? street.trim() : null,
        distanceM: distance,
        properties: feature.properties ?? {}
      };
    }
  }
  return best;
}
