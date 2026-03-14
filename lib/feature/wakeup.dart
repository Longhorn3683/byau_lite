import 'dart:io';

import 'package:byau/launch_in_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void importWakeUp(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            content: SizedBox(
              width: 300,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                      'WakeUp课程表支持上课提醒、自定义课表等功能，可接入小布建议、YOYO建议、系统日程。\n若课表发生变化（如调课），需清空WakeUp课程表中的课程并重新导入。\n\n以下为导出课表步骤：'),
                  ListTile(
                      title: const Text('第一步'),
                      subtitle: const Text('下载WakeUp课程表'),
                      onTap: () => launchInBrowser('https://wakeup.fun/')),
                  ListTile(
                      title: const Text('第二步'),
                      subtitle: const Text('导入模板，选择WakeUp课程表'),
                      onTap: () async {
                        String string = await rootBundle.loadString(
                            'assets/wakeup_template.wakeup_schedule');
                        final directory =
                            await getApplicationDocumentsDirectory();
                        var file = File(
                            "${directory.path}/wakeup_template.wakeup_schedule");
                        await file.writeAsString(string);
                        OpenFile.open(file.path);
                      }),
                  ListTile(
                    title: const Text('第三步'),
                    subtitle: const Text('从教务系统导出课表并导入'),
                    onTap: () => showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                              title: const Text('导出课表'),
                              content: SizedBox(
                                width: 300,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: const [
                                    Text('将前往课表查询页面并自动导出课表。\n请选择当前的网络环境：'),
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
                                  child: const Text('非校园网'),
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const WakeUpPage(
                                                address:
                                                    'https://http-10-1-4-41-80.webvpn.byau.edu.cn/jsxsd/kbcx/kbxx_xzb',
                                                webVPN: false,
                                              ))),
                                ),
                                TextButton(
                                  child: const Text('校园网'),
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const WakeUpPage(
                                                address:
                                                    'http://10.1.4.41/jsxsd/kbcx/kbxx_xzb',
                                                webVPN: true,
                                              ))),
                                ),
                              ]);
                        }),
                  ),
                  ListTile(
                    title: const Text('第四步'),
                    subtitle: const Text('按照导入教程导入WakeUp课程表'),
                    onTap: () =>
                        launchInBrowser('https://pd.qq.com/s/bj7h2i1t5'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('确定'),
                onPressed: () async {
                  Navigator.pop(context);
                },
              ),
            ]);
      });
}

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
