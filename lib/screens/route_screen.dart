import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/app_state.dart';
import '../services/location_service.dart';
import '../services/timer_service.dart';
import '../widgets/bar_info_overlay.dart';
import '../widgets/timer_widget.dart';
import '../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../models/round.dart';
import 'package:another_flushbar/flushbar.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  Set<Marker> _markers = {};
  int _lastBarIndex = -1;
  bool _didSetBarRoute = false;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
    _updateMarkers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSetBarRoute) {
      final round = GoRouter.of(context).routerDelegate.currentConfiguration?.extra;
      if (round is Round) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AppState>().setBarRoute(round.bars);
        });
      }
      _didSetBarRoute = true;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeLocationTracking() async {
    try {
      bool hasPermission = await LocationService.requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          _showErrorDialog('Sijaintilupa vaaditaan sovelluksen toimimiseksi.');
        }
        return;
      }
      Position position = await LocationService.getCurrentPosition();
      if (mounted) {
        final appState = context.read<AppState>();
        appState.setCurrentPosition(position);
        _updateMapCamera(position);
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            appState.setCurrentPosition(position);
            // Do NOT update camera here!
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Virhe sijainnin haussa: $e');
      }
    }
  }

  void _updateMapCamera(Position position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }

  void _updateMarkers() {
    final appState = context.read<AppState>();
    final barRoute = appState.barRoute;
    final currentBarIndex = appState.currentBarIndex;
    if (_lastBarIndex == currentBarIndex && _markers.isNotEmpty) return;
    Set<Marker> markers = {};
    for (int i = 0; i < barRoute.length; i++) {
      final bar = barRoute[i];
      final isCurrentBar = i == currentBarIndex;
      final isCompleted = i < currentBarIndex;
      markers.add(
        Marker(
          markerId: MarkerId('bar_$i'),
          position: LatLng(bar.lat, bar.lon),
          infoWindow: InfoWindow(
            title: bar.name,
            snippet: bar.description ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isCompleted
                ? BitmapDescriptor.hueGreen
                : isCurrentBar
                    ? BitmapDescriptor.hueYellow
                    : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }
    setState(() {
      _markers = markers;
      _lastBarIndex = currentBarIndex;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text(
          'Virhe',
          style: TextStyle(color: AppTheme.accentGold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppTheme.accentGold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text(
          title,
          style: const TextStyle(color: AppTheme.accentGold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppTheme.accentGold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEnterBar() async {
    final appState = context.read<AppState>();
    final currentBar = appState.currentBar;
    final currentPosition = appState.currentPosition;
    if (currentBar == null || currentPosition == null) {
      _showErrorDialog('Sijaintitietoja ei saatavilla');
      return;
    }
    try {
      bool isNearby = appState.isTestingMode || LocationService.checkProximity(
        currentPosition.latitude,
        currentPosition.longitude,
        currentBar.lat,
        currentBar.lon,
        threshold: 50,
      );
      if (isNearby) {
        appState.startBarVisit(durationSeconds: 60); // 60 seconds for testing
        Flushbar(
          messageText: const Center(
            child: Text(
              'Ajastin käynnistyy...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: AppTheme.secondaryBlack,
          borderRadius: BorderRadius.circular(16),
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          duration: const Duration(seconds: 5),
          flushbarPosition: FlushbarPosition.BOTTOM,
          animationDuration: const Duration(milliseconds: 700),
          forwardAnimationCurve: Curves.elasticOut,
          reverseAnimationCurve: Curves.easeIn,
        ).show(context);
        _updateMarkers();
      } else {
        _showErrorDialog('📍 Et ole tarpeeksi lähellä baaria');
      }
    } catch (e) {
      _showErrorDialog('Virhe: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only update markers when bar/progress changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMarkers());
    final appState = Provider.of<AppState>(context, listen: false);
    return Scaffold(
      body: Stack(
        children: [
          // GoogleMap OUTSIDE of Consumer!
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (appState.currentPosition != null) {
                _updateMapCamera(appState.currentPosition!);
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(62.8926, 27.6785),
              zoom: 16,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onTap: (_) => FocusScope.of(context).unfocus(),
          ),
          // Center on me button (moved below top bar)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.accentGold,
              child: const Icon(Icons.my_location, color: AppTheme.primaryBlack),
              onPressed: () {
                final pos = appState.currentPosition;
                if (pos != null && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(pos.latitude, pos.longitude),
                    ),
                  );
                }
              },
            ),
          ),
          // Overlays and timer use Consumer/Selector
          Consumer<AppState>(
            builder: (context, appState, child) {
              // Show congratulation snackbar when timer ends
              if (!appState.isInProgress && appState.remainingSeconds == 0 && appState.currentBarIndex > 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Flushbar(
                    messageText: const Center(
                      child: Text(
                        'Aika lopussa! Onnittelut, voit siirtyä kohti seuraavaa baaria.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    backgroundColor: AppTheme.secondaryBlack,
                    borderRadius: BorderRadius.circular(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    duration: const Duration(seconds: 5),
                    flushbarPosition: FlushbarPosition.BOTTOM,
                    animationDuration: const Duration(milliseconds: 700),
                    forwardAnimationCurve: Curves.elasticOut,
                    reverseAnimationCurve: Curves.easeIn,
                  ).show(context);
                });
              }
              if (appState.isRouteCompleted) {
                return _buildCompletionScreen();
              }
              return Column(
                children: [
                  // Top overlay with progress
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 16,
                      right: 16,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBlack.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accentGold.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_bar,
                            color: AppTheme.accentGold,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Baari ${appState.currentBarIndex + 1}/${appState.barRoute.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.white,
                                  ),
                                ),
                                LinearProgressIndicator(
                                  value: (appState.currentBarIndex + 1) / appState.barRoute.length,
                                  backgroundColor: AppTheme.grey.withOpacity(0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Timer overlay (when active)
                  Selector<AppState, int>(
                    selector: (_, state) => state.remainingSeconds,
                    builder: (context, remainingSeconds, child) {
                      final isActive = context.select((AppState s) => s.isTimerActive);
                      if (!isActive) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 100,
                          left: 16,
                          right: 16,
                        ),
                        child: TimerWidget(
                          remainingSeconds: remainingSeconds,
                          isActive: isActive,
                        ),
                      );
                    },
                  ),
                  // Bar info overlay
                  if (!appState.isInProgress && appState.currentBar != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 16,
                            left: 16,
                            right: 16,
                          ),
                          child: BarInfoOverlay(
                            bar: appState.currentBar!,
                            currentPosition: appState.currentPosition,
                            onEnterBar: _handleEnterBar,
                            isInProgress: appState.isInProgress,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.accentGold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 60,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Kierros suoritettu! 🎉',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Olet käynyt kaikissa baareissa!',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.lightGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AppState>().resetRoute();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Aloita uusi kierros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentGold,
                      side: const BorderSide(color: AppTheme.accentGold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Palaa alkuun',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
