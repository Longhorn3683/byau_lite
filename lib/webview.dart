import 'dart:convert';
import 'dart:io';

import 'package:byau/course.dart';
import 'package:byau/launch_in_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
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
                widget.title,
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
            MenuAnchor(
                builder: (BuildContext context, MenuController controller,
                    Widget? child) {
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
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.arrow_back),
                    child: const Text("后退"),
                    onPressed: () => webViewController?.goBack(),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.arrow_forward),
                    child: const Text("前进"),
                    onPressed: () => webViewController?.goForward(),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.refresh),
                    child: const Text("刷新"),
                    onPressed: () => webViewController?.loadUrl(
                        urlRequest: URLRequest(url: WebUri(initialUrl))),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.link),
                    child: const Text("复制链接"),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: initialUrl)),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.open_in_browser),
                    child: const Text("在浏览器打开"),
                    onPressed: () => launchInBrowser(widget.address),
                  ),
                ]),
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
                        useHybridComposition: false, useOnDownloadStart: true),
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
                      } else if (url.path.contains(
                          '_web/_lightapp/schedule/mobile/student/index.html')) {
                        Directory? document =
                            await getApplicationDocumentsDirectory();

                        // 课程表
                        String customCourse() {
                          Directory custom =
                              Directory('${document.path}/custom/');
                          if (custom.existsSync()) {
                            String script = '';
                            custom.listSync().forEach((e) {
                              File file = File(e.path);
                              String albumJson = file.readAsStringSync();
                              final jsonMap = json.decode(albumJson);
                              Course course = Course.fromJson(jsonMap);
                              getColor() {
                                return 'style="height: 96px;background-color: ${course.color}"';
                              }

                              String cell = '${course.week + course.time * 7}'
                                  .padLeft(2, '0');

                              script =
                                  """${script}array[$cell].innerHTML = '<div style="width: 100%;position: relative"><div class="contect-show clickc" ${getColor()}>${course.name}</div></div>';""";
                            });
                            return script;
                          } else {
                            return '';
                          }
                        }

                        await webViewController?.evaluateJavascript(source: """
                                // 自定义课表
                                var oldXHR = window.XMLHttpRequest;
                                function newXHR() {
                                    var realXHR = new oldXHR();
                                    realXHR.addEventListener('readystatechange', function() {
                                        if (realXHR.readyState == 4) {
                                            setTimeout(() => {
                                              custom(document.getElementsByTagName("td"));
                                              function custom(array){
                                                 ${customCourse()}
                                              };
                                            }, 0);
                                       }
                                   }, false);
                                    return realXHR;
                                }
                                window.XMLHttpRequest = newXHR;
                            """);
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
                                      Text(downloadStartRequest.url.toString())
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
                                      Clipboard.setData(ClipboardData(
                                          text: downloadStartRequest.url
                                              .toString()));
                                      Navigator.pop(context);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('在浏览器打开'),
                                    onPressed: () {
                                      launchInBrowser(initialUrl);
                                    },
                                  ),
                                ]);
                          });
                    },
                  ),
                  progress < 1.0
                      ? LinearProgressIndicator(value: progress)
                      : Container(),
                ],
              ),
            )
          ],
        )));
  }
}
