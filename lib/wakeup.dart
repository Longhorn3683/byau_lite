import 'package:flutter/material.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WakeUpPage extends StatefulWidget {
  final String address;
  final bool webVPN;

  const WakeUpPage({super.key, required this.address, required this.webVPN});

  @override
  State<WakeUpPage> createState() => _WakeUpPageState();
}

class _WakeUpPageState extends State<WakeUpPage> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
  }

  double progress = 0;
  String initialUrl = '';
  String className = '';
  String csvString = '';

  @override
  Widget build(BuildContext context) {
    bool retry = false;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '导出课表',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              initialUrl,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "刷新",
            onPressed: () => webViewController?.loadUrl(
                urlRequest: URLRequest(
                    url: WebUri(widget.webVPN
                        ? 'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2F10.1.4.41%2Fjsxsd%2F'
                        : 'https://webvpn.byau.edu.cn/auth/login?returnUrl=https://http-10-255-255-130-80.webvpn.byau.edu.cn/jsxsd/'))),
          ),
        ],
      ),
      body: SafeArea(
          child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(
                      url: WebUri(widget.webVPN
                          ? 'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2F10.1.4.41%2Fjsxsd%2F'
                          : 'https://webvpn.byau.edu.cn/auth/login?returnUrl=https://http-10-255-255-130-80.webvpn.byau.edu.cn/jsxsd/')),
                  initialSettings:
                      InAppWebViewSettings(useHybridComposition: false),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      initialUrl = url.toString();
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {}
                    setState(() {
                      this.progress = progress / 100;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    setState(() {
                      initialUrl = url.toString();
                    });
                    if (url!.path.contains('/cas/login')) {
                      // 登录页面
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
                    } else if (url.path
                        .contains('/jsxsd/framework/xsMain.jsp')) {
                      await webViewController?.evaluateJavascript(source: '''
                        var iframeWindow = window.document.getElementById("Frame0").contentWindow;
                        info(iframeWindow.document.getElementsByClassName("middletopdwxxcont"));
                        function info(array){
                           for(var i=0; i<array.length; i++) {
                                console.log(array[i].innerText);
                            }
                        };''');
                      webViewController?.loadUrl(
                          urlRequest: URLRequest(url: WebUri(widget.address)));
                    }

                    // 加载课表提取脚本
                    if (url.path.contains('/jsxsd/kbcx/kbxx_xzb')) {
                      await webViewController?.evaluateJavascript(source: '''
                        var classInput = document.getElementById("skbj");
                        classInput.value='$className';
                        ''');
                      await controller.injectJavascriptFileFromAsset(
                          assetFilePath: "assets/wakeup.js");
                    }
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    if (initialUrl.contains('/jsxsd/framework/xsMain.jsp')) {
                      className = consoleMessage.message;
                    } else if (initialUrl.contains('/jsxsd/kbcx/kbxx_xzb') &&
                        consoleMessage.message
                            .contains('课程名称,星期,开始节数,结束节数,老师,地点,周数')) {
                      csvString = '';
                      csvString = consoleMessage.message.replaceAll(' ', '\n');
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                                title: const Text('课表信息'),
                                content: SizedBox(
                                  width: 300,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      Text(csvString),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('取消'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('保存'),
                                    onPressed: () =>
                                        FlutterFileSaver().writeFileAsString(
                                      fileName: '导出课表.csv',
                                      data: csvString,
                                    ),
                                  ),
                                ]);
                          });
                    }
                  },
                ),
                progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container(),
              ],
            ),
          )
        ],
      )),
    );
  }
}
