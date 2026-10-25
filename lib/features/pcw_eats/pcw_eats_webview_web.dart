// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

Widget buildPcwEatsView({required String url, required String token}) {
  return _WebEatsIframe(url: url, token: token);
}

class _WebEatsIframe extends StatefulWidget {
  final String url;
  final String token;
  const _WebEatsIframe({required this.url, required this.token});

  @override
  State<_WebEatsIframe> createState() => _WebEatsIframeState();
}

class _WebEatsIframeState extends State<_WebEatsIframe> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'pcw-eats-iframe-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int _) {
      final src = Uri.parse(
        widget.url,
      ).replace(queryParameters: {'token': widget.token}).toString();

      final iframe = html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.position = 'absolute' 
        ..allow = 'clipboard-read; clipboard-write; fullscreen';

      iframe.setAttribute('width', '100%');
      iframe.setAttribute('height', '100%');

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: SizedBox.expand(child: HtmlElementView(viewType: _viewId)),
    );
  }
}
