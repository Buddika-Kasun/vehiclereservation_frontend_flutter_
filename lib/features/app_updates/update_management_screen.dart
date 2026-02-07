import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/update_model.dart';

class UpdateManagementScreen extends StatefulWidget {
  const UpdateManagementScreen({super.key});

  @override
  State<UpdateManagementScreen> createState() => _UpdateManagementScreenState();
}

class _UpdateManagementScreenState extends State<UpdateManagementScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  List<AppUpdate> _updates = [];
  bool _isLoading = false;
  PlatformFile? _selectedFile;
  double _uploadProgress = 0.0;
  Uint8List? _fileBytes; // For web file storage

  // Form controllers
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _buildNumberController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _releaseNotesController = TextEditingController();
  String _selectedPlatform = 'android';
  bool _isMandatory = false;
  bool _isSilent = false;
  bool _redirectToStore = false;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get('/updates');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _updates = data.map((json) => AppUpdate.fromJson(json)).toList();
        });
      }
    } catch (e) {
      _showError('Failed to load updates: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk', 'ipa', 'zip'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          // Store bytes for web upload
          _fileBytes = _selectedFile!.bytes;
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _uploadUpdate() async {
    if (_selectedFile == null || _fileBytes == null) {
      _showError('Please select a file to upload');
      return;
    }

    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Create FormData using FormData() constructor, not fromMap()
      final formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry('version', _versionController.text),
        MapEntry('buildNumber', _buildNumberController.text),
        MapEntry('platform', _selectedPlatform),
        MapEntry('updateTitle', _titleController.text),
        MapEntry('updateDescription', _descriptionController.text),
        MapEntry('isMandatory', _isMandatory.toString()),
        MapEntry('isSilent', _isSilent.toString()),
        MapEntry('redirectToStore', _redirectToStore.toString()),
        MapEntry('isActive', 'true'), // Always active by default
      ]);

      // Add optional fields
      if (_releaseNotesController.text.isNotEmpty) {
        formData.fields.add(
          MapEntry('releaseNotes', _releaseNotesController.text),
        );
      }

      // Add file - use the correct MIME type
      String? mimeType;
      if (_selectedFile!.name.toLowerCase().endsWith('.apk')) {
        mimeType = 'application/vnd.android.package-archive';
      } else if (_selectedFile!.name.toLowerCase().endsWith('.ipa')) {
        mimeType = 'application/octet-stream';
      } else if (_selectedFile!.name.toLowerCase().endsWith('.zip')) {
        mimeType = 'application/zip';
      }

      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            _fileBytes!,
            filename: _selectedFile!.name,
            contentType: mimeType != null ? DioMediaType.parse(mimeType) : null,
          ),
        ),
      );

      final response = await _dio.post(
        '/updates/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
          // Don't throw on 400, handle it manually
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
        onSendProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSuccess('Update uploaded successfully!');
        _resetForm();
        _loadUpdates();
      } else if (response.statusCode == 400) {
        // Handle validation errors
        final errorData = response.data;
        String errorMessage = 'Validation error';

        if (errorData is Map<String, dynamic>) {
          if (errorData['message'] != null) {
            if (errorData['message'] is List) {
              errorMessage = (errorData['message'] as List).join(', ');
            } else {
              errorMessage = errorData['message'].toString();
            }
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        }

        _showError(errorMessage);
      } else {
        _showError('Upload failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Upload failed';
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        }
      }

      _showError('$errorMessage (${e.response?.statusCode ?? 'No status'})');
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
  
  bool _validateForm() {
    if (_versionController.text.isEmpty) {
      _showError('Please enter version number');
      return false;
    }
    if (_buildNumberController.text.isEmpty) {
      _showError('Please enter build number');
      return false;
    }
    if (_titleController.text.isEmpty) {
      _showError('Please enter update title');
      return false;
    }
    return true;
  }

  void _resetForm() {
    _versionController.clear();
    _buildNumberController.clear();
    _titleController.clear();
    _descriptionController.clear();
    _releaseNotesController.clear();
    _selectedFile = null;
    _fileBytes = null;
    _selectedPlatform = 'android';
    _isMandatory = false;
    _isSilent = false;
    _redirectToStore = false;
  }

  Future<void> _deleteUpdate(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this update?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dio.delete('/updates/$id');
        _showSuccess('Update deleted successfully!');
        _loadUpdates();
      } catch (e) {
        _showError('Failed to delete: $e');
      }
    }
  }

  Future<void> _downloadUpdate(AppUpdate update) async {
    try {
      // Use the backend download endpoint
      final downloadUrl = '${ApiConfig.baseUrl}/updates/${update.id}/download';

      print('Downloading from: $downloadUrl');

      final url = Uri.parse(downloadUrl);

      // Check if we can launch the URL
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        _showSuccess('Download started!');
      } else {
        _showError('Could not launch download URL');
      }
    } catch (e) {
      _showError('Download failed: $e');
    }
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Update Management'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.white,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel - Form (Keep your original UI)
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              color: Colors.grey[50],
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create New Update',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFormField(
                        controller: _versionController,
                        label: 'Version (e.g., 2.0.0)',
                        icon: Icons.tag,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: _buildNumberController,
                        label: 'Build Number (e.g., 20)',
                        icon: Icons.numbers,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: _titleController,
                        label: 'Update Title',
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: _releaseNotesController,
                        label: 'Release Notes (Optional)',
                        icon: Icons.notes,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      // Platform Selection
                      DropdownButtonFormField<String>(
                        value: _selectedPlatform,
                        decoration: const InputDecoration(
                          labelText: 'Platform',
                          prefixIcon: Icon(Icons.devices),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'android',
                            child: Text('Android'),
                          ),
                          DropdownMenuItem(value: 'ios', child: Text('iOS')),
                          DropdownMenuItem(value: 'web', child: Text('Web')),
                          DropdownMenuItem(
                            value: 'both',
                            child: Text('Both (Android & iOS)'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedPlatform = value!);
                        },
                      ),
                      const SizedBox(height: 12),
                      // File Picker
                      InkWell(
                        onTap: _pickFile,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_upload, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFile?.name ?? 'Select App File',
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (_selectedFile != null)
                                Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              const Text(
                                'Supported: .apk, .ipa, .zip',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Options
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: const Text('Mandatory Update'),
                            subtitle: const Text(
                              'Users cannot skip this update',
                            ),
                            value: _isMandatory,
                            onChanged: (value) =>
                                setState(() => _isMandatory = value),
                          ),
                          SwitchListTile(
                            title: const Text('Silent Update'),
                            subtitle: const Text(
                              'Update automatically without user confirmation',
                            ),
                            value: _isSilent,
                            onChanged: (value) =>
                                setState(() => _isSilent = value),
                          ),
                          SwitchListTile(
                            title: const Text('Redirect to Store'),
                            subtitle: const Text(
                              'Redirect users to Play Store/App Store',
                            ),
                            value: _redirectToStore,
                            onChanged: (value) =>
                                setState(() => _redirectToStore = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Upload Progress
                      if (_uploadProgress > 0)
                        Column(
                          children: [
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      // Upload Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading || _selectedFile == null
                              ? null
                              : _uploadUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Upload Update'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right Panel - Updates List (Keep your original UI)
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Existing Updates',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _updates.isEmpty
                        ? const Center(
                            child: Text(
                              'No updates found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _updates.length,
                            itemBuilder: (context, index) {
                              final update = _updates[index];
                              return _buildUpdateCard(update);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildUpdateCard(AppUpdate update) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'v${update.version} (Build ${update.buildNumber})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Chip(
                      label: Text(update.platform.toUpperCase()),
                      backgroundColor: _getPlatformColor(update.platform),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (update.isMandatory)
                      const Chip(
                        label: Text('MANDATORY'),
                        backgroundColor: Colors.red,
                        labelStyle: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    if (update.isSilent)
                      const Chip(
                        label: Text('SILENT'),
                        backgroundColor: Colors.green,
                        labelStyle: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              update.updateTitle,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              update.updateDescription,
              style: const TextStyle(color: Colors.grey),
            ),
            if (update.fileSize > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'File Size: ${update.fileSize.toStringAsFixed(1)} MB',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Uploaded: ${_formatDate(update.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Download file
                        if (update.downloadUrl != null) {
                          _downloadUpdate(update);
                        } else {
                          _showError('No download URL available');
                        }
                      },
                      icon: const Icon(Icons.download, size: 20),
                      tooltip: 'Download',
                    ),
                    IconButton(
                      onPressed: () => _deleteUpdate(update.id),
                      icon: const Icon(Icons.delete, size: 20),
                      tooltip: 'Delete',
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'android':
        return Colors.green;
      case 'ios':
        return Colors.black;
      case 'web':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
