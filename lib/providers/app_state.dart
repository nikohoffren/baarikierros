import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bar.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  int _currentBarIndex = 0;
  bool _isInProgress = false;
  int _remainingSeconds = 0;
  Position? _currentPosition;
  bool _isTimerActive = false;

  //! Testing mode: disables proximity check, set false for production
  bool testingMode = true;

  List<Bar> _barRoute = [];

  Timer? _timer;

  final AuthService _authService = AuthService();
  User? _user;
  bool _hasSubscription = false;

  AppState() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _hasSubscription = await _authService.getSubscriptionStatus(user.uid);
      } else {
        _hasSubscription = false;
      }
      notifyListeners();
    });
  }

  // Getters
  int get currentBarIndex => _currentBarIndex;
  bool get isInProgress => _isInProgress;
  int get remainingSeconds => _remainingSeconds;
  Position? get currentPosition => _currentPosition;
  bool get isTimerActive => _isTimerActive;
  List<Bar> get barRoute => _barRoute;
  Bar? get currentBar => _currentBarIndex < _barRoute.length ? _barRoute[_currentBarIndex] : null;
  bool get isRouteCompleted => _currentBarIndex >= _barRoute.length;
  bool get isTestingMode => testingMode;
  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get hasSubscription => _hasSubscription;

  // Methods
  void setBarRoute(List<Bar> bars) {
    _barRoute = bars;
    _currentBarIndex = 0;
    _isInProgress = false;
    _isTimerActive = false;
    _remainingSeconds = 0;
    notifyListeners();
  }

  void setCurrentPosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  void startBarVisit({int durationSeconds = 15 * 60}) {
    _isInProgress = true;
    _remainingSeconds = durationSeconds;
    _isTimerActive = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        updateTimer(_remainingSeconds - 1);
      } else {
        timer.cancel();
      }
    });
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
    _timer?.cancel();
    _currentBarIndex++;
    notifyListeners();
  }

  void resetRoute() {
    _currentBarIndex = 0;
    _isInProgress = false;
    _isTimerActive = false;
    _remainingSeconds = 0;
    _timer?.cancel();
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      _hasSubscription = await _authService.getSubscriptionStatus(user.uid);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _hasSubscription = false;
    notifyListeners();
  }
}
