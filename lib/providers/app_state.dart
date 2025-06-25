import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bar.dart';

class AppState extends ChangeNotifier {
  int _currentBarIndex = 0;
  bool _isInProgress = false;
  int _remainingSeconds = 0;
  Position? _currentPosition;
  bool _isTimerActive = false;

  // Sample bar route - replace with actual bars in your area
  final List<Bar> _barRoute = [
    const Bar(
      name: 'Pub Keskusta',
      lat: 62.8926,
      lon: 27.6785,
      description: 'Klassinen keskustan pubi',
    ),
    const Bar(
      name: 'Karaoke Baari',
      lat: 62.8921,
      lon: 27.6769,
      description: 'Hauska karaoke-illat',
    ),
    const Bar(
      name: 'Cocktail Lounge',
      lat: 62.8915,
      lon: 27.6792,
      description: 'Tyylikkäät cocktailit',
    ),
    const Bar(
      name: 'Rock Bar',
      lat: 62.8930,
      lon: 27.6775,
      description: 'Rock-musiikkia ja hyvää tunnelmaa',
    ),
  ];

  // Getters
  int get currentBarIndex => _currentBarIndex;
  bool get isInProgress => _isInProgress;
  int get remainingSeconds => _remainingSeconds;
  Position? get currentPosition => _currentPosition;
  bool get isTimerActive => _isTimerActive;
  List<Bar> get barRoute => _barRoute;
  Bar? get currentBar => _currentBarIndex < _barRoute.length ? _barRoute[_currentBarIndex] : null;
  bool get isRouteCompleted => _currentBarIndex >= _barRoute.length;

  // Methods
  void setCurrentPosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  void startBarVisit() {
    _isInProgress = true;
    _remainingSeconds = 15 * 60; // 15 minutes
    _isTimerActive = true;
    notifyListeners();
  }

  void updateTimer(int seconds) {
    _remainingSeconds = seconds;
    if (seconds <= 0) {
      completeBarVisit();
    }
    notifyListeners();
  }

  void completeBarVisit() {
    _isInProgress = false;
    _isTimerActive = false;
    _currentBarIndex++;
    notifyListeners();
  }

  void resetRoute() {
    _currentBarIndex = 0;
    _isInProgress = false;
    _isTimerActive = false;
    _remainingSeconds = 0;
    notifyListeners();
  }
}
