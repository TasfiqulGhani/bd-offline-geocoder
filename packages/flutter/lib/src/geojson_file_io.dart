import 'dart:io';

import 'geojson_parser.dart';
import 'geocoder_layer.dart';

/// Loads a GeoJSON FeatureCollection from a local filesystem [path].
Future<GeocoderLayer> loadGeoJsonFile(
  String path, {
  required String id,
  required GeocoderLayerType type,
  List<String>? namePropertyCandidates,
}) async {
  final jsonText = await File(path).readAsString();
  return parseGeoJsonLayerText(
    jsonText,
    id: id,
    type: type,
    namePropertyCandidates: namePropertyCandidates,
  );
}
