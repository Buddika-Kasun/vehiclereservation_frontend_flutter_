/*
import 'package:latlong2/latlong.dart';

class GeoHelper {
  static LatLng jsonToLatLng(dynamic json) {
    return LatLng(
      double.parse(json['lat']),
      double.parse(json['lon']),
    );
  }
}
*/
import 'package:latlong2/latlong.dart';

class GeoHelper {
  static LatLng jsonToLatLng(dynamic json) {
    // Handle both Nominatim format and your backend format
    if (json['lat'] != null && json['lon'] != null) {
      return LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      );
    } else if (json['latitude'] != null && json['longitude'] != null) {
      return LatLng(
        json['latitude'].toDouble(),
        json['longitude'].toDouble(),
      );
    } else {
      throw Exception('Invalid location format: $json');
    }
  }
}