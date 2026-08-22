import 'package:bd_offline_geocoder/bd_offline_geocoder.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BD Offline Geocoder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A4E)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: const ReverseGeocoderScreen(),
    );
  }
}

class ReverseGeocoderScreen extends StatefulWidget {
  const ReverseGeocoderScreen({super.key});

  @override
  State<ReverseGeocoderScreen> createState() => _ReverseGeocoderScreenState();
}

class _ReverseGeocoderScreenState extends State<ReverseGeocoderScreen> {
  final _latitudeController = TextEditingController(text: '23.74015');
  final _longitudeController = TextEditingController(text: '90.38286');

  BangladeshReverseGeocoder? _geocoder;
  AddressResult? _result;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGeocoder();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _loadGeocoder() async {
    try {
      final geocoder = await BdOfflineGeocoder.fromBundledAssets();
      setState(() {
        _geocoder = geocoder;
        _loading = false;
      });
      _reverse();
    } catch (error) {
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _reverse() {
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    if (latitude == null || longitude == null) {
      setState(() {
        _error = 'Enter valid latitude and longitude values.';
        _result = null;
      });
      return;
    }

    try {
      final result = _geocoder!.reverse(
        latitude: latitude,
        longitude: longitude,
      );
      setState(() {
        _result = result;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _result = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BD Offline Geocoder')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Offline Bangladesh Address Lookup',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          prefixIcon: Icon(Icons.explore_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading || _geocoder == null ? null : _reverse,
                  icon: const Icon(Icons.search),
                  label: const Text('Reverse Geocode'),
                ),
                const SizedBox(height: 20),
                if (_loading) const LinearProgressIndicator(),
                if (_error != null)
                  _ResultPanel(
                    icon: Icons.error_outline,
                    title: 'Unable to reverse geocode',
                    body: _error!,
                  ),
                if (_result != null)
                  _ResultPanel(
                    icon: Icons.place_outlined,
                    title:
                        _result!.found ? 'Matched Address' : 'No Layer Match',
                    body: _result!.formatted,
                    rows: [
                      _InfoRow('House number', _result!.houseNumber),
                      _InfoRow('Road number', _result!.roadNumber),
                      _InfoRow('Road name', _result!.roadName),
                      _InfoRow('Area / village', _result!.areaVillage),
                      _InfoRow('Union / ward', _result!.unionWard),
                      _InfoRow('Thana / upazila', _result!.thanaUpazila),
                      _InfoRow('District', _result!.district),
                      _InfoRow('Division', _result!.division),
                      _InfoRow('Postal code', _result!.postalCode),
                      _InfoRow('City', _result!.city),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.icon,
    required this.title,
    required this.body,
    this.rows = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
            if (rows.isNotEmpty) ...[
              const Divider(height: 28),
              for (final row in rows) row,
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}
