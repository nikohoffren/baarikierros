class Bar {
  final String name;
  final double lat;
  final double lon;
  final String? description;
  final String? imageUrl;

  const Bar({
    required this.name,
    required this.lat,
    required this.lon,
    this.description,
    this.imageUrl,
  });

  factory Bar.fromJson(Map<String, dynamic> json) {
    return Bar(
      name: json['name'] as String,
      lat: json['lat'] as double,
      lon: json['lon'] as double,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lon': lon,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
