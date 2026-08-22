import 'geocoder_layer.dart';

/// Filesystem loading is unavailable on web and other non-IO platforms.
Future<GeocoderLayer> loadGeoJsonFile(
  String path, {
  required String id,
  required GeocoderLayerType type,
  List<String>? namePropertyCandidates,
}) {
  throw UnsupportedError(
    'GeoJsonBoundarySource.fromFile("$path") is not available on this platform. '
    'Use fromString, fromMap, or BdOfflineGeocoder.fromBundledAssets() for $id ($type).',
  );
}
