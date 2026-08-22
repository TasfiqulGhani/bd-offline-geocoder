import 'package:flutter/services.dart';

import 'dart:convert';

import 'address_result.dart';
import 'bangladesh_boundary_assets.dart';
import 'boundary_feature.dart';
import 'geocoder_layer.dart';
import 'geojson_parser.dart';
import 'place.dart';
import 'street_index.dart';


/// Offline reverse geocoder for Bangladesh administrative boundary layers.
class BangladeshReverseGeocoder {
  /// Message returned when a point is outside every configured BD boundary.
  static const bangladeshOnlyMessage =
      'This geocoder only supports locations inside Bangladesh.';

  /// Creates a geocoder from already parsed boundary [layers].
  BangladeshReverseGeocoder({
    required List<GeocoderLayer> layers,
    this.countryName = 'Bangladesh',
    List<Map<String, Object?>> roadFeatures = const [],
    List<Map<String, Object?>> addressFeatures = const [],
  })  : _layers = List.unmodifiable(layers),
        _roadFeatures = List.unmodifiable(roadFeatures),
        _addressFeatures = List.unmodifiable(addressFeatures);

  /// Configured boundary layers searched from largest to smallest area.
  final List<GeocoderLayer> _layers;
  final List<Map<String, Object?>> _roadFeatures;
  final List<Map<String, Object?>> _addressFeatures;

  /// Country name included in every result.
  final String countryName;

  /// Looks up administrative address parts for [latitude] and [longitude].
  AddressResult reverse({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinate(latitude, longitude);

    String? division;
    String? district;
    String? upazila;
    String? union;
    String? locality;
    final matchedLayers = <String, Map<String, Object?>>{};

    for (final layer in _layers) {
      final feature = layer.match(latitude, longitude);
      if (feature == null) continue;

      final name = layer.displayNameFor(feature);
      matchedLayers[layer.id] = feature.properties;

      switch (layer.type) {
        case GeocoderLayerType.division:
          division = name;
        case GeocoderLayerType.district:
          district = name;
        case GeocoderLayerType.upazila:
          upazila = name;
        case GeocoderLayerType.union:
          union = name;
        case GeocoderLayerType.locality:
        case GeocoderLayerType.custom:
          locality = name;
      }
    }

    final addressMatch = nearestAddress(_addressFeatures, latitude, longitude);
    final roadMatch = nearestRoad(_roadFeatures, latitude, longitude);
    String? road;
    String? houseNumber;
    String? city;
    if (addressMatch != null) {
      houseNumber = addressMatch.housenumber;
      road = addressMatch.street;
      final rawCity = addressMatch.properties['city'];
      city = rawCity is String && rawCity.trim().isNotEmpty ? rawCity.trim() : null;
      locality ??= localityFromCity(city, [district, division, upazila]);
      matchedLayers['dhaka_addresses'] = addressMatch.properties;
    }
    if (roadMatch != null && road == null) {
      road = roadMatch.name;
    }
    if (roadMatch != null) {
      matchedLayers['dhaka_roads'] = roadMatch.properties;
    }

    final postalCode = lookupPostcode(
      district,
      postcodeCandidates(
        locality: locality,
        city: city,
        union: union,
        upazila: upazila,
      ),
    );
    final split = splitRoad(road);

    return AddressResult(
      country: countryName,
      houseNumber: houseNumber,
      roadNumber: split.roadNumber,
      roadName: split.roadName,
      areaVillage: locality,
      unionWard: union,
      thanaUpazila: thanaUpazilaName(upazila, locality),
      district: district,
      division: division,
      postalCode: postalCode,
      city: cityName(upazila, district),
      message: matchedLayers.isEmpty ? bangladeshOnlyMessage : null,
      matchedLayers: matchedLayers,
    );
  }

  /// Returns the raw feature matched by a specific layer [id], if any.
  BoundaryFeature? matchLayer(String id, double latitude, double longitude) {
    _validateCoordinate(latitude, longitude);
    for (final layer in _layers) {
      if (layer.id == id) return layer.match(latitude, longitude);
    }
    return null;
  }

  static void _validateCoordinate(double latitude, double longitude) {
    if (latitude.isNaN ||
        latitude.isInfinite ||
        latitude < -90 ||
        latitude > 90) {
      throw RangeError(
        'latitude must be a finite number between -90 and 90',
      );
    }
    if (longitude.isNaN ||
        longitude.isInfinite ||
        longitude < -180 ||
        longitude > 180) {
      throw RangeError(
        'longitude must be a finite number between -180 and 180',
      );
    }
  }
}

/// Preferred package-named entry point for offline Bangladesh reverse geocoding.
class BdOfflineGeocoder extends BangladeshReverseGeocoder {
  /// Creates a geocoder from parsed boundary [layers].
  BdOfflineGeocoder({
    required super.layers,
    super.countryName,
    super.roadFeatures,
    super.addressFeatures,
  });

  /// Loads the bundled ADM1-ADM4 Flutter assets in parallel.
  ///
  /// This is the Flutter equivalent of Python/npm `from_included_data()`.
  static Future<BdOfflineGeocoder> fromBundledAssets() async {
    final loaded = await Future.wait<Object>([
      _loadBundledLayer(
        BangladeshBoundaryAssets.divisions,
        id: 'divisions',
        type: GeocoderLayerType.division,
        namePropertyCandidates: const ['adm1_name'],
      ),
      _loadBundledLayer(
        BangladeshBoundaryAssets.districts,
        id: 'districts',
        type: GeocoderLayerType.district,
        namePropertyCandidates: const ['adm2_name'],
      ),
      _loadBundledLayer(
        BangladeshBoundaryAssets.upazilas,
        id: 'upazilas',
        type: GeocoderLayerType.upazila,
        namePropertyCandidates: const ['adm3_name'],
      ),
      _loadBundledLayer(
        BangladeshBoundaryAssets.unions,
        id: 'unions',
        type: GeocoderLayerType.union,
        namePropertyCandidates: const ['shapeName'],
      ),
      _loadFeatureCollection(BangladeshBoundaryAssets.dhakaRoads),
      _loadFeatureCollection(BangladeshBoundaryAssets.dhakaAddresses),
    ]);

    return BdOfflineGeocoder(
      layers: loaded.sublist(0, 4).cast<GeocoderLayer>(),
      roadFeatures: loaded[4] as List<Map<String, Object?>>,
      addressFeatures: loaded[5] as List<Map<String, Object?>>,
    );
  }

  static Future<List<Map<String, Object?>>> _loadFeatureCollection(
    String assetPath,
  ) async {
    final jsonText = await _loadAssetString(assetPath);
    final decoded = jsonDecode(jsonText) as Map<String, Object?>;
    final features = decoded['features'] as List<Object?>? ?? const [];
    return features.cast<Map<String, Object?>>();
  }

  static Future<GeocoderLayer> _loadBundledLayer(
    String assetPath, {
    required String id,
    required GeocoderLayerType type,
    required List<String> namePropertyCandidates,
  }) async {
    final jsonText = await _loadAssetString(assetPath);
    return parseGeoJsonLayerText(
      jsonText,
      id: id,
      type: type,
      namePropertyCandidates: namePropertyCandidates,
    );
  }

  static Future<String> _loadAssetString(String packagePath) async {
    try {
      return await rootBundle.loadString(packagePath);
    } catch (_) {
      final relative = packagePath.replaceFirst(
        'packages/bd_offline_geocoder/',
        '',
      );
      return rootBundle.loadString(relative);
    }
  }
}
