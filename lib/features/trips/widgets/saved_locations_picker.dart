// lib/features/trips/widgets/saved_locations_picker.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/nominatim_search_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/saved_location.dart';
import 'save_location_dialog.dart';

class SavedLocationsPicker extends StatefulWidget {
  final Function(SavedLocation) onLocationSelected;
  final String? currentAddress;
  final LatLng? currentCoordinates;

  const SavedLocationsPicker({
    Key? key,
    required this.onLocationSelected,
    this.currentAddress,
    this.currentCoordinates,
  }) : super(key: key);

  @override
  State<SavedLocationsPicker> createState() => _SavedLocationsPickerState();
}

class _SavedLocationsPickerState extends State<SavedLocationsPicker> {
  List<SavedLocation> _locations = [];
  bool _isLoading = true;
  bool _isGettingCurrentLocation = false;
  SavedLocation? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _getCurrentLocationAsSavedLocation();
  }

  Future<void> _getCurrentLocationAsSavedLocation() async {
    setState(() => _isGettingCurrentLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled');
        setState(() => _isGettingCurrentLocation = false);
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          print('Location permission denied');
          setState(() => _isGettingCurrentLocation = false);
          return;
        }
      }

      // Get current position
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Reverse geocode to get address
      final results = await NominatimService.reverseGeocode(
        pos.latitude,
        pos.longitude,
      );

      String address =
          results.isNotEmpty && results["data"]["display_name"] != null
          ? results["data"]["display_name"]
          : "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";

      // Create a special SavedLocation for current location
      _currentLocation = SavedLocation(
        id: (-1).toString(), // Special ID for current location
        name: 'Current Location',
        address: address,
        latitude: pos.latitude,
        longitude: pos.longitude,
        label: 'Live',
        isFavorite: false,
        useCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error getting current location: $e');
      _currentLocation = null;
    } finally {
      if (mounted) {
        setState(() => _isGettingCurrentLocation = false);
      }
    }
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllSavedLocations();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        setState(() {
          _locations = data.map((json) => SavedLocation.fromJson(json)).toList()
            ..sort((a, b) => b.useCount.compareTo(a.useCount));
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load saved locations'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLocation(SavedLocation location) async {
    try {
      final response = await ApiService.deleteSavedLocation(
        location.id.toString(),
      );
      if (response['success'] == true) {
        await _loadLocations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location deleted successfully')),
          );
        }
      }
    } catch (e) {
      print('Error deleting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCurrentLocation =
        _currentLocation != null && !_isGettingCurrentLocation;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.bookmark, color: Color(0xFFF9C80E)),
                SizedBox(width: 12),
                Text(
                  'Saved Locations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (widget.currentAddress != null &&
                    widget.currentCoordinates != null)
                  TextButton.icon(
                    onPressed: _showSaveDialog,
                    icon: Icon(Icons.save, size: 18),
                    label: Text('Save Selected'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFFF9C80E),
                    ),
                  ),
              ],
            ),
          ),
          // Locations List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _getItemCount(hasCurrentLocation),
                    itemBuilder: (context, index) {
                      // Show current location first if available
                      if (hasCurrentLocation && index == 0) {
                        return _buildCurrentLocationTile();
                      }

                      // Adjust index for saved locations
                      final locationIndex = hasCurrentLocation
                          ? index - 1
                          : index;
                      if (locationIndex < _locations.length) {
                        return _buildLocationTile(_locations[locationIndex]);
                      }

                      //return _buildEmptyState();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _getItemCount(bool hasCurrentLocation) {
    if (_locations.isEmpty && !hasCurrentLocation) return 1; // Empty state
    int count = _locations.length;
    if (hasCurrentLocation) count++;
    return count;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No saved locations yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          if (widget.currentAddress != null)
            TextButton(
              onPressed: _showSaveDialog,
              child: Text('Save current location'),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationTile() {
    if (_isGettingCurrentLocation) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Getting current location...'),
            ],
          ),
        ),
      );
    }

    if (_currentLocation == null) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Unable to get current location'),
              TextButton(
                onPressed: _getCurrentLocationAsSavedLocation,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFFF9C80E).withOpacity(0.2),
          child: Icon(Icons.my_location, color: Color(0xFFF9C80E), size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Current Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9C80E),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFFF9C80E).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9C80E),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 4),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'GPS Location',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _currentLocation!.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () {
          widget.onLocationSelected(_currentLocation!);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildLocationTile(SavedLocation location) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: location.label != null
            ? Color(0xFFF9C80E).withOpacity(0.2)
            : Colors.grey[200],
        child: Icon(
          _getLabelIcon(location.label),
          color: location.label != null ? Color(0xFFF9C80E) : Colors.grey[600],
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              location.name,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (location.isFavorite)
            Icon(Icons.star, color: Color(0xFFF9C80E), size: 16),
          if (location.useCount > 0)
            Container(
              margin: EdgeInsets.only(left: 8),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${location.useCount}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location.label != null)
            Container(
              margin: EdgeInsets.only(bottom: 4),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFFF9C80E).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                location.label!,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFF9C80E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            location.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: PopupMenuButton(
        icon: Icon(Icons.more_vert),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'favorite',
            child: Row(
              children: [
                Icon(
                  location.isFavorite ? Icons.star_border : Icons.star,
                  color: Color(0xFFF9C80E),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  location.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
        onSelected: (value) async {
          if (value == 'delete') {
            _confirmDelete(location);
          } else if (value == 'favorite') {
            await _toggleFavorite(location);
          }
        },
      ),
      onTap: () {
        widget.onLocationSelected(location);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _toggleFavorite(SavedLocation location) async {
    try {
      await ApiService.toggleFavorite(location.id.toString());
      await _loadLocations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              location.isFavorite
                  ? 'Removed from favorites'
                  : 'Added to favorites',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getLabelIcon(String? label) {
    switch (label) {
      case 'Home':
        return Icons.home;
      case 'Work':
        return Icons.work;
      case 'Office':
        return Icons.business;
      case 'School':
        return Icons.school;
      case 'Gym':
        return Icons.fitness_center;
      default:
        return Icons.location_on;
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => SaveLocationDialog(
        address: widget.currentAddress!,
        coordinates: widget.currentCoordinates!,
        onSaved: _loadLocations,
      ),
    );
  }

  void _confirmDelete(SavedLocation location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Location'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteLocation(location);
    }
  }
}
