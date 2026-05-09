// lib/features/trips/widgets/save_location_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';

class SaveLocationDialog extends StatefulWidget {
  final String address;
  final LatLng coordinates;
  final VoidCallback onSaved;

  const SaveLocationDialog({
    Key? key,
    required this.address,
    required this.coordinates,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<SaveLocationDialog> createState() => _SaveLocationDialogState();
}

class _SaveLocationDialogState extends State<SaveLocationDialog> {
  final _nameController = TextEditingController();
  String? _selectedLabel;
  bool _isFavorite = false;
  bool _isSaving = false;

  final List<String> _labels = [
    'Home',
    'Work',
    'Office',
    'School',
    'Gym',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.98,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.save_alt, color: Color(0xFFF9C80E), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Save Location',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Map Preview
              _buildMapPreview(),
              SizedBox(height: 16),

              // Address Card
              _buildAddressCard(),
              SizedBox(height: 20),

              // Location Name Input
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Location Name *',
                  hintText: 'e.g., Main Office, Client Site',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Label Selection
              Text(
                'Label (Optional)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _labels.map((label) {
                  return FilterChip(
                    label: Text(label),
                    selected: _selectedLabel == label,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLabel = selected ? label : null;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Color(0xFFF9C80E).withOpacity(0.3),
                    checkmarkColor: Color(0xFFF9C80E),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Favorite Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isFavorite,
                    onChanged: (value) {
                      setState(() {
                        _isFavorite = value ?? false;
                      });
                    },
                    activeColor: Color(0xFFF9C80E),
                  ),
                  Text('Add to favorites'),
                ],
              ),
              SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF9C80E),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text('Save'),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: widget.coordinates,
                initialZoom: 16,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.vehiclereservation',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.coordinates,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: Color(0xFFF9C80E),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Location indicator overlay
            /*
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Color(0xFFF9C80E), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Selected Location',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            */
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: Color(0xFFF9C80E), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.address,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.gps_fixed, size: 12, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      'Lat: ${widget.coordinates.latitude.toStringAsFixed(6)}, '
                      'Lng: ${widget.coordinates.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveLocation() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a location name')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await ApiService.createSavedLocation(
        name: _nameController.text.trim(),
        address: widget.address,
        latitude: widget.coordinates.latitude,
        longitude: widget.coordinates.longitude,
        label: _selectedLabel,
        isFavorite: _isFavorite,
      );

      if (response['success'] == true && mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location saved successfully!')));
      } else if (mounted) {
        throw Exception('Failed to save location');
      }
    } catch (e) {
      print('Error saving location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
