import 'bounds.dart';
import 'polygon.dart';

class BoundaryFeature {
  const BoundaryFeature({
    required this.properties,
    required this.polygons,
    required this.bounds,
  });

  final Map<String, Object?> properties;
  final List<Polygon> polygons;
  final Bounds bounds;

  bool contains(double latitude, double longitude) {
    if (!bounds.contains(latitude, longitude)) return false;
    return polygons.any((polygon) => polygon.contains(latitude, longitude));
  }
}
