import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget buildPcwEatsView({required String url, required String token}) {
  return _MobileEatsWebView(url: url, token: token);
}

class _MobileEatsWebView extends StatefulWidget {
  final String url;
  final String token;
  const _MobileEatsWebView({required this.url, required this.token});

  @override
  State<_MobileEatsWebView> createState() => _MobileEatsWebViewState();
}

class _MobileEatsWebViewState extends State<_MobileEatsWebView> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(
          'PcwRideBridge',
          onMessageReceived: (m) => debugPrint('Bridge: ${m.message}'),
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _loading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (e) {
              debugPrint('WebView error: ${e.description} (${e.errorCode})');
              if (mounted) setState(() => _loading = false);
            },
            onNavigationRequest: (req) {
              if (req.url.startsWith('pcwride://')) {
                // TODO: parse and route to native screen
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );

      await controller.loadRequest(
        Uri.parse(widget.url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'X-Client': 'pcw-ride-app',
        },
      );

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Init WebView failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  _init();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}
