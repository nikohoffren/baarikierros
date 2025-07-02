import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bar.dart';
import '../models/city.dart';
import '../models/round.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class AppState extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  //* Auth state
  User? _user;
  bool _hasSubscription = false;
  bool get isSignedIn => _user != null;
  User? get user => _user;
  bool get hasSubscription => _hasSubscription;

  //* Location state
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  //* Route state
  List<Bar> _barRoute = [];
  int _currentBarIndex = 0;
  bool _isInProgress = false;
  bool _isRouteCompleted = false;
  int _remainingSeconds = 0;
  bool _isTimerActive = false;
  bool _isTestingMode = true; //! Set false for production

  //* Cities and rounds state
  List<City> _cities = [];
  Map<String, List<Round>> _roundsByCity = {};
  City? _selectedCity;
  bool _isLoadingRounds = false;

  Timer? _timer;

  List<Bar> get barRoute => _barRoute;
  int get currentBarIndex => _currentBarIndex;
  bool get isInProgress => _isInProgress;
  bool get isRouteCompleted => _isRouteCompleted;
  int get remainingSeconds => _remainingSeconds;
  bool get isTimerActive => _isTimerActive;
  bool get isTestingMode => _isTestingMode;
  Bar? get currentBar => _barRoute.isNotEmpty && _currentBarIndex < _barRoute.length ? _barRoute[_currentBarIndex] : null;
  List<City> get cities => _cities;
  Map<String, List<Round>> get roundsByCity => _roundsByCity;
  City? get selectedCity => _selectedCity;
  bool get isLoadingRounds => _isLoadingRounds;

  AppState() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      _hasSubscription = await _authService.getSubscriptionStatus(user.uid);
      _loadCities();
    } else {
      _hasSubscription = false;
      _cities = [];
      _roundsByCity = {};
      _selectedCity = null;
    }
    notifyListeners();
  }

  Future<void> _loadCities() async {
    try {
      _cities = await _firebaseService.getCities();
      if (_cities.isNotEmpty) {
        _selectedCity = _cities.first;
        await _loadRoundsForCity(_selectedCity!.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cities: $e');
    }
  }

  Future<void> _loadRoundsForCity(String cityId) async {
    _isLoadingRounds = true;
    notifyListeners();
    try {
      final rounds = await _firebaseService.getRoundsByCity(cityId);
      _roundsByCity[cityId] = rounds;
    } catch (e) {
      debugPrint('Error loading rounds for city $cityId: $e');
      _roundsByCity[cityId] = [];
    } finally {
      _isLoadingRounds = false;
      notifyListeners();
    }
  }

  void setSelectedCity(City city) {
    _selectedCity = city;
    if (!_roundsByCity.containsKey(city.id)) {
      _loadRoundsForCity(city.id);
    }
    notifyListeners();
  }

  void setCurrentPosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  void setBarRoute(List<Bar> bars) {
    _barRoute = bars;
    _currentBarIndex = 0;
    _isInProgress = false;
    _isRouteCompleted = false;
    _remainingSeconds = 0;
    _isTimerActive = false;
    notifyListeners();
  }

  void startBarVisit({required int durationSeconds}) {
    _isInProgress = true;
    _remainingSeconds = durationSeconds;
    _isTimerActive = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      updateTimer();
    });
    notifyListeners();
  }

  void updateTimer() {
    if (_remainingSeconds > 0 && _isTimerActive) {
      _remainingSeconds--;
      if (_remainingSeconds == 0) {
        _completeCurrentBar();
        _timer?.cancel();
      }
      notifyListeners();
    }
  }

  void _completeCurrentBar() {
    _isInProgress = false;
    _isTimerActive = false;
    _timer?.cancel();
    if (_currentBarIndex < _barRoute.length - 1) {
      _currentBarIndex++;
    } else {
      _isRouteCompleted = true;
    }
    notifyListeners();
  }

  void resetRoute() {
    _barRoute = [];
    _currentBarIndex = 0;
    _isInProgress = false;
    _isRouteCompleted = false;
    _remainingSeconds = 0;
    _isTimerActive = false;
    _timer?.cancel();
    notifyListeners();
  }

  void toggleTestingMode() {
    _isTestingMode = !_isTestingMode;
    notifyListeners();
  }

  //* Auth methods
  Future<void> signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}
