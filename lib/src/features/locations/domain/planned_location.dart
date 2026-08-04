class PlannedLocation {
  const PlannedLocation({
    required this.id,
    required this.country,
    required this.city,
    required this.flag,
    required this.countryCode,
    required this.region,
    this.isFavorite = false,
  });

  final String id;
  final String country;
  final String city;
  final String flag;
  final String countryCode;
  final String region;
  final bool isFavorite;
}
