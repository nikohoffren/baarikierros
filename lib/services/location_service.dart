import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static bool checkProximity(
    double userLat,
    double userLon,
    double barLat,
    double barLon, {
    double threshold = 50, // meters
  }) {
    double distance = Geolocator.distanceBetween(
      userLat,
      userLon,
      barLat,
      barLon,
    );
    return distance <= threshold;
  }

  static double calculateDistance(
    double userLat,
    double userLon,
    double barLat,
    double barLon,
  ) {
    return Geolocator.distanceBetween(
      userLat,
      userLon,
      barLat,
      barLon,
    );
  }

  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }
}
