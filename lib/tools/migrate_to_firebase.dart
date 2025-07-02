import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firebase_service.dart';
import '../data/app_data.dart';
import '../models/city.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await migrateData();
}

Future<void> migrateData() async {
  final firebaseService = FirebaseService();

  print('Migrating cities...');
  final citiesCollection = await firebaseService.citiesCollection.get();
  if (citiesCollection.docs.isEmpty) {
    for (var city in AppData.cities) {
      await firebaseService.citiesCollection.add({
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
        final barId = await firebaseService.addBar(bar);
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

      await firebaseService.addRoute(roundData);
      print('Added round: ${round.name} for city: $cityName');
    }
  }

  print('Migration completed successfully!');
}
