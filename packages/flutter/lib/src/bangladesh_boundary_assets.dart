/// Flutter asset paths for the boundary files bundled with this package.
///
/// Use these paths with `rootBundle.loadString(...)` from Flutter apps.
class BangladeshBoundaryAssets {
  const BangladeshBoundaryAssets._();

  /// ADM1 division boundaries.
  static const divisions =
      'packages/bd_offline_geocoder/assets/boundaries/bgd_admin1.geojson';

  /// ADM2 district boundaries.
  static const districts =
      'packages/bd_offline_geocoder/assets/boundaries/bgd_admin2.geojson';

  /// ADM3 upazila, thana, and city corporation boundaries.
  static const upazilas =
      'packages/bd_offline_geocoder/assets/boundaries/bgd_admin3.geojson';

  /// Simplified ADM4 union, ward, and pourashava boundaries.
  static const unions =
      'packages/bd_offline_geocoder/assets/boundaries/bgd_admin4_simplified.geojson';

  /// Named OpenStreetMap roads for central Dhaka.
  static const dhakaRoads =
      'packages/bd_offline_geocoder/assets/roads/dhaka_named_roads.geojson';

  /// OpenStreetMap house-number points for central Dhaka.
  static const dhakaAddresses =
      'packages/bd_offline_geocoder/assets/addresses/dhaka_address_points.geojson';
}
