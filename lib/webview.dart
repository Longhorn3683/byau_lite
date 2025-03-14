import 'dart:io';

import 'package:byau/launch_in_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

class WebViewPage extends StatefulWidget {
  final String title;
  final String address;

  const WebViewPage({super.key, required this.title, required this.address});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? webViewController;

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
              icon: const Icon(Icons.open_in_browser),
              tooltip: "在浏览器打开",
              onPressed: () {
                launchInBrowser(widget.address);
              }),
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
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStop: (controller, url) async {
              Directory? document = await getApplicationDocumentsDirectory();
              File usernameFile = File('${document.path}/username');
              File passwordFile = File('${document.path}/password');
              String username = usernameFile.readAsStringSync();
              String password = passwordFile.readAsStringSync();

              // 自动登录
              if (url!.path.contains('/cas/login') &&
                  username.isNotEmpty &&
                  password.isNotEmpty) {
                await webViewController?.evaluateJavascript(
                    source:
                        'javascript:fm1.username.value="$username";fm1.password.value="$password";fm1.passbutton.click()');
              }
            },
          ),
        ],
      ),
    );
  }
}
