// lib/features/trips/models/saved_location.dart
import 'package:latlong2/latlong.dart';

class SavedLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? label; // 'Home', 'Work', 'Office', etc.
  final bool isFavorite;
  final double useCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.label,
    this.isFavorite = false,
    this.useCount = 0,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    }
    
    return SavedLocation(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      label: json['label'],
      isFavorite: json['isFavorite'] ?? false,
      useCount: parseDouble(json['useCount']),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
      'useCount': useCount,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'isFavorite': isFavorite,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  LatLng get coordinates => LatLng(latitude, longitude);
}
