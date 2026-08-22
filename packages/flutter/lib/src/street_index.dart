import 'dart:math';

const metersPerDegLat = 110540.0;
const maxRoadDistanceM = 80.0;
const maxAddressDistanceM = 50.0;

double _metersPerDegLon(double latitude) =>
    111320.0 * cos(latitude * pi / 180);

double pointDistanceM(
  double latitude,
  double longitude,
  double pointLat,
  double pointLon,
) {
  final dx = (pointLon - longitude) * _metersPerDegLon(latitude);
  final dy = (pointLat - latitude) * metersPerDegLat;
  return sqrt(dx * dx + dy * dy);
}

double pointToSegmentM(
  double latitude,
  double longitude,
  double lon1,
  double lat1,
  double lon2,
  double lat2,
) {
  final kx = _metersPerDegLon(latitude);
  final px = longitude * kx;
  final py = latitude * metersPerDegLat;
  final ax = lon1 * kx;
  final ay = lat1 * metersPerDegLat;
  final bx = lon2 * kx;
  final by = lat2 * metersPerDegLat;
  final dx = bx - ax;
  final dy = by - ay;
  if (dx == 0 && dy == 0) {
    return sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay));
  }
  var t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
  t = t.clamp(0.0, 1.0);
  final qx = ax + t * dx;
  final qy = ay + t * dy;
  return sqrt((px - qx) * (px - qx) + (py - qy) * (py - qy));
}

class StreetMatch {
  const StreetMatch({
    required this.name,
    required this.distanceM,
    required this.properties,
  });

  final String name;
  final double distanceM;
  final Map<String, Object?> properties;
}

class AddressMatch {
  const AddressMatch({
    required this.housenumber,
    required this.distanceM,
    required this.properties,
    this.street,
  });

  final String housenumber;
  final String? street;
  final double distanceM;
  final Map<String, Object?> properties;
}

StreetMatch? nearestRoad(
  List<Map<String, Object?>> features,
  double latitude,
  double longitude,
) {
  StreetMatch? best;
  for (final feature in features) {
    final geometry = feature['geometry'] as Map<String, Object?>?;
    final coords = geometry?['coordinates'] as List<Object?>? ?? const [];
    if (geometry?['type'] != 'LineString' || coords.length < 2) continue;
    final properties = (feature['properties'] as Map<String, Object?>?) ?? {};
    final name = properties['name'];
    if (name is! String || name.trim().isEmpty) continue;
    for (var i = 0; i < coords.length - 1; i++) {
      final start = coords[i] as List<Object?>;
      final end = coords[i + 1] as List<Object?>;
      final distance = pointToSegmentM(
        latitude,
        longitude,
        (start[0] as num).toDouble(),
        (start[1] as num).toDouble(),
        (end[0] as num).toDouble(),
        (end[1] as num).toDouble(),
      );
      if (distance > maxRoadDistanceM) continue;
      if (best == null || distance < best.distanceM) {
        best = StreetMatch(
          name: name.trim(),
          distanceM: distance,
          properties: properties,
        );
      }
    }
  }
  return best;
}

AddressMatch? nearestAddress(
  List<Map<String, Object?>> features,
  double latitude,
  double longitude,
) {
  AddressMatch? best;
  for (final feature in features) {
    final geometry = feature['geometry'] as Map<String, Object?>?;
    final coords = geometry?['coordinates'] as List<Object?>? ?? const [];
    if (geometry?['type'] != 'Point' || coords.length < 2) continue;
    final properties = (feature['properties'] as Map<String, Object?>?) ?? {};
    final number = properties['housenumber'];
    if (number is! String || number.trim().isEmpty) continue;
    final distance = pointDistanceM(
      latitude,
      longitude,
      (coords[1] as num).toDouble(),
      (coords[0] as num).toDouble(),
    );
    if (distance > maxAddressDistanceM) continue;
    if (best == null || distance < best.distanceM) {
      final street = properties['street'];
      best = AddressMatch(
        housenumber: number.trim(),
        street: street is String && street.trim().isNotEmpty ? street.trim() : null,
        distanceM: distance,
        properties: properties,
      );
    }
  }
  return best;
}
