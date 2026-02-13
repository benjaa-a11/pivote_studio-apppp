import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Simple wrapper for WebView to be used in VideoPlayerWidget
class HtmlPlayerWidget extends StatelessWidget {
  final WebViewController controller;

  const HtmlPlayerWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: WebViewWidget(controller: controller),
    );
  }
}
