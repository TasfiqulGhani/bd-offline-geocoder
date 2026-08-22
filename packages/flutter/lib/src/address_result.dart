import 'address_format.dart';

/// Bangladesh address parts returned from a reverse geocode lookup.
class AddressResult {
  /// Creates an immutable reverse geocode result.
  const AddressResult({
    required this.country,
    this.houseNumber,
    this.roadNumber,
    this.roadName,
    this.areaVillage,
    this.unionWard,
    this.thanaUpazila,
    this.district,
    this.division,
    this.postalCode,
    this.city,
    this.message,
    this.matchedLayers = const {},
  });

  /// Country name, normally `Bangladesh`.
  final String country;

  /// Nearest OSM house number in Dhaka, if within 50 meters.
  final String? houseNumber;

  /// Road number such as `3` or `7`, when the OSM street is `Road 3`.
  final String? roadNumber;

  /// Named road such as `Dhanmondi Road`, when OSM has a name.
  final String? roadName;

  /// Neighborhood or village, usually from OSM `addr:city`.
  final String? areaVillage;

  /// ADM4 union, ward, or pourashava name.
  final String? unionWard;

  /// Rural upazila, or `{area} Thana` when OSM has a Dhaka neighborhood.
  final String? thanaUpazila;

  /// ADM2 district name.
  final String? district;

  /// ADM1 division name.
  final String? division;

  /// Unique Bangladesh Post thana code, when known.
  final String? postalCode;

  /// City name when the point is inside a city corporation.
  final String? city;

  /// Human-readable message for non-match results.
  final String? message;

  /// Raw properties for every matched layer, keyed by layer id.
  final Map<String, Map<String, Object?>> matchedLayers;

  /// Whether at least one configured GeoJSON layer matched the point.
  bool get found => matchedLayers.isNotEmpty;

  /// Comma-separated address string ordered from smallest to largest area.
  String get formatted {
    if (!found && message != null) return message!;

    final roadNumberPart = roadNumber == null
        ? null
        : roadNumber!.toLowerCase().startsWith('road')
            ? roadNumber
            : 'Road $roadNumber';
    var place = city ?? district;
    if (place != null && postalCode != null) {
      place = '$place $postalCode';
    } else if (postalCode != null) {
      place = postalCode;
    }
    var divisionPart = division;
    final placeBase = city ?? district ?? '';
    if (divisionPart != null &&
        placeBase.isNotEmpty &&
        divisionPart.toLowerCase() == placeBase.toLowerCase()) {
      divisionPart = null;
    }
    return formatAddress([
      houseNumber == null ? null : 'House $houseNumber',
      roadNumberPart,
      roadName,
      areaVillage,
      unionWard,
      thanaUpazila,
      place,
      divisionPart,
      country,
    ]);
  }

  String _blank(String? value) =>
      value != null && value.trim().isNotEmpty ? value : '';

  /// Converts this result to the stable Bangladesh address JSON schema.
  Map<String, Object?> toJson() => {
        'house_number': _blank(houseNumber),
        'road_number': _blank(roadNumber),
        'road_name': _blank(roadName),
        'area_village': _blank(areaVillage),
        'union_ward': _blank(unionWard),
        'thana_upazila': _blank(thanaUpazila),
        'district': _blank(district),
        'division': _blank(division),
        'postal_code': _blank(postalCode),
        'city': _blank(city),
        'country': country,
        if (message != null) 'message': message,
        'found': found,
        'formatted': formatted,
        'matchedLayers': matchedLayers,
      };

  @override
  String toString() => formatted;
}
