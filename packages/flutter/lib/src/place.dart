import 'area_postcodes.dart';

const _skip = {
  'bangladesh',
  'dhaka',
  'dhaka city',
  'dhaka city corporation',
  'dhaka north city corporation',
  'dhaka south city corporation',
};

final _split = RegExp(r'[,/|]');

String normalizePlaceName(String value) {
  var cleaned = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.contains('(')) {
    cleaned = cleaned.split('(').first.trim();
  }
  return cleaned;
}

String? localityFromCity(String? city, [List<String?> skipNames = const []]) {
  if (city == null || city.trim().isEmpty) return null;
  final skip = {..._skip};
  for (final name in skipNames) {
    if (name == null || name.trim().isEmpty) continue;
    skip
      ..add(normalizePlaceName(name))
      ..add(name.trim().toLowerCase());
  }
  for (final part in city.split(_split)) {
    final cleaned = part.trim();
    if (cleaned.isEmpty) continue;
    if (skip.contains(cleaned.toLowerCase()) ||
        skip.contains(normalizePlaceName(cleaned))) {
      continue;
    }
    return cleaned;
  }
  return null;
}

String? lookupPostcode(String? district, List<String?> names) {
  if (district == null || district.trim().isEmpty) return null;
  final table = areaPostcodes[normalizePlaceName(district)];
  if (table == null) return null;
  for (final name in names) {
    if (name == null || name.trim().isEmpty) continue;
    final folded = name.trim().toLowerCase();
    if (folded.startsWith('ward') || folded.contains('city corporation')) {
      continue;
    }
    final key = normalizePlaceName(name);
    if (_skip.contains(key)) continue;
    final code = table[key];
    if (code != null) return code;
  }
  return null;
}

List<String> postcodeCandidates({
  String? locality,
  String? city,
  String? union,
  String? upazila,
}) {
  final names = <String>[];
  for (final value in [locality, city, union, upazila]) {
    if (value == null || value.trim().isEmpty) continue;
    names.add(value.trim());
    for (final part in value.split(_split)) {
      final cleaned = part.trim();
      if (cleaned.isNotEmpty && !names.contains(cleaned)) {
        names.add(cleaned);
      }
    }
  }
  return names;
}

bool isCityCorporation(String? name) =>
    name != null && name.toLowerCase().contains('city corporation');

({String? roadNumber, String? roadName}) splitRoad(String? road) {
  if (road == null || road.trim().isEmpty) {
    return (roadNumber: null, roadName: null);
  }
  final value = road.trim();
  final prefixed = RegExp(r'^(?:road|rd)\s*[#:]?\s*(.+)$', caseSensitive: false)
      .firstMatch(value);
  if (prefixed != null) {
    return (roadNumber: prefixed.group(1)!.trim(), roadName: null);
  }
  if (RegExp(r'^[\d০-৯][\d০-৯/\-]*$').hasMatch(value)) {
    return (roadNumber: value, roadName: null);
  }
  final named = RegExp(r'^(.*?\broad)\s+([\d০-৯][\d০-৯/\-]*)$', caseSensitive: false)
      .firstMatch(value);
  if (named != null) {
    return (roadNumber: named.group(2)!.trim(), roadName: named.group(1)!.trim());
  }
  return (roadNumber: null, roadName: value);
}

String? thanaUpazilaName(String? upazila, String? areaVillage) {
  if (upazila != null && upazila.trim().isNotEmpty && !isCityCorporation(upazila)) {
    return upazila.trim();
  }
  if (areaVillage == null || areaVillage.trim().isEmpty) return null;
  final area = areaVillage.trim();
  final folded = area.toLowerCase();
  if (folded.contains('thana') || folded.contains('upazila')) return area;
  return '$area Thana';
}

String? cityName(String? upazila, String? district) {
  if (isCityCorporation(upazila) && district != null && district.trim().isNotEmpty) {
    return district.trim();
  }
  return null;
}
