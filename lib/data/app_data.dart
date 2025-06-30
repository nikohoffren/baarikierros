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
        minutesPerBar: 30,
        bars: [
          const Bar(
              name: 'Intro Social',
              lat: 62.8922,
              lon: 27.6782,
              description: 'Modern pub with a great atmosphere.',
              openingHours: {
                'monday': [OpenPeriod(open: '14:00', close: '23:00')],
                'tuesday': [OpenPeriod(open: '14:00', close: '23:00')],
                'wednesday': [OpenPeriod(open: '14:00', close: '23:00')],
                'thursday': [OpenPeriod(open: '14:00', close: '23:00')],
                'friday': [OpenPeriod(open: '14:00', close: '02:00')],
                'saturday': [OpenPeriod(open: '12:00', close: '02:00')],
                'sunday': [OpenPeriod(open: '14:00', close: '22:00')],
              }),
          const Bar(
              name: 'Malja',
              lat: 62.8911,
              lon: 27.6811,
              description: 'A cozy corner pub.',
              openingHours: {
                'monday': [OpenPeriod(open: '15:00', close: '23:00')],
                'tuesday': [OpenPeriod(open: '15:00', close: '23:00')],
                'wednesday': [OpenPeriod(open: '15:00', close: '23:00')],
                'thursday': [OpenPeriod(open: '15:00', close: '23:00')],
                'friday': [OpenPeriod(open: '15:00', close: '02:00')],
                'saturday': [OpenPeriod(open: '13:00', close: '02:00')],
                'sunday': [OpenPeriod(open: '15:00', close: '22:00')],
              }),
          const Bar(
              name: 'Albatrossi',
              lat: 62.8879,
              lon: 27.6798,
              description: 'A legendary local favorite.',
              openingHours: {
                'monday': [OpenPeriod(open: '16:00', close: '23:00')],
                'tuesday': [OpenPeriod(open: '16:00', close: '23:00')],
                'wednesday': [OpenPeriod(open: '16:00', close: '23:00')],
                'thursday': [OpenPeriod(open: '16:00', close: '23:00')],
                'friday': [OpenPeriod(open: '16:00', close: '02:00')],
                'saturday': [OpenPeriod(open: '14:00', close: '02:00')],
                'sunday': [OpenPeriod(open: '16:00', close: '22:00')],
              }),
          const Bar(
              name: 'Apteekkari',
              lat: 62.8925,
              lon: 27.6777,
              description: 'Rooftop terrace and lively events.',
              openingHours: {
                'monday': [OpenPeriod(open: '14:00', close: '23:00')],
                'tuesday': [OpenPeriod(open: '14:00', close: '23:00')],
                'wednesday': [OpenPeriod(open: '14:00', close: '23:00')],
                'thursday': [OpenPeriod(open: '14:00', close: '23:00')],
                'friday': [OpenPeriod(open: '14:00', close: '02:00')],
                'saturday': [OpenPeriod(open: '12:00', close: '02:00')],
                'sunday': [OpenPeriod(open: '14:00', close: '22:00')],
              }),
          const Bar(
              name: 'Pannuhuone Gust. Ranin',
              lat: 62.8920,
              lon: 27.6772,
              description: 'Classic bar with a wide selection of drinks.',
              openingHours: {
                'monday': [OpenPeriod(open: '15:00', close: '23:00')],
                'tuesday': [OpenPeriod(open: '15:00', close: '23:00')],
                'wednesday': [OpenPeriod(open: '15:00', close: '23:00')],
                'thursday': [OpenPeriod(open: '15:00', close: '23:00')],
                'friday': [OpenPeriod(open: '15:00', close: '02:00')],
                'saturday': [OpenPeriod(open: '13:00', close: '02:00')],
                'sunday': [OpenPeriod(open: '15:00', close: '22:00')],
              }),
          const Bar(
              name: 'Bar Nousu',
              lat: 62.8927,
              lon: 27.6779,
              description: 'Popular nightclub and bar.',
              openingHours: {
                'monday': [OpenPeriod(open: '18:00', close: '02:00')],
                'tuesday': [OpenPeriod(open: '18:00', close: '02:00')],
                'wednesday': [OpenPeriod(open: '18:00', close: '02:00')],
                'thursday': [OpenPeriod(open: '18:00', close: '02:00')],
                'friday': [OpenPeriod(open: '18:00', close: '04:00')],
                'saturday': [OpenPeriod(open: '16:00', close: '04:00')],
                'sunday': [OpenPeriod(open: '18:00', close: '02:00')],
              }),
        ],
      ),
      Round(
        name: 'Sataman rinki',
        description: 'Enjoy the views and brews around Kuopio harbor.',
        minutesPerBar: 25,
        bars: [
          const Bar(
              name: 'Wanha Satama',
              lat: 62.8885,
              lon: 27.6881,
              description: 'Great views of the lake.',
              openingHours: {
                'monday': [OpenPeriod(open: '14:00', close: '22:00')],
                'tuesday': [OpenPeriod(open: '14:00', close: '22:00')],
                'wednesday': [OpenPeriod(open: '14:00', close: '22:00')],
                'thursday': [OpenPeriod(open: '14:00', close: '22:00')],
                'friday': [OpenPeriod(open: '14:00', close: '00:00')],
                'saturday': [OpenPeriod(open: '12:00', close: '00:00')],
                'sunday': [OpenPeriod(open: '14:00', close: '22:00')],
              }),
          const Bar(
              name: 'Sataman Helmi',
              lat: 62.8906,
              lon: 27.6918,
              description: 'A gem by the water.',
              openingHours: {
                'monday': [OpenPeriod(open: '15:00', close: '22:00')],
                'tuesday': [OpenPeriod(open: '15:00', close: '22:00')],
                'wednesday': [OpenPeriod(open: '15:00', close: '22:00')],
                'thursday': [OpenPeriod(open: '15:00', close: '22:00')],
                'friday': [OpenPeriod(open: '15:00', close: '00:00')],
                'saturday': [OpenPeriod(open: '13:00', close: '00:00')],
                'sunday': [OpenPeriod(open: '15:00', close: '22:00')],
              }),
          const Bar(
              name: "King's Crown",
              lat: 62.8893,
              lon: 27.6835,
              description: 'Traditional pub feel.',
              openingHours: {
                'monday': [OpenPeriod(open: '16:00', close: '23:00')],
                'tuesday': [OpenPeriod(open: '16:00', close: '23:00')],
                'wednesday': [OpenPeriod(open: '16:00', close: '23:00')],
                'thursday': [OpenPeriod(open: '16:00', close: '23:00')],
                'friday': [OpenPeriod(open: '16:00', close: '01:00')],
                'saturday': [OpenPeriod(open: '14:00', close: '01:00')],
                'sunday': [OpenPeriod(open: '16:00', close: '22:00')],
              }),
          const Bar(
              name: 'Cafe Satama',
              lat: 62.8897,
              lon: 27.6872,
              description: 'Relaxed café-bar by the harbor.',
              openingHours: {
                'monday': [OpenPeriod(open: '14:00', close: '21:00')],
                'tuesday': [OpenPeriod(open: '14:00', close: '21:00')],
                'wednesday': [OpenPeriod(open: '14:00', close: '21:00')],
                'thursday': [OpenPeriod(open: '14:00', close: '21:00')],
                'friday': [OpenPeriod(open: '14:00', close: '23:00')],
                'saturday': [OpenPeriod(open: '12:00', close: '23:00')],
                'sunday': [OpenPeriod(open: '14:00', close: '21:00')],
              }),
          const Bar(
              name: 'Boat House',
              lat: 62.8891,
              lon: 27.6902,
              description: 'Nautical-themed bar with terrace.',
              openingHours: {
                'monday': [OpenPeriod(open: '15:00', close: '22:00')],
                'tuesday': [OpenPeriod(open: '15:00', close: '22:00')],
                'wednesday': [OpenPeriod(open: '15:00', close: '22:00')],
                'thursday': [OpenPeriod(open: '15:00', close: '22:00')],
                'friday': [OpenPeriod(open: '15:00', close: '00:00')],
                'saturday': [OpenPeriod(open: '13:00', close: '00:00')],
                'sunday': [OpenPeriod(open: '15:00', close: '22:00')],
              }),
        ],
      ),
    ],
    'Helsinki': [],
    'Tampere': [],
    'Turku': [],
    'Oulu': [],
  };
}
