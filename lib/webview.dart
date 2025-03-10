import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebViewPage extends StatefulWidget {
  final String title;
  final String address;
  final String username;
  final String password;

  const WebViewPage(
      {super.key,
      required this.title,
      required this.address,
      required this.username,
      required this.password});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? webViewController;

  InAppWebViewSettings settings = InAppWebViewSettings(
      transparentBackground: true,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW);

  String url = "";

  double progress = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "刷新",
              onPressed: () {
                webViewController?.loadUrl(
                    urlRequest: URLRequest(url: WebUri(widget.address)));
              }),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.address)),
            initialSettings: settings,
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStop: (controller, url) async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();

              // 自动登录
              if (url!.path.contains('/cas/login') &&
                  prefs.getBool('auto_login') == true) {
                await webViewController?.evaluateJavascript(
                    source:
                        'javascript:fm1.username.value="${widget.username}";fm1.password.value="${widget.password}";fm1.passbutton.click()');
              }
            },
          ),
        ],
      ),
    );
  }
}
