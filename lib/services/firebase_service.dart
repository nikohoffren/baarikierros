import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/bar.dart';
import '../models/round.dart';
import '../models/city.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload an image to Firebase Storage
  Future<String> uploadImage(String barId, File imageFile) async {
    final storageRef = _storage.ref().child('bars/$barId/images/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Fetch all cities
  Future<List<City>> getCities() async {
    final snapshot = await _firestore.collection('cities').get();
    return snapshot.docs.map((doc) => City.fromJson({...doc.data(), 'id': doc.id})).toList();
  }

  // Fetch rounds for a specific city
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

  // Get all bars for a specific city
  Future<List<Bar>> getBarsByCity(String cityId) async {
    final snapshot = await _firestore
        .collection('cities')
        .doc(cityId)
        .collection('bars')
        .get();

    return snapshot.docs
        .map((doc) => Bar.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Get a specific bar by ID
  Future<Bar?> getBar(String cityId, String barId) async {
    final doc = await _firestore
        .collection('cities')
        .doc(cityId)
        .collection('bars')
        .doc(barId)
        .get();

    if (!doc.exists) return null;
    return Bar.fromJson({...doc.data()!, 'id': doc.id});
  }
}
