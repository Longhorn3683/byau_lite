import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailCoursePage extends StatefulWidget {
  final bool webVPN;

  const FailCoursePage({super.key, required this.webVPN});

  @override
  State<FailCoursePage> createState() => _FailCoursePageState();
}

class _FailCoursePageState extends State<FailCoursePage> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
  }

  double progress = 0;
  String initialUrl = '';

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
              '挂了吗',
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
                        ? 'https://webvpn.byau.edu.cn/auth/login?returnUrl=https://http-10-255-255-130-80.webvpn.byau.edu.cn/jsxsd/'
                        : 'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2F10.1.4.41%2Fjsxsd%2F'))),
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
                          ? 'https://webvpn.byau.edu.cn/auth/login?returnUrl=https://http-10-255-255-130-80.webvpn.byau.edu.cn/jsxsd/'
                          : 'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2F10.1.4.41%2Fjsxsd%2F')),
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
                      // 教务系统主页
                      webViewController?.loadUrl(
                          urlRequest: URLRequest(
                              url: WebUri(widget.webVPN
                                  ? 'https://http-10-1-4-41-80.webvpn.byau.edu.cn/jsxsd/kscj/cjbjg_list'
                                  : 'http://10.1.4.41/jsxsd/kscj/cjbjg_list')));
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
