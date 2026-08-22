class Bounds {
  const Bounds({
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;

  bool contains(double latitude, double longitude) {
    return latitude >= minLatitude &&
        latitude <= maxLatitude &&
        longitude >= minLongitude &&
        longitude <= maxLongitude;
  }

  static Bounds fromRing(List<List<double>> ring) {
    var minLatitude = double.infinity;
    var minLongitude = double.infinity;
    var maxLatitude = double.negativeInfinity;
    var maxLongitude = double.negativeInfinity;

    for (final point in ring) {
      final longitude = point[0];
      final latitude = point[1];
      if (latitude < minLatitude) minLatitude = latitude;
      if (latitude > maxLatitude) maxLatitude = latitude;
      if (longitude < minLongitude) minLongitude = longitude;
      if (longitude > maxLongitude) maxLongitude = longitude;
    }

    return Bounds(
      minLatitude: minLatitude,
      minLongitude: minLongitude,
      maxLatitude: maxLatitude,
      maxLongitude: maxLongitude,
    );
  }

  Bounds expand(Bounds other) {
    return Bounds(
      minLatitude:
          minLatitude < other.minLatitude ? minLatitude : other.minLatitude,
      minLongitude:
          minLongitude < other.minLongitude ? minLongitude : other.minLongitude,
      maxLatitude:
          maxLatitude > other.maxLatitude ? maxLatitude : other.maxLatitude,
      maxLongitude:
          maxLongitude > other.maxLongitude ? maxLongitude : other.maxLongitude,
    );
  }
}
