/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSRMService {
  static Future<List<LatLng>> getRoute(List<LatLng> points) async {
    if (points.length < 2) return [];

    final coords = points.map((e) => "${e.longitude},${e.latitude}").join(";");

    final url = Uri.parse(
      "http://router.project-osrm.org/route/v1/driving/$coords?"
      "overview=full&geometries=geojson",
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    final route = data["routes"][0]["geometry"]["coordinates"];
    return route.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
  }
}
*/

/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSRMService {
  static Future<List<LatLng>> getRoute(List<LatLng> points) async {
    if (points.length < 2) return [];

    try {
      // Convert points to string for URL
      final coordinates = points.map((p) => '${p.longitude},${p.latitude}').join(';');
      
      final proxyUrls = [
        'https://cors-anywhere.herokuapp.com/http://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson',
        'https://api.codetabs.com/v1/proxy?quest=http://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson',
        'http://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson',
      ];

      for (final url in proxyUrls) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'VehicleReservationApp/1.0',
              'Accept': 'application/json',
            },
          ).timeout(Duration(seconds: 15));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
              final geometry = data['routes'][0]['geometry'];
              if (geometry['type'] == 'LineString') {
                final coordinates = geometry['coordinates'] as List;
                // Convert from [lon, lat] to LatLng(lat, lon)
                return coordinates.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
              }
            }
          }
        } catch (e) {
          print('OSRM proxy failed: $e');
          continue;
        }
      }

      // If OSRM fails, return a straight line between points for development
      print('OSRM failed, returning straight line');
      return _getStraightLineRoute(points);
      
    } catch (e) {
      print('Error getting OSRM route: $e');
      return _getStraightLineRoute(points);
    }
  }

  static List<LatLng> _getStraightLineRoute(List<LatLng> points) {
    // Simple straight line interpolation for development
    List<LatLng> route = [];
    for (int i = 0; i < points.length - 1; i++) {
      route.add(points[i]);
      // Add some intermediate points for visualization
      final steps = 10;
      for (int j = 1; j < steps; j++) {
        final ratio = j / steps;
        final lat = points[i].latitude + (points[i + 1].latitude - points[i].latitude) * ratio;
        final lng = points[i].longitude + (points[i + 1].longitude - points[i].longitude) * ratio;
        route.add(LatLng(lat, lng));
      }
    }
    if (points.isNotEmpty) {
      route.add(points.last);
    }
    return route;
  }
}
*/

import 'package:latlong2/latlong.dart';
import 'api_service.dart';

class OSRMService {
  static Future<List<LatLng>> getRoute(List<LatLng> points) async {
    if (points.length < 2) return [];

    try {
      final coordinates = points.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude
      }).toList();

      final data = await ApiService.calculateRoute(coordinates);
      return _parseRouteResponse(data);
    } catch (e) {
      print('Error getting route from backend: $e');
      rethrow;
    }
  }

  static List<LatLng> _parseRouteResponse(Map<String, dynamic> data) {
    if (data['route'] is List) {
      final routeData = data['route'] as List;
      return routeData.map((point) => 
        LatLng(point['latitude'], point['longitude'])
      ).toList();
    } else if (data['coordinates'] is List) {
      final coordinates = data['coordinates'] as List;
      return coordinates.map((coord) => 
        LatLng(coord[1].toDouble(), coord[0].toDouble())
      ).toList();
    } else {
      throw Exception('Unexpected route format from backend: $data');
    }
  }
}
