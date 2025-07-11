import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/bar.dart';
import '../models/round.dart';
import '../models/city.dart';
import '../models/group_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(String barId, File imageFile) async {
    final storageRef = _storage.ref().child('bars/$barId/images/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<List<City>> getCities() async {
    final snapshot = await _firestore.collection('cities').get();
    return snapshot.docs.map((doc) => City.fromJson({...doc.data(), 'id': doc.id})).toList();
  }

  Future<List<Round>> getRoundsByCity(String cityId) async {
    final cityRoundsRef = _firestore.collection('cities').doc(cityId).collection('rounds');
    final snapshot = await cityRoundsRef.get();

    List<Round> rounds = [];
    for (var doc in snapshot.docs) {
      Map<String, dynamic> roundData = {...doc.data(), 'id': doc.id};
      rounds.add(Round.fromJson(roundData));
    }

    return rounds;
  }

  Future<List<Bar>> getBarsByCity(String cityId) async {
    final snapshot = await _firestore.collection('cities').doc(cityId).collection('bars').get();

    return snapshot.docs.map((doc) => Bar.fromJson({...doc.data(), 'id': doc.id})).toList();
  }

  Future<Bar?> getBar(String cityId, String barId) async {
    final doc = await _firestore.collection('cities').doc(cityId).collection('bars').doc(barId).get();

    if (!doc.exists) return null;
    return Bar.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<String> createGroup(Round round, User user) async {
    final groupCode = _generateGroupCode();
    final now = DateTime.now();
    await _firestore.collection('groups').doc(groupCode).set({
      'routeId': round.id,
      'routeName': round.name,
      'bars': round.bars.map((b) => b.toJson()).toList(),
      'members': {
        user.uid: {'displayName': user.displayName ?? '', 'photoURL': user.photoURL, 'joinedAt': now, 'currentBarIndex': 0, 'lastActive': now},
      },
      'createdBy': user.uid,
      'createdAt': now,
      'started': false,
      'isActive': true,
    });
    return groupCode;
  }

  Future<void> joinGroup(String groupCode, User user) async {
    final doc = _firestore.collection('groups').doc(groupCode);
    final snap = await doc.get();
    if (!snap.exists) throw Exception('Group not found');
    final now = DateTime.now();
    await doc.update({
      'members.${user.uid}': {'displayName': user.displayName ?? '', 'photoURL': user.photoURL, 'joinedAt': now, 'currentBarIndex': 0, 'lastActive': now},
    });
  }

  Stream<GroupData> listenToGroup(String groupCode) {
    return _firestore.collection('groups').doc(groupCode).snapshots().map((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) throw Exception('Group not found');
      return GroupData.fromFirestore(groupCode, data);
    });
  }

  Future<void> updateGroupProgress(String groupCode, String uid, int barIndex) async {
    await _firestore.collection('groups').doc(groupCode).update({'members.$uid.currentBarIndex': barIndex, 'members.$uid.lastActive': DateTime.now()});
  }

  Future<void> leaveGroup(String groupCode, String uid) async {
    await _firestore.collection('groups').doc(groupCode).update({'members.$uid': FieldValue.delete()});
  }

  String _generateGroupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    final code = List.generate(6, (i) => chars[(rand >> (i * 5)) % chars.length]).join();
    return code;
  }

  Future<void> startGroup(String groupCode) async {
    await _firestore.collection('groups').doc(groupCode).update({'started': true});
  }

  Future<void> checkInToBar(String groupCode, String uid, int barIndex, List<String> allMemberUids) async {
    final doc = _firestore.collection('groups').doc(groupCode);
    final snap = await doc.get();
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;
    final checkIns = Map<String, dynamic>.from(data['checkIns'] ?? {});
    final barKey = barIndex.toString();
    final List<dynamic> checkedIn = List<dynamic>.from(checkIns[barKey] ?? []);
    if (!checkedIn.contains(uid)) {
      checkedIn.add(uid);
    }
    checkIns[barKey] = checkedIn;

    final allCheckedIn = allMemberUids.every((m) => checkedIn.contains(m));
    final Map<String, dynamic> updates = {'checkIns.$barKey': checkedIn};
    if (allCheckedIn) {
      updates['barTimers.$barKey'] = FieldValue.serverTimestamp();
    }
    await doc.update(updates);
  }

  Future<void> deleteGroup(String groupCode) async {
    await _firestore.collection('groups').doc(groupCode).delete();
  }
}
