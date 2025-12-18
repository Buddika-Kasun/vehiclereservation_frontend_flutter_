/*
import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimService {
  static Future<List<dynamic>> search(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      
      // Try direct call to Nominatim - this should work if you run with CORS disabled
      final directUrl = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=10';
      
      final response = await http.get(
        Uri.parse(directUrl),
        headers: {
          'User-Agent': 'VehicleReservationApp/1.0 (your-app@example.com)',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        
        // Check if response is valid JSON
        if (responseBody.trim().isEmpty) {
          throw Exception('Empty response from Nominatim');
        }
        
        if (responseBody.startsWith('<!DOCTYPE') || 
            responseBody.startsWith('<html')) {
          throw Exception('Nominatim returned HTML error: ${responseBody.substring(0, 100)}');
        }

        final result = json.decode(responseBody);
        if (result is List) {
          print('Successfully found ${result.length} real results');
          return result;
        } else {
          throw Exception('Unexpected response format from Nominatim');
        }
      } else {
        throw Exception('Nominatim returned status: ${response.statusCode}');
      }
      
    } catch (e) {
      print('Error searching with Nominatim: $e');
      rethrow; // Re-throw the exception so calling code knows it failed
    }
  }
}
*/

import '../services/api_service.dart';

class NominatimService {
  static Future<List<dynamic>> search(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final result = await ApiService.searchLocations(query);
      return _parseBackendResponse(result);
    } catch (e) {
      print('Error searching with backend: $e');
      rethrow;
    }
  }

  static Future<dynamic> reverseGeocode(double lat, double lon) async {
    try {
      final result = await ApiService.reverseGeocode(lat, lon);
      return result;
    } catch (e) {
      print('Error reverse geocoding: $e');
      rethrow;
    }
  }
  
  static List<dynamic> _parseBackendResponse(dynamic result) {
    // Handle both List and Map responses
    if (result is List) {
      return result;
    } else if (result is Map<String, dynamic>) {
      if (result['data'] is List) return result['data'];
      if (result['results'] is List) return result['results'];
      if (result['locations'] is List) return result['locations'];
    }
    
    throw Exception('Unexpected backend response format: $result');
  }
}
