import 'boundary_feature.dart';

/// Semantic administrative level represented by a [GeocoderLayer].
enum GeocoderLayerType {
  /// ADM1 division layer.
  division,

  /// ADM2 district layer.
  district,

  /// ADM3 upazila, thana, or city corporation layer.
  upazila,

  /// ADM4 union, ward, or pourashava layer.
  union,

  /// Optional smaller custom place layer.
  locality,

  /// Any other caller-defined polygon layer.
  custom,
}

/// A named collection of boundary polygons for one administrative level.
class GeocoderLayer {
  /// Creates a geocoder layer from parsed boundary features.
  const GeocoderLayer({
    required this.id,
    required this.type,
    required this.features,
    this.namePropertyCandidates = const [
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
  });

  /// Stable caller-defined id, such as `divisions` or `districts`.
  final String id;

  /// Administrative level represented by this layer.
  final GeocoderLayerType type;

  /// Boundary features parsed from GeoJSON.
  final List<BoundaryFeature> features;

  /// Property keys checked in order when extracting display names.
  final List<String> namePropertyCandidates;

  /// Returns the first feature containing [latitude] and [longitude].
  BoundaryFeature? match(double latitude, double longitude) {
    for (final feature in features) {
      if (feature.contains(latitude, longitude)) return feature;
    }
    return null;
  }

  /// Reads the first non-empty configured display-name property.
  String? displayNameFor(BoundaryFeature feature) {
    for (final key in namePropertyCandidates) {
      final value = feature.properties[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
