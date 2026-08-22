// ignore_for_file: avoid_print

import 'package:bd_offline_geocoder/bd_offline_geocoder.dart';

Future<void> main() async {
  final divisions = await GeoJsonBoundarySource.fromFile(
    'assets/boundaries/bgd_admin1.geojson',
    id: 'divisions',
    type: GeocoderLayerType.division,
    namePropertyCandidates: const ['adm1_name'],
  );
  final districts = await GeoJsonBoundarySource.fromFile(
    'assets/boundaries/bgd_admin2.geojson',
    id: 'districts',
    type: GeocoderLayerType.district,
    namePropertyCandidates: const ['adm2_name'],
  );
  final upazilas = await GeoJsonBoundarySource.fromFile(
    'assets/boundaries/bgd_admin3.geojson',
    id: 'upazilas',
    type: GeocoderLayerType.upazila,
    namePropertyCandidates: const ['adm3_name'],
  );
  final unions = await GeoJsonBoundarySource.fromFile(
    'assets/boundaries/bgd_admin4_simplified.geojson',
    id: 'unions',
    type: GeocoderLayerType.union,
    namePropertyCandidates: const ['shapeName'],
  );

  final geocoder = BangladeshReverseGeocoder(
    layers: [divisions, districts, upazilas, unions],
  );

  final result = geocoder.reverse(latitude: 23.74015, longitude: 90.38286);

  print(result.formatted);
  print(result.toJson());
}
