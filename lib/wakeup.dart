import 'dart:io';

import 'package:byau/launch_in_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

class WakeUpPage extends StatefulWidget {
  final String address;

  const WakeUpPage({super.key, required this.address});

  @override
  State<WakeUpPage> createState() => _WakeUpPageState();
}

class _WakeUpPageState extends State<WakeUpPage> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('导出课表'),
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
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            initialSettings: InAppWebViewSettings(useOnDownloadStart: true),
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

              // 自动跳转课表查询
              if (url!.path.contains('/jsxsd/framework/xsMain.jsp') &&
                  username.isNotEmpty &&
                  password.isNotEmpty) {
                String newAddress = widget.address.replaceAll(
                    '/jsxsd/framework/xsMain.jsp', '/jsxsd/kbcx/kbxx_xzb');
                await webViewController?.loadUrl(
                    urlRequest: URLRequest(url: WebUri(newAddress)));
              }

              if (url!.path.contains('/jsxsd/kbcx/kbxx_xzb') &&
                  username.isNotEmpty &&
                  password.isNotEmpty) {
                String script =
                    await rootBundle.loadString("assets/export_script.js");
                await webViewController?.evaluateJavascript(source: script);
              }
            },
            onDownloadStartRequest: (controller, url) async {
              print("onDownloadStart ${url.url.path}");
              Directory? directory = await getExternalStorageDirectory();
              final taskId = await FlutterDownloader.enqueue(
                url: url.url.path,
                savedDir: directory!.path,
                showNotification:
                    true, // show download progress in status bar (for Android)
                openFileFromNotification:
                    true, // click on notification to open downloaded file (for Android)
              );
            },
          ),
        ],
      ),
    );
  }
}
