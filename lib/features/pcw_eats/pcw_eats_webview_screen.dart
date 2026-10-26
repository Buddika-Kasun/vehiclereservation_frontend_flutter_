import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

// Conditional import: picks the right implementation per platform.
import 'pcw_eats_webview_stub.dart'
    if (dart.library.io) 'pcw_eats_webview_mobile.dart'
    if (dart.library.html) 'pcw_eats_webview_web.dart';

class PcwEatsWebViewScreen extends StatefulWidget {
  final User? user;
  final String eatsUrl;
  const PcwEatsWebViewScreen({Key? key, required this.user, required this.eatsUrl}) : super(key: key);

  @override
  State<PcwEatsWebViewScreen> createState() => _PcwEatsWebViewScreenState();
}

class _PcwEatsWebViewScreenState extends State<PcwEatsWebViewScreen> {

  String? _token;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final token = await SecureStorageService().accessToken;
      if (!mounted) return;
      setState(() {
        _token = token;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Token load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('PCW EATS', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Failed to load PCW Eats'),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _loading = true;
                  });
                  _loadToken();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Delegates to platform-specific view
    return buildPcwEatsView(url: widget.eatsUrl, token: _token ?? '');
  }
}
