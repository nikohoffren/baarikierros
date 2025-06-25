import 'package:baarikierros/models/bar.dart';
import 'package:baarikierros/models/city.dart';
import 'package:baarikierros/models/round.dart';

class AppData {
  static final List<City> cities = [
    const City(name: 'Kuopio'),
    const City(name: 'Helsinki'),
    const City(name: 'Tampere'),
    const City(name: 'Turku'),
    const City(name: 'Oulu'),
  ];

  static final Map<String, List<Round>> roundsByCity = {
    'Kuopio': [
      Round(
        name: 'Keskustan kierros',
        description: 'Classic tour of Kuopio city center pubs.',
        bars: [
          const Bar(
              name: 'Intro Social',
              lat: 62.8922,
              lon: 27.6782,
              description: 'Modern pub with a great atmosphere.'),
          const Bar(
              name: 'Malja',
              lat: 62.8911,
              lon: 27.6811,
              description: 'A cozy corner pub.'),
          const Bar(
              name: 'Albatrossi',
              lat: 62.8879,
              lon: 27.6798,
              description: 'A legendary local favorite.'),
        ],
      ),
      Round(
        name: 'Sataman rinki',
        description: 'Enjoy the views and brews around Kuopio harbor.',
        bars: [
          const Bar(
              name: 'Wanха Satama',
              lat: 62.8885,
              lon: 27.6881,
              description: 'Great views of the lake.'),
          const Bar(
              name: 'Sataman Helmi',
              lat: 62.8906,
              lon: 27.6918,
              description: 'A gem by the water.'),
          const Bar(
              name: 'King\'s Crown',
              lat: 62.8893,
              lon: 27.6835,
              description: 'Traditional pub feel.'),
        ],
      ),
    ],
    'Helsinki': [],
    'Tampere': [],
    'Turku': [],
    'Oulu': [],
  };
}
