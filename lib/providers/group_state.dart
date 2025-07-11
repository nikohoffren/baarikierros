import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/round.dart';
import '../models/group_data.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupState extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isGroupMode = false;
  String? _groupCode;
  GroupData? _groupData;
  Stream<GroupData>? _groupStream;
  StreamSubscription<GroupData>? _groupSub;
  String? _myUid;

  bool get isGroupMode => _isGroupMode;
  String? get groupCode => _groupCode;
  GroupData? get groupData => _groupData;
  String? get myUid => _myUid;

  List<Map<String, dynamic>> get groupMembers {
    if (_groupData == null) return [];
    return _groupData!.members.entries.map((e) {
      final m = Map<String, dynamic>.from(e.value);
      m['uid'] = e.key;
      return m;
    }).toList();
  }

  int get myProgress {
    if (_groupData == null || _myUid == null) return 0;
    return _groupData!.members[_myUid]?['currentBarIndex'] ?? 0;
  }

  Future<String> createGroup(Round round, User user) async {
    _isGroupMode = true;
    _myUid = user.uid;
    final code = await _firebaseService.createGroup(round, user);
    _groupCode = code;
    _listenToGroup(code);
    notifyListeners();
    return code;
  }

  Future<void> joinGroup(String groupCode, User user) async {
    _isGroupMode = true;
    _myUid = user.uid;
    await _firebaseService.joinGroup(groupCode, user);
    _groupCode = groupCode;
    _listenToGroup(groupCode);
    notifyListeners();
  }

  void _listenToGroup(String groupCode) {
    _groupSub?.cancel();
    _groupStream = _firebaseService.listenToGroup(groupCode);
    _groupSub = _groupStream!.listen((data) {
      _groupData = data;
      notifyListeners();
    });
  }

  Future<void> updateProgress(int barIndex) async {
    if (_groupCode == null || _myUid == null) return;
    await _firebaseService.updateGroupProgress(_groupCode!, _myUid!, barIndex);
  }

  Future<void> leaveGroup() async {
    if (_groupCode != null && _myUid != null) {
      await _firebaseService.leaveGroup(_groupCode!, _myUid!);
      //* Check if this was the last member or the round is completed, then delete the group
      final doc = await FirebaseFirestore.instance.collection('groups').doc(_groupCode!).get();
      final data = doc.data();
      if (data != null) {
        final members = (data['members'] as Map<String, dynamic>?) ?? {};
        final started = data['started'] == true;
        //* If group is not started and no members left, or only the creator remains, delete the group
        if (!started && (members.isEmpty || (members.length == 1 && members.keys.first == data['createdBy']))) {
          await _firebaseService.deleteGroup(_groupCode!);
        } else if (members.isEmpty && started) {
          await _firebaseService.deleteGroup(_groupCode!);
        }
      }
    }
    _resetGroupState();
    notifyListeners();
  }

  Future<void> startGroup() async {
    if (_groupCode != null) {
      await _firebaseService.startGroup(_groupCode!);
    }
  }

  Future<void> checkInToBar(int barIndex) async {
    if (_groupCode == null || _myUid == null || _groupData == null) return;
    final allUids = _groupData!.members.keys.toList();
    await _firebaseService.checkInToBar(_groupCode!, _myUid!, barIndex, allUids);
  }

  List<String> get checkedInUids {
    if (_groupData == null) return [];
    final barKey = myProgress.toString();
    final checkIns = _groupData!.checkIns;
    return List<String>.from(checkIns[barKey] ?? []);
  }

  DateTime? get currentBarTimer {
    if (_groupData == null) return null;
    final barKey = myProgress.toString();
    final barTimers = _groupData!.barTimers;
    final ts = barTimers[barKey];
    if (ts is DateTime) return ts;
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  bool get allCheckedIn {
    if (_groupData == null) return false;
    final allUids = _groupData!.members.keys.toList();
    return allUids.every((uid) => checkedInUids.contains(uid));
  }

  void _resetGroupState() {
    _isGroupMode = false;
    _groupCode = null;
    _groupData = null;
    _myUid = null;
    _groupSub?.cancel();
    _groupSub = null;
    _groupStream = null;
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    super.dispose();
  }
}
