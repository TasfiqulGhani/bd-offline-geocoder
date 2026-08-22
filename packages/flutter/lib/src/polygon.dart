import 'bounds.dart';

class Polygon {
  const Polygon(this.rings, this.bounds);

  final List<List<List<double>>> rings;
  final Bounds bounds;

  bool contains(double latitude, double longitude) {
    if (!bounds.contains(latitude, longitude) || rings.isEmpty) return false;
    if (!_ringContains(rings.first, latitude, longitude)) return false;

    for (final hole in rings.skip(1)) {
      if (_ringContains(hole, latitude, longitude)) return false;
    }
    return true;
  }

  static Polygon fromGeoJsonPolygon(List<Object?> coordinates) {
    final rings = coordinates.map(_parseRing).toList(growable: false);
    var bounds = Bounds.fromRing(rings.first);
    for (final ring in rings.skip(1)) {
      bounds = bounds.expand(Bounds.fromRing(ring));
    }
    return Polygon(rings, bounds);
  }

  static List<List<double>> _parseRing(Object? ring) {
    final points = ring as List<Object?>;
    return points.map((point) {
      final pair = point as List<Object?>;
      return [(pair[0] as num).toDouble(), (pair[1] as num).toDouble()];
    }).toList(growable: false);
  }

  static bool _ringContains(
    List<List<double>> ring,
    double latitude,
    double longitude,
  ) {
    var inside = false;
    var previous = ring.length - 1;

    for (var current = 0; current < ring.length; current++) {
      final currentLongitude = ring[current][0];
      final currentLatitude = ring[current][1];
      final previousLongitude = ring[previous][0];
      final previousLatitude = ring[previous][1];

      final intersects =
          (currentLatitude > latitude) != (previousLatitude > latitude) &&
              longitude <
                  (previousLongitude - currentLongitude) *
                          (latitude - currentLatitude) /
                          (previousLatitude - currentLatitude) +
                      currentLongitude;

      if (intersects) inside = !inside;
      previous = current;
    }

    return inside;
  }
}
