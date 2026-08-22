/// Joins address parts from smallest to largest area, skipping blanks
/// and consecutive duplicate names such as `Dhaka, Dhaka`.
String formatAddress(Iterable<String?> parts) {
  final formatted = <String>[];
  for (final part in parts) {
    if (part == null) continue;
    final cleaned = part.trim();
    if (cleaned.isEmpty) continue;
    if (formatted.isNotEmpty &&
        formatted.last.toLowerCase() == cleaned.toLowerCase()) {
      continue;
    }
    formatted.add(cleaned);
  }
  return formatted.join(', ');
}
