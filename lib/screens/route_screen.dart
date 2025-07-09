import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/app_state.dart';
import '../services/location_service.dart';
import '../widgets/bar_info_overlay.dart';
import '../widgets/timer_widget.dart';
import '../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../models/round.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:ui' as ui;

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

  //* Cache for custom marker icons
  final Map<String, BitmapDescriptor> _markerIconCache = {};

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
        _positionSubscription = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10))
            .listen((Position position) {
              if (mounted) {
                appState.setCurrentPosition(position);
                //* Do NOT update camera here!
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
      _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
    }
  }

  Future<BitmapDescriptor> _getCustomMarkerIcon(String barName, bool isCurrentBar, bool isCompleted) async {
    final cacheKey = '$barName-$isCurrentBar-$isCompleted';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }
    const double size = 120;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()
      ..color = isCompleted
          ? Colors.green
          : isCurrentBar
          ? Colors.yellow
          : Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2 - 10), 36, paint);
    final icon = Icons.local_bar;
    final textPainterIcon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontSize: 48, fontFamily: icon.fontFamily, color: Colors.white, package: icon.fontPackage),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterIcon.layout();
    textPainterIcon.paint(canvas, Offset((size - textPainterIcon.width) / 2, (size / 2 - 10) - textPainterIcon.height / 2));
    final textPainter = TextPainter(
      text: TextSpan(
        text: barName,
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.normal, color: Colors.black, backgroundColor: Colors.white),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    textPainter.layout(maxWidth: size - 8);
    final double textY = size - textPainter.height - 8;
    final double textX = (size - textPainter.width) / 2;
    final RRect textBg = RRect.fromRectAndRadius(
      Rect.fromLTWH(textX - 6, textY - 2, textPainter.width + 12, textPainter.height + 4),
      const Radius.circular(10),
    );
    canvas.drawRRect(textBg, Paint()..color = Colors.white);
    textPainter.paint(canvas, Offset(textX, textY));
    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    final descriptor = BitmapDescriptor.fromBytes(bytes);
    _markerIconCache[cacheKey] = descriptor;
    return descriptor;
  }

  void _updateMarkers() async {
    final appState = context.read<AppState>();
    final barRoute = appState.barRoute;
    final currentBarIndex = appState.currentBarIndex;
    if (_lastBarIndex == currentBarIndex && _markers.isNotEmpty) return;
    Set<Marker> markers = {};
    for (int i = 0; i < barRoute.length; i++) {
      final bar = barRoute[i];
      final isCurrentBar = i == currentBarIndex;
      final isCompleted = i < currentBarIndex;
      final icon = await _getCustomMarkerIcon(bar.name, isCurrentBar, isCompleted);
      markers.add(
        Marker(
          markerId: MarkerId('bar_$i'),
          position: LatLng(bar.lat, bar.lon),
          infoWindow: InfoWindow(title: bar.name, snippet: bar.description ?? ''),
          icon: icon,
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
        title: const Text('Virhe', style: TextStyle(color: AppTheme.accentGold)),
        content: Text(message, style: const TextStyle(color: AppTheme.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.accentGold)),
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
        title: Text(title, style: const TextStyle(color: AppTheme.accentGold)),
        content: Text(message, style: const TextStyle(color: AppTheme.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.accentGold)),
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
      bool isNearby =
          appState.isTestingMode ||
          LocationService.checkProximity(currentPosition.latitude, currentPosition.longitude, currentBar.lat, currentBar.lon, threshold: 50);
      if (isNearby) {
        appState.startBarVisit(durationSeconds: 60); //! 60 seconds for testing
        Flushbar(
          messageText: const Center(
            child: Text(
              'Ajastin käynnissä',
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
    //* Only update markers when bar/progress changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMarkers());
    final appState = Provider.of<AppState>(context, listen: false);
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (appState.currentPosition != null) {
                _updateMapCamera(appState.currentPosition!);
              }
            },
            initialCameraPosition: CameraPosition(target: LatLng(62.8926, 27.6785), zoom: 16),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onTap: (_) => FocusScope.of(context).unfocus(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.accentGold,
              child: const Icon(Icons.my_location, color: AppTheme.primaryBlack),
              onPressed: () {
                final pos = appState.currentPosition;
                if (pos != null && _mapController != null) {
                  _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
                }
              },
            ),
          ),
          Consumer<AppState>(
            builder: (context, appState, child) {
              //* Show congratulation snackbar when timer ends, but not after the last bar
              if (!appState.isInProgress && appState.remainingSeconds == 0 && appState.currentBarIndex > 0 && !appState.isRouteCompleted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Flushbar(
                    messageText: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.celebration, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                'Onnittelut, voit siirtyä kohti seuraavaa baaria!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 3
                                    ..color = Colors.black,
                                ),
                              ),
                              const Text(
                                'Onnittelut, voit siirtyä kohti seuraavaa baaria!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    backgroundGradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    margin: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    duration: const Duration(seconds: 5),
                    flushbarPosition: FlushbarPosition.TOP,
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
                  Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBlack.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_bar, color: AppTheme.accentGold, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Baari ${appState.currentBarIndex + 1}/${appState.barRoute.length}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.white),
                                ),
                                if (appState.barRoute.isNotEmpty)
                                  LinearProgressIndicator(
                                    value: (appState.currentBarIndex + 1) / appState.barRoute.length,
                                    backgroundColor: AppTheme.grey.withOpacity(0.3),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                                  )
                                else
                                  LinearProgressIndicator(
                                    value: 0.0,
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
                  Selector<AppState, int>(
                    selector: (_, state) => state.remainingSeconds,
                    builder: (context, remainingSeconds, child) {
                      final isActive = context.select((AppState s) => s.isTimerActive);
                      if (!isActive) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 100, left: 16, right: 16),
                        child: TimerWidget(
                          remainingSeconds: remainingSeconds,
                          isActive: isActive,
                          currentBar: context.read<AppState>().currentBar!,
                          currentBarIndex: context.read<AppState>().currentBarIndex,
                          totalBars: context.read<AppState>().barRoute.length,
                        ),
                      );
                    },
                  ),
                  if (!appState.isInProgress && appState.currentBar != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, left: 16, right: 16),
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(color: AppTheme.secondaryBlack.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
              child: TextButton.icon(
                onPressed: () async {
                  final shouldQuit = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.secondaryBlack,
                      title: const Text('Lopeta kierros', style: TextStyle(color: AppTheme.accentGold)),
                      content: const Text('Oletko varma että haluat lopettaa kierroksen?', style: TextStyle(color: AppTheme.white)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Peruuta', style: TextStyle(color: AppTheme.lightGrey)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Lopeta', style: TextStyle(color: AppTheme.accentGold)),
                        ),
                      ],
                    ),
                  );
                  if (shouldQuit == true) {
                    context.read<AppState>().resetRoute();
                    if (context.mounted) context.go('/');
                  }
                },
                icon: const Icon(Icons.close, color: AppTheme.accentGold),
                label: const Text(
                  'Lopeta kierros',
                  style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentGold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
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
                    boxShadow: [BoxShadow(color: AppTheme.accentGold.withOpacity(0.3), blurRadius: 30, spreadRadius: 10)],
                  ),
                  child: const Icon(Icons.celebration, size: 60, color: AppTheme.primaryBlack),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Kierros suoritettu! 🎉',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Olet käynyt kaikissa baareissa!',
                  style: TextStyle(fontSize: 18, color: AppTheme.lightGrey),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Aloita uusi kierros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton(
                    onPressed: () => context.go('/'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentGold,
                      side: const BorderSide(color: AppTheme.accentGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Palaa alkuun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
