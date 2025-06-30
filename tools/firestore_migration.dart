import 'dart:io';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:firebase_admin/src/credential.dart';
import 'package:firebase_admin/src/firestore.dart';
import 'package:firebase_admin/src/exception.dart';

Future<void> main() async {
  // IMPORTANT: Make sure you have the 'serviceAccountKey.json' in the 'tools' directory.
  try {
    // Initialize Firebase Admin with your service account
    final app = FirebaseAdmin.instance.initializeApp(
      AppOptions(
        credential: ServiceAccountCredential.fromPath('tools/serviceAccountKey.json'),
        projectId: 'baarikierros-flutter-app' // Replace with your actual project ID
      ),
    );

    final firestore = app.firestore();
    print('Firebase Admin initialized successfully.');

    // 1. Find your city (e.g. Kuopio)
    final cityName = 'Kuopio';
    print('Searching for city: $cityName');
    final citiesSnap = await firestore.collection('cities').where('name', isEqualTo: cityName).get();

    if (citiesSnap.docs.isEmpty) {
      print('City "$cityName" not found! Please check the name and your Firestore data.');
      exit(1);
    }
    final cityDoc = citiesSnap.docs.first;
    final cityId = cityDoc.id;
    print('Found city "$cityName" with ID: $cityId');

    // 2. Get all bars from the top-level 'bars' collection
    print("Fetching bars from the top-level 'bars' collection...");
    final barsSnap = await firestore.collection('bars').get();
    if (barsSnap.docs.isEmpty) {
      print('No bars found in top-level bars collection. Nothing to migrate.');
      exit(0);
    }
    print('Found ${barsSnap.docs.length} bars to migrate.');

    // 3. Move each bar to cities/{cityId}/bars
    final barIds = <String>[];
    final batch = firestore.batch();

    for (final barDoc in barsSnap.docs) {
      final barData = barDoc.data();
      final newBarRef = firestore.collection('cities').doc(cityId).collection('bars').doc(barDoc.id);
      batch.set(newBarRef, barData); // Use a batch for efficiency
      barIds.add(barDoc.id);
    }
    await batch.commit();
    print('Successfully moved ${barIds.length} bars to subcollection in city "$cityName".');

    // 4. Create a round under the city referencing all bar IDs
    print('Creating a new round...');
    final roundData = {
      'name': 'Kuopion Klassikkokierros',
      'description': 'Kierrä Kuopion suosituimmat baarit tässä legendaarisessa pubirundissa!',
      'bars': barIds,
      'cityId': cityId, // Add cityId for consistency
      'createdAt': FieldValue.serverTimestamp(),
      'isPublic': true,
      'minutesPerBar': 30,
      'estimatedDuration': 'Noin 3 tuntia',
    };
    final roundRef = firestore.collection('cities').doc(cityId).collection('rounds').doc();
    await roundRef.set(roundData);
    print('Successfully created round "${roundData['name']}" with ${barIds.length} bars.');

    print('\nMigration complete!');
    print('You should now see the bars and a round under the Kuopio city document in Firestore.');
    exit(0);

  } on FirebaseAdminException catch (e) {
    print('Firebase Admin Error: ${e.code} - ${e.message}');
    if (e.code == 'app/invalid-credential') {
      print("Please ensure 'tools/serviceAccountKey.json' exists and is valid.");
    }
    exit(1);
  } catch (e) {
    print('An unexpected error occurred: $e');
    exit(1);
  }
}
