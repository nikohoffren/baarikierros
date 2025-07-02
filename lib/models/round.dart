import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baarikierros/models/bar.dart';

class Round {
  final String id;
  final String name;
  final String? description;
  final String cityId;
  final List<Bar> bars;
  final String? estimatedDuration;
  final DateTime? createdAt;
  final String? createdBy;
  final bool isPublic;
  final int? minutesPerBar;
  final String? imageUrl;

  Round({
    required this.id,
    required this.name,
    this.description,
    required this.cityId,
    required this.bars,
    this.estimatedDuration,
    this.createdAt,
    this.createdBy,
    this.isPublic = true,
    this.minutesPerBar,
    this.imageUrl,
  });

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      cityId: json['cityId'] as String,
      bars: (json['bars'] as List<dynamic>)
          .map((bar) => Bar.fromJson(bar as Map<String, dynamic>))
          .toList(),
      estimatedDuration: json['estimatedDuration'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      minutesPerBar: json['minutesPerBar'] as int?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cityId': cityId,
      'bars': bars.map((bar) => bar.toJson()).toList(),
      'estimatedDuration': estimatedDuration,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy,
      'isPublic': isPublic,
      'minutesPerBar': minutesPerBar,
      'imageUrl': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Round &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  //* Create a Round from Firestore document
  factory Round.fromFirestore(String docId, Map<String, dynamic> data) {
    return Round(
      id: docId,
      name: data['name'] as String,
      description: data['description'] as String?,
      cityId: data['cityId'] as String,
      bars: (data['bars'] as List<dynamic>).map((e) => Bar.fromJson(e as Map<String, dynamic>)).toList(),
      estimatedDuration: data['estimatedDuration'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
      isPublic: data['isPublic'] as bool? ?? true,
      minutesPerBar: data['minutesPerBar'] as int?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  //* Convert Round to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'cityId': cityId,
      'bars': bars.map((bar) => bar.toJson()).toList(),
      'estimatedDuration': estimatedDuration,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'isPublic': isPublic,
      'minutesPerBar': minutesPerBar,
      'imageUrl': imageUrl,
    };
  }

  //* Create a copy of Round with updated fields
  Round copyWith({
    String? id,
    String? name,
    String? description,
    String? cityId,
    List<Bar>? bars,
    String? estimatedDuration,
    DateTime? createdAt,
    String? createdBy,
    bool? isPublic,
    int? minutesPerBar,
    String? imageUrl,
  }) {
    return Round(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      cityId: cityId ?? this.cityId,
      bars: bars ?? this.bars,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isPublic: isPublic ?? this.isPublic,
      minutesPerBar: minutesPerBar ?? this.minutesPerBar,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
