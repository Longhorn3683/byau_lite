import 'package:byau/launch_in_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    bool retry = false;
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
              if (url!.path.contains('/cas/login')) {
                // 登录页面
                // 自动登录
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                if (prefs.getString('username') != null &&
                    prefs.getString('password') != null) {
                  // 有登录信息且未触发重试
                  if (retry == false) {
                    await controller.evaluateJavascript(
                        source:
                            'javascript:fm1.username.value="${prefs.getString('username')}";fm1.password.value="${prefs.getString('password')}";fm1.passbutton.click()');
                    retry = true;
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
