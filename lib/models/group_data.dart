import 'package:cloud_firestore/cloud_firestore.dart';
import 'round.dart';
import 'bar.dart';

class GroupData {
  final String groupCode;
  final String routeId;
  final String routeName;
  final List<dynamic> bars;
  final Map<String, dynamic> members;
  final String createdBy;
  final bool started;
  final bool isActive;
  final DateTime? startedAt;
  final DateTime? createdAt;
  final Map<String, dynamic> checkIns;
  final Map<String, dynamic> barTimers;

  GroupData({
    required this.groupCode,
    required this.routeId,
    required this.routeName,
    required this.bars,
    required this.members,
    required this.createdBy,
    required this.started,
    required this.isActive,
    this.startedAt,
    this.createdAt,
    required this.checkIns,
    required this.barTimers,
  });

  factory GroupData.fromFirestore(String groupCode, Map<String, dynamic> data) {
    return GroupData(
      groupCode: groupCode,
      routeId: data['routeId'] ?? '',
      routeName: data['routeName'] ?? '',
      bars: data['bars'] ?? [],
      members: Map<String, dynamic>.from(data['members'] ?? {}),
      createdBy: data['createdBy'] ?? '',
      started: data['started'] ?? false,
      isActive: data['isActive'] ?? true,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      checkIns: Map<String, dynamic>.from(data['checkIns'] ?? {}),
      barTimers: Map<String, dynamic>.from(data['barTimers'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupCode': groupCode,
      'routeId': routeId,
      'routeName': routeName,
      'bars': bars,
      'members': members,
      'createdBy': createdBy,
      'started': started,
      'isActive': isActive,
      'startedAt': startedAt,
      'createdAt': createdAt,
      'checkIns': checkIns,
      'barTimers': barTimers,
    };
  }

  Round toRound() {
    return Round(
      id: routeId,
      name: routeName,
      description: null,
      cityId: '',
      bars: bars.map((e) => Bar.fromJson(Map<String, dynamic>.from(e))).toList(),
      estimatedDuration: null,
      createdAt: createdAt,
      createdBy: createdBy,
      isPublic: true,
      minutesPerBar: null,
      imageUrl: null,
    );
  }
}
