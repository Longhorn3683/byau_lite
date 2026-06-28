import 'package:byau/launch_in_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebViewPage extends StatefulWidget {
  final String title;
  final String address;
  final String campusNetAddress;

  const WebViewPage({
    super.key,
    required this.title,
    required this.address,
    required this.campusNetAddress,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
  }

  getPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('username') != null &&
        prefs.getString('username') != '') {
      return prefs.getString('username');
    }
  }

  bool webVPN = true;

  double progress = 0;
  String initialUrl = '';
  @override
  Widget build(BuildContext context) {
    bool retry = false;
    MenuController menuController = MenuController();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              initialUrl,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
            ),
          ],
        ),
        actions: [
          MenuAnchor(
            builder:
                (
                  BuildContext context,
                  MenuController controller,
                  Widget? child,
                ) {
                  menuController = controller;
                  return IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.more_vert),
                  );
                },
            menuChildren: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      webViewController?.goBack();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      webViewController?.goForward();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      webViewController?.loadUrl(
                        urlRequest: URLRequest(url: WebUri(initialUrl)),
                      );
                      menuController.close();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.link),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: initialUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('链接已复制'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                      menuController.close();
                    },
                  ),
                ],
              ),
              webVPNSwitch(),

              MenuItemButton(
                leadingIcon: const Icon(Icons.open_in_browser),
                child: const Text("在浏览器打开"),
                onPressed: () => launchInBrowser(initialUrl),
              ),
              failCourseButton(),
            ],
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
                    initialUrlRequest: URLRequest(url: WebUri(widget.address)),
                    initialSettings: InAppWebViewSettings(
                      useHybridComposition: false,
                      useOnDownloadStart: true,
                    ),
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        initialUrl = url.toString();
                      });
                      if (widget.title == '成绩查询' &&
                          (url!.path.contains('/cas/login') ||
                              url.path.contains('inquireScore'))) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            action: SnackBarAction(
                              label: '确定',
                              onPressed: () {},
                            ),
                            content: const Text('此为八一农大APP的成绩查询页面，数据更新比教务系统慢。'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
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
                        // 自动登录
                        final SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        if (prefs.getString('username') != null &&
                            prefs.getString('password') != null) {
                          // 有登录信息且未触发重试
                          if (retry == false) {
                            await controller.evaluateJavascript(
                              source:
                                  'javascript:fm1.username.value="${prefs.getString('username')}";fm1.password.value="${prefs.getString('password')}";fm1.passbutton.click()',
                            );
                            retry = true;
                          }
                        }
                      } else {
                        retry = false;
                      }
                    },
                    onDownloadStartRequest:
                        (controller, downloadStartRequest) async {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('下载文件'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      Text(downloadStartRequest.url.toString()),
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
                                    child: const Text('复制链接'),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: downloadStartRequest.url
                                              .toString(),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('在浏览器打开'),
                                    onPressed: () {
                                      launchInBrowser(initialUrl);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                  ),
                  progress < 1.0
                      ? LinearProgressIndicator(value: progress)
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget webVPNSwitch() {
    if (widget.campusNetAddress != '') {
      return StatefulBuilder(
        builder: (context, setState2) {
          return SwitchListTile(
            title: Text(
              'WebVPN',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            value: webVPN,
            onChanged: (bool value) {
              setState2(() {
                webVPN = value;
              });
              webViewController?.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri(
                    webVPN ? widget.address : widget.campusNetAddress,
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      return const SizedBox();
    }
  }

  failCourseButton() {
    if (widget.title == '教务系统') {
      return MenuItemButton(
        leadingIcon: const Icon(Icons.search_off),
        child: const Text("挂了吗？"),
        onPressed: () => showModalBottomSheet(
          context: context,
          enableDrag: false,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          builder: (context) {
            return InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(
                  webVPN
                      ? 'https://http-10-1-4-41-80.webvpn.byau.edu.cn/jsxsd/kscj/cjbjg_list'
                      : 'http://10.1.4.41/jsxsd/kscj/cjbjg_list',
                ),
              ),
              initialSettings: InAppWebViewSettings(
                useHybridComposition: false,
              ),
            );
          },
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
