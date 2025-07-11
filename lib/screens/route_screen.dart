import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/app_state.dart';
import '../providers/group_state.dart';
import '../services/location_service.dart';
import '../widgets/bar_info_overlay.dart';
import '../widgets/timer_widget.dart';
import '../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../models/round.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:ui' as ui;
import '../models/bar.dart';

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
    final groupState = Provider.of<GroupState>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    if (!_didSetBarRoute) {
      if (groupState.isGroupMode && groupState.groupData != null) {
        final barsData = groupState.groupData!.bars;
        final bars = barsData.map<Bar>((b) => Bar.fromJson(Map<String, dynamic>.from(b))).toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState.setBarRoute(bars);
        });
        _didSetBarRoute = true;
      } else {
        final round = GoRouter.of(context).routerDelegate.currentConfiguration?.extra;
        if (round is Round) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appState.setBarRoute(round.bars);
          });
          _didSetBarRoute = true;
        }
      }
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

  Future<BitmapDescriptor> _getGroupMemberMarkerIcon(String name, bool isSelf) async {
    const double size = 90;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()
      ..color = isSelf ? Colors.blueAccent : Colors.grey[700]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 32, paint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: name.isNotEmpty ? name[0] : '?',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));
    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }

  void _updateMarkers() async {
    final appState = context.read<AppState>();
    final groupState = Provider.of<GroupState>(context, listen: false);
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

    if (groupState.isGroupMode && groupState.groupData != null) {
      for (final member in groupState.groupMembers) {
        final name = member['displayName'] as String? ?? '';
        final lat = member['lat'] as double?;
        final lon = member['lon'] as double?;
        final isSelf = member['uid'] == groupState.myUid;
        if (lat != null && lon != null) {
          final markerId = MarkerId('member_${name}_$lat$lon');
          final icon = await _getGroupMemberMarkerIcon(name, isSelf);
          markers.add(
            Marker(
              markerId: markerId,
              position: LatLng(lat, lon),
              icon: icon,
              infoWindow: InfoWindow(title: name, snippet: isSelf ? 'Sinä' : null),
              zIndex: isSelf ? 2 : 1,
            ),
          );
        }
      }
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
    final groupState = Provider.of<GroupState>(context, listen: false);
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
      if (!isNearby) {
        _showErrorDialog('📍 Et ole tarpeeksi lähellä baaria');
        return;
      }
      if (groupState.isGroupMode) {
        await groupState.checkInToBar(appState.currentBarIndex);
        Flushbar(
          messageText: const Center(
            child: Text(
              'Kirjauduttu baariin, odotetaan muita...',
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
      } else {
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
    final groupState = Provider.of<GroupState>(context);

    // --- DEBUG: Print group state at build ---
    debugPrint('RouteScreen build: isGroupMode=${groupState.isGroupMode}');
    debugPrint('RouteScreen build: groupData=${groupState.groupData}');
    if (groupState.groupData != null) {
      debugPrint('RouteScreen build: groupData.bars=${groupState.groupData!.bars}');
    }
    // --- END DEBUG ---

    if (groupState.isGroupMode && groupState.groupData != null && !_didSetBarRoute) {
      final barsData = groupState.groupData!.bars;
      debugPrint('Group mode: groupData.bars = $barsData');
      if (barsData.isNotEmpty) {
        final bars = barsData.map<Bar>((b) => Bar.fromJson(Map<String, dynamic>.from(b))).toList();
        appState.setBarRoute(bars);
        _didSetBarRoute = true;
        debugPrint('Group mode: setBarRoute called with ${bars.length} bars');
      } else {
        debugPrint('Group mode: barsData is empty, not calling setBarRoute');
      }
    }

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
            left: 16,
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            child: Consumer<AppState>(builder: (context, appState, _) => _buildTopBar(appState, groupState)),
          ),
          Consumer<AppState>(
            builder: (context, appState, child) {
              final groupState = Provider.of<GroupState>(context);
              final isGroupMode = groupState.isGroupMode;
              final barTimer = groupState.currentBarTimer;
              final checkedInUids = groupState.checkedInUids;
              final myUid = groupState.myUid;
              final hasCheckedIn = isGroupMode && myUid != null && checkedInUids.contains(myUid);
              final timerShouldStart = isGroupMode ? barTimer != null : appState.isTimerActive;
              final remainingSeconds = appState.remainingSeconds;
              final currentBar = appState.currentBar;
              final currentPosition = appState.currentPosition;

              if (currentBar != null && currentPosition != null && !timerShouldStart) {
                final isNearby =
                    appState.isTestingMode ||
                    LocationService.checkProximity(currentPosition.latitude, currentPosition.longitude, currentBar.lat, currentBar.lon, threshold: 50);
                if (isNearby) {
                  if (isGroupMode && !hasCheckedIn) {
                    groupState.checkInToBar(appState.currentBarIndex);
                  } else if (!isGroupMode && !appState.isTimerActive) {
                    appState.startBarVisit(durationSeconds: 60); //! or use a configured duration
                  }
                }
              }
              if (isGroupMode && barTimer != null && !appState.isTimerActive) {
                appState.startBarVisit(durationSeconds: 60); //! or use a group-configured duration
              }
              if (appState.isRouteCompleted) {
                return _buildCompletionScreen();
              }
              return Column(
                children: [
                  if (timerShouldStart)
                    Padding(
                      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 100, left: 16, right: 16),
                      child: TimerWidget(
                        remainingSeconds: remainingSeconds,
                        isActive: appState.isTimerActive,
                        currentBar: appState.currentBar!,
                        currentBarIndex: appState.currentBarIndex,
                        totalBars: appState.barRoute.length,
                      ),
                    ),
                  if (appState.currentBar != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, left: 16, right: 16),
                          child: BarInfoOverlay(
                            bar: appState.currentBar!,
                            currentPosition: appState.currentPosition,
                            isInProgress: timerShouldStart,
                            showWaiting: isGroupMode && hasCheckedIn && !timerShouldStart,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppState appState, GroupState groupState) {
    final currentBarIndex = appState.currentBarIndex;
    final totalBars = appState.barRoute.length;
    final barLabel = 'Baari ${currentBarIndex + 1}/$totalBars';
    return Card(
      color: AppTheme.secondaryBlack.withOpacity(0.98),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.local_bar, color: AppTheme.accentGold, size: 28),
                const SizedBox(width: 10),
                Text(
                  barLabel,
                  style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                ElevatedButton(
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
                      if (groupState.isGroupMode) {
                        await groupState.leaveGroup();
                      } else {
                        context.read<AppState>().resetRoute();
                      }
                      if (context.mounted) context.go('/');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.primaryBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    elevation: 0,
                  ),
                  child: const Text('Lopeta kierros'),
                ),
              ],
            ),
            if (groupState.isGroupMode && groupState.groupData != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: groupState.groupMembers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          final member = groupState.groupMembers[idx];
                          final name = member['displayName'] as String? ?? '';
                          final isSelf = member['uid'] == groupState.myUid;
                          final progress = member['currentBarIndex'] as int? ?? 0;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: isSelf ? 12 : 10,
                                backgroundColor: isSelf ? Colors.blueAccent : AppTheme.accentGold,
                                child: Text(
                                  name.isNotEmpty ? name[0] : '?',
                                  style: TextStyle(color: isSelf ? Colors.white : AppTheme.primaryBlack, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 0),
                              Text(
                                name,
                                style: TextStyle(
                                  color: isSelf ? Colors.blueAccent : AppTheme.accentGold,
                                  fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 9,
                                ),
                              ),
                              Text('B${progress + 1}', style: const TextStyle(color: AppTheme.lightGrey, fontSize: 8)),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: AppTheme.accentGold),
                    tooltip: 'Keskitä sijainti',
                    onPressed: () {
                      final pos = appState.currentPosition;
                      if (pos != null && _mapController != null) {
                        _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
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
                    onPressed: () async {
                      final groupState = context.read<GroupState>();
                      final appState = context.read<AppState>();
                      if (groupState.isGroupMode) {
                        await groupState.leaveGroup();
                      }
                      appState.resetRoute();
                      if (context.mounted) context.go('/');
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
