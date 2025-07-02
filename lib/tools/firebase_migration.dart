import 'package:firebase_core/firebase_core.dart';
import '../services/firebase_service.dart';
import '../data/app_data.dart';
import '../models/city.dart';

class FirebaseMigration {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> migrateData() async {
    await Firebase.initializeApp();

    final citiesCollection = await _firebaseService._firestore.collection('cities').get();
    if (citiesCollection.docs.isEmpty) {
      print('Migrating cities...');
      for (var city in AppData.cities) {
        await _firebaseService._firestore.collection('cities').add({
          'name': city.name,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });
      }
      print('Cities migrated successfully!');
    }

    print('Migrating bars and routes...');
    for (var cityEntry in AppData.roundsByCity.entries) {
      final cityName = cityEntry.key;
      final rounds = cityEntry.value;

      for (var round in rounds) {
        final barIds = <String>[];
        for (var bar in round.bars) {
          final barId = await _firebaseService.addBar(bar);
          barIds.add(barId);
          print('Added bar: ${bar.name}');
        }

        final roundData = round.copyWith(
          bars: round.bars.asMap().entries.map((entry) {
            return entry.value.copyWith(
              id: barIds[entry.key],
            );
          }).toList(),
          city: cityName,
        );

        await _firebaseService.addRoute(roundData);
        print('Added round: ${round.name} for city: $cityName');
      }
    }

    print('Migration completed successfully!');
  }
}

void main() async {
  await Firebase.initializeApp();
  final migration = FirebaseMigration();
  await migration.migrateData();
}
