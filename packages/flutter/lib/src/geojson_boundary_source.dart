import 'geojson_file.dart';
import 'geojson_parser.dart';
import 'geocoder_layer.dart';

/// Parser for GeoJSON boundary files used by [GeocoderLayer].
class GeoJsonBoundarySource {
  const GeoJsonBoundarySource._();

  /// Loads a GeoJSON `FeatureCollection` from a local filesystem [path].
  ///
  /// Unavailable on web. Use [fromString], [fromMap], or
  /// [BdOfflineGeocoder.fromBundledAssets] instead.
  static Future<GeocoderLayer> fromFile(
    String path, {
    required String id,
    required GeocoderLayerType type,
    List<String>? namePropertyCandidates,
  }) {
    return loadGeoJsonFile(
      path,
      id: id,
      type: type,
      namePropertyCandidates: namePropertyCandidates,
    );
  }

  /// Parses a GeoJSON `FeatureCollection` from raw JSON text.
  static GeocoderLayer fromString(
    String jsonText, {
    required String id,
    required GeocoderLayerType type,
    List<String>? namePropertyCandidates,
  }) {
    return parseGeoJsonLayerText(
      jsonText,
      id: id,
      type: type,
      namePropertyCandidates: namePropertyCandidates,
    );
  }

  /// Parses a GeoJSON `FeatureCollection` from an already decoded map.
  static GeocoderLayer fromMap(
    Map<String, Object?> geoJson, {
    required String id,
    required GeocoderLayerType type,
    List<String>? namePropertyCandidates,
  }) {
    return parseGeoJsonLayer(
      geoJson,
      id: id,
      type: type,
      namePropertyCandidates: namePropertyCandidates,
    );
  }
}
