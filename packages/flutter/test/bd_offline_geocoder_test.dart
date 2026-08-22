import 'package:bd_offline_geocoder/bd_offline_geocoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('matches nested administrative layers', () async {
    final divisions = await GeoJsonBoundarySource.fromFile(
      'test/fixtures/sample_bangladesh_admin.geojson',
      id: 'divisions',
      type: GeocoderLayerType.division,
    );
    final districts = await GeoJsonBoundarySource.fromFile(
      'test/fixtures/sample_districts.geojson',
      id: 'districts',
      type: GeocoderLayerType.district,
    );
    final upazilas = await GeoJsonBoundarySource.fromFile(
      'test/fixtures/sample_upazilas.geojson',
      id: 'upazilas',
      type: GeocoderLayerType.upazila,
    );
    final unions = await GeoJsonBoundarySource.fromFile(
      'test/fixtures/sample_unions.geojson',
      id: 'unions',
      type: GeocoderLayerType.union,
    );

    final geocoder = BangladeshReverseGeocoder(
      layers: [divisions, districts, upazilas, unions],
    );

    final result = geocoder.reverse(latitude: 23.7615, longitude: 90.3917);

    expect(result.found, isTrue);
    expect(result.division, 'Dhaka Division');
    expect(result.district, 'Dhaka District');
    expect(result.thanaUpazila, 'Tejgaon');
    expect(
      result.formatted,
      'Tejgaon, Dhaka District, Dhaka Division, Bangladesh',
    );
  });

  test('matches fixture coordinate down to ward level', () async {
    final divisions = await GeoJsonBoundarySource.fromFile(
      'test/fixtures/sample_bangladesh_admin.geojson',
      id: 'divisions',
      type: GeocoderLayerType.division,
    );
    final districts = await GeoJsonBoundarySource.fromFile(
      'test/fixtures/sample_districts.geojson',
      id: 'districts',
      type: GeocoderLayerType.district,
    );
    final upazilas = await GeoJsonBoundarySource.fromFile(
      'test/fixtures/sample_upazilas.geojson',
      id: 'upazilas',
      type: GeocoderLayerType.upazila,
    );
    final unions = await GeoJsonBoundarySource.fromFile(
      'test/fixtures/sample_unions.geojson',
      id: 'unions',
      type: GeocoderLayerType.union,
    );

    final geocoder = BangladeshReverseGeocoder(
      layers: [divisions, districts, upazilas, unions],
    );

    final result = geocoder.reverse(latitude: 23.771, longitude: 90.355);

    expect(result.division, 'Dhaka Division');
    expect(result.district, 'Dhaka District');
    expect(result.thanaUpazila, 'Mohammadpur Thana');
    expect(result.unionWard, 'Ward 29');
    expect(
      result.formatted,
      'Ward 29, Mohammadpur Thana, Dhaka District, Dhaka Division, Bangladesh',
    );
  });

  test('matches packaged boundary data down to ADM4 level', () async {
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

    final geocoder = BdOfflineGeocoder(
      layers: [divisions, districts, upazilas, unions],
    );

    final result = geocoder.reverse(latitude: 23.771, longitude: 90.355);

    expect(result.division, 'Dhaka');
    expect(result.district, 'Dhaka');
    expect(result.unionWard, 'Ward No-43');
    expect(result.city, 'Dhaka');
    expect(result.thanaUpazila, isNull);
    expect(
      result.formatted,
      'Ward No-43, Dhaka, Bangladesh',
    );
  });

  test('returns Bangladesh-only message outside all configured layers',
      () async {
    final divisions = await GeoJsonBoundarySource.fromFile(
      'test/fixtures/sample_bangladesh_admin.geojson',
      id: 'divisions',
      type: GeocoderLayerType.division,
    );

    final geocoder = BangladeshReverseGeocoder(layers: [divisions]);
    final result = geocoder.reverse(latitude: 22.0, longitude: 89.0);

    expect(result.found, isFalse);
    expect(result.message, BangladeshReverseGeocoder.bangladeshOnlyMessage);
    expect(
      result.formatted,
      'This geocoder only supports locations inside Bangladesh.',
    );
    expect(result.toJson()['message'], result.message);
  });

  test('rejects invalid coordinates', () {
    final geocoder = BangladeshReverseGeocoder(layers: const []);

    expect(
      () => geocoder.reverse(latitude: 123, longitude: 90),
      throwsRangeError,
    );
    expect(
      () => geocoder.reverse(latitude: 23, longitude: 190),
      throwsRangeError,
    );
    expect(
      () => geocoder.reverse(latitude: double.nan, longitude: 90),
      throwsRangeError,
    );
  });

  test('fromBundledAssets matches packaged ADM4 data', () async {
    final geocoder = await BdOfflineGeocoder.fromBundledAssets();
    final result = geocoder.reverse(latitude: 23.771, longitude: 90.355);

    expect(result.division, 'Dhaka');
    expect(result.district, 'Dhaka');
    expect(result.unionWard, 'Ward No-43');
    expect(result.city, 'Dhaka');
    expect(result.houseNumber, '৭৪৯');
    expect(result.roadNumber, anyOf('০৮', '8'));
    expect(result.formatted, contains('Bangladesh'));
  });

  test('Dhanmondi includes locality and postal code', () async {
    final geocoder = await BdOfflineGeocoder.fromBundledAssets();
    final result = geocoder.reverse(latitude: 23.74015, longitude: 90.38286);

    expect(result.houseNumber, '3');
    expect(result.roadNumber, '3');
    expect(result.areaVillage, 'Dhanmondi');
    expect(result.thanaUpazila, 'Dhanmondi Thana');
    expect(result.postalCode, '1209');
    expect(result.unionWard, 'Ward No-49');
    expect(result.city, 'Dhaka');
    expect(
      result.formatted,
      'House 3, Road 3, Dhanmondi, Ward No-49, Dhanmondi Thana, Dhaka 1209, Bangladesh',
    );
  });
}
