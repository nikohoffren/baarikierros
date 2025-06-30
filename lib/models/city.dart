class City {
  final String id;
  final String name;
  final String? description;
  final double lat;
  final double lon;
  final String? imageUrl;

  City({
    required this.id,
    required this.name,
    this.description,
    required this.lat,
    required this.lon,
    this.imageUrl,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      lat: (json['lat'] as num? ?? 0).toDouble(),
      lon: (json['lon'] as num? ?? 0).toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lat': lat,
      'lon': lon,
      'imageUrl': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
