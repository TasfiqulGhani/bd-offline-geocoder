import 'dart:convert';

import 'boundary_feature.dart';
import 'geocoder_layer.dart';
import 'polygon.dart';

/// Shared GeoJSON FeatureCollection parsing used by file and asset loaders.
GeocoderLayer parseGeoJsonLayer(
  Map<String, Object?> geoJson, {
  required String id,
  required GeocoderLayerType type,
  List<String>? namePropertyCandidates,
}) {
  final features = geoJson['features'] as List<Object?>? ?? const [];
  final parsed = features
      .map((feature) => _parseFeature(feature as Map<String, Object?>))
      .whereType<BoundaryFeature>()
      .toList(growable: false);

  return GeocoderLayer(
    id: id,
    type: type,
    features: parsed,
    namePropertyCandidates: namePropertyCandidates ??
        const [
          'name',
          'NAME',
          'Name',
          'adm1_name',
          'adm2_name',
          'adm3_name',
          'adm4_name',
          'ADM1_EN',
          'ADM2_EN',
          'ADM3_EN',
          'ADM4_EN',
          'shapeName',
          'shapeNameEn',
        ],
  );
}

GeocoderLayer parseGeoJsonLayerText(
  String jsonText, {
  required String id,
  required GeocoderLayerType type,
  List<String>? namePropertyCandidates,
}) {
  final decoded = jsonDecode(jsonText) as Map<String, Object?>;
  return parseGeoJsonLayer(
    decoded,
    id: id,
    type: type,
    namePropertyCandidates: namePropertyCandidates,
  );
}

BoundaryFeature? _parseFeature(Map<String, Object?> feature) {
  final geometry = feature['geometry'] as Map<String, Object?>?;
  if (geometry == null) return null;

  final polygons = _parseGeometry(geometry);
  if (polygons.isEmpty) return null;

  var bounds = polygons.first.bounds;
  for (final polygon in polygons.skip(1)) {
    bounds = bounds.expand(polygon.bounds);
  }

  return BoundaryFeature(
    properties: (feature['properties'] as Map<String, Object?>?) ?? const {},
    polygons: polygons,
    bounds: bounds,
  );
}

List<Polygon> _parseGeometry(Map<String, Object?> geometry) {
  final type = geometry['type'] as String?;
  final coordinates = geometry['coordinates'] as List<Object?>?;
  if (type == null || coordinates == null) return const [];

  if (type == 'Polygon') {
    return [Polygon.fromGeoJsonPolygon(coordinates)];
  }

  if (type == 'MultiPolygon') {
    return coordinates
        .map((polygon) => Polygon.fromGeoJsonPolygon(polygon as List<Object?>))
        .toList(growable: false);
  }

  return const [];
}
