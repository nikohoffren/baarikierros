class OpenPeriod {
  final String open;
  final String close;

  const OpenPeriod({required this.open, required this.close});

  factory OpenPeriod.fromJson(Map<String, dynamic> json) {
    return OpenPeriod(
      open: json['open'] as String,
      close: json['close'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'open': open,
    'close': close,
  };
}

class Bar {
  final String name;
  final double lat;
  final double lon;
  final String? description;
  final String? imageUrl;
  final Map<String, List<OpenPeriod>> openingHours;

  const Bar({
    required this.name,
    required this.lat,
    required this.lon,
    this.description,
    this.imageUrl,
    required this.openingHours,
  });

  factory Bar.fromJson(Map<String, dynamic> json) {
    final openingHoursJson = json['openingHours'] as Map<String, dynamic>? ?? {};
    final openingHours = openingHoursJson.map((key, value) => MapEntry(
      key,
      (value as List<dynamic>).map((e) => OpenPeriod.fromJson(e as Map<String, dynamic>)).toList(),
    ));
    return Bar(
      name: json['name'] as String,
      lat: json['lat'] as double,
      lon: json['lon'] as double,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      openingHours: openingHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lon': lon,
      'description': description,
      'imageUrl': imageUrl,
      'openingHours': openingHours.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
    };
  }
}
