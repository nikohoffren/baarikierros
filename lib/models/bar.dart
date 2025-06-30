import 'package:cloud_firestore/cloud_firestore.dart';

class OpenPeriod {
  final String open;
  final String close;

  OpenPeriod({required this.open, required this.close});

  factory OpenPeriod.fromJson(Map<String, dynamic> json) {
    return OpenPeriod(
      open: json['open'] as String,
      close: json['close'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
    };
  }
}

class Bar {
  final String id;
  final String name;
  final String? description;
  final double lat;
  final double lon;
  final List<String> imageUrls;
  final Map<String, List<OpenPeriod>> openingHours;
  final String? address;
  final String? website;
  final String? phone;
  final Map<String, dynamic>? additionalInfo;
  final DateTime? createdAt;
  final String? createdBy;
  final bool isActive;

  Bar({
    required this.id,
    required this.name,
    this.description,
    required this.lat,
    required this.lon,
    required this.imageUrls,
    required this.openingHours,
    this.address,
    this.website,
    this.phone,
    this.additionalInfo,
    this.createdAt,
    this.createdBy,
    this.isActive = true,
  });

  factory Bar.fromJson(Map<String, dynamic> json) {
    return Bar(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      openingHours: (json['openingHours'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((period) => OpenPeriod.fromJson(period as Map<String, dynamic>))
              .toList(),
        ),
      ),
      address: json['address'] as String?,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lat': lat,
      'lon': lon,
      'imageUrls': imageUrls,
      'openingHours': openingHours.map(
        (key, value) => MapEntry(
          key,
          value.map((period) => period.toJson()).toList(),
        ),
      ),
      'address': address,
      'website': website,
      'phone': phone,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  Bar copyWith({
    String? id,
    String? name,
    String? description,
    double? lat,
    double? lon,
    List<String>? imageUrls,
    Map<String, List<OpenPeriod>>? openingHours,
    String? address,
    String? website,
    String? phone,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
  }) {
    return Bar(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      imageUrls: imageUrls ?? this.imageUrls,
      openingHours: openingHours ?? this.openingHours,
      address: address ?? this.address,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bar &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
