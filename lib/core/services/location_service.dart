import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      return false;
    }

    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkLocationPermission();

      if (!hasPermission) {
        return null;
      }

      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        // Handle location service disabled
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  static Future<Stream<Position>?> getLocationStream() async {
    bool hasPermission = await checkLocationPermission();

    if (!hasPermission) {
      return null;
    }

    return Geolocator.getPositionStream(
      //desiredAccuracy: LocationAccuracy.high,
      //distanceFilter: 10, // Update every 10 meters
    );
  }
}
