import 'dart:convert';
import 'dart:io';

import 'package:byau/course.dart';
import 'package:byau/custom_course.dart';
import 'package:byau/get_dark_bool.dart';
import 'package:byau/launch_in_browser.dart';
import 'package:byau/wakeup.dart';
import 'package:byau/webview.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(const BYAUApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

class BYAUApp extends StatelessWidget {
  const BYAUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color.fromRGBO(0, 120, 64, 1)),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: const Color.fromRGBO(0, 120, 64, 1)),
      home: const MyHomePage(),
      title: '极速农大',
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  InAppWebViewController? courseWebViewController;
  InAppWebViewController? agendaWebViewController;
  InAppWebViewController? codeWebViewController;

  InAppWebViewSettings settings = InAppWebViewSettings(
      transparentBackground: true,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW);

  CookieManager cookieManager = CookieManager.instance();

  @override
  void initState() {
    cookieManager.deleteAllCookies(); // 清除Cookies
    initApp();

    super.initState();
  }

  String version = '2.5.2';
  final usernameEdit = TextEditingController();
  final passwordEdit = TextEditingController();

  bool retry = false;
  bool qaLock1 = false;
  bool qaLock2 = false;
  bool webVPN = false;

  @override
  dispose() {
    usernameEdit.dispose();
    passwordEdit.dispose();
    super.dispose();
  }

  initApp() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // 初始化各开关
    if (prefs.getBool('transparent') == null) {
      prefs.setBool('transparent', true);
    }
    if (prefs.getBool('divider') == null) {
      prefs.setBool('divider', true);
    }
    if (prefs.getBool('timeline') == null) {
      prefs.setBool('timeline', true);
    }
    if (prefs.getBool('overview') == null) {
      prefs.setBool('overview', false);
    }

    // 弹出首次使用
    if (prefs.getString('version') != version) {
      await showFirstRunDialog();
    }
    if (prefs.getBool('first_run') == null) {
      await showAutoLoginDialog();
    }

    var result = await Dio()
        .get('https://gitee.com/Longhorn3683/byau_lite/raw/main/version');
    if (result.statusCode == 200) {
      if (version != result.toString()) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                  title: const Text('新版本已发布'),
                  content: SizedBox(
                    width: 300,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Text('当前版本为 $version 。版本 $result 已发布，建议更新。'),
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
                      child: const Text('更新'),
                      onPressed: () => launchInBrowser(
                          'https://www.123912.com/s/1pxFjv-4nUch'),
                    ),
                  ]);
            });
      }
    }
  }

  showFirstRunDialog() async {
    const QuickActions().clearShortcutItems;
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
              canPop: false,
              child: AlertDialog(
                  title: const Text('欢迎使用极速农大'),
                  content: SizedBox(
                    width: 250,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const Text('免责声明：本应用由开发者独立开发，与学校无关。若有侵权内容，请联系开发者删除。'),
                        const SizedBox(height: 4),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip),
                          title: const Text('隐私政策'),
                          onTap: () async {
                            String privacy = await rootBundle
                                .loadString('assets/privacy_policy.md');
                            showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return AlertDialog(
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: [
                                            MarkdownBody(data: privacy)
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
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('拒绝'),
                      onPressed: () {
                        showDialog(
                            barrierDismissible: false,
                            builder: (context) {
                              return PopScope(
                                  canPop: false,
                                  child: AlertDialog(
                                      content: const Text('本app需要同意隐私政策才能使用。'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text("确定"),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ]));
                            },
                            context: context);
                      },
                    ),
                    TextButton(
                      child: const Text('同意'),
                      onPressed: () async {
                        final SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setString("version", version);

                        // 设置快捷菜单
                        const QuickActions().setShortcutItems(<ShortcutItem>[
                          const ShortcutItem(
                              type: 'code',
                              localizedTitle: '虚拟校园卡',
                              icon: 'qa_code'),
                          const ShortcutItem(
                              type: 'calendar',
                              localizedTitle: '校历',
                              icon: 'qa_calendar'),
                        ]);

                        Navigator.pop(context);
                      },
                    ),
                  ]));
        });
  }

  showAutoLoginDialog() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('username') != null &&
        prefs.getString('password') != null) {
      usernameEdit.text = prefs.getString('username')!;
      passwordEdit.text = prefs.getString('password')!;
    } else {
      usernameEdit.text = '';
      passwordEdit.text = '';
    }

    showDialog(
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
                title: const Text("登录信息"),
                content: SizedBox(
                  width: 250,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const Text('随时可在首页右上角“设置”中修改。'),
                      const SizedBox(height: 8),
                      TextField(
                        autofocus: true,
                        controller: usernameEdit,
                        onSubmitted: (value) {
                          usernameEdit.text = value;
                        },
                        onEditingComplete: () =>
                            FocusScope.of(context).nextFocus(),
                        decoration: const InputDecoration(
                            labelText: "学号", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: true,
                        controller: passwordEdit,
                        onSubmitted: (value) {
                          passwordEdit.text = value;
                        },
                        onEditingComplete: () =>
                            FocusScope.of(context).unfocus(),
                        minLines: 1,
                        maxLines: 1,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: "密码", border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text("忘记密码"),
                    onPressed: () => launchInBrowser(
                        'https://imp.byau.edu.cn/_web/_apps/ids/api/passwordRecovery/new.rst'),
                  ),
                  TextButton(
                    child: const Text("取消"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text("确定"),
                    onPressed: () async {
                      if (usernameEdit.text.isEmpty |
                          passwordEdit.text.isEmpty) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                  content: const Text('信息未填写完整。'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('确定'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ]);
                            });
                      } else {
                        prefs.setBool("first_run", false);
                        prefs.setString('username', usernameEdit.text);
                        prefs.setString('password', passwordEdit.text);

                        retry = false; // 重置重试次数
                        setState(() {
                          refreshHome();
                        });
                        Navigator.pop(context);
                      }
                    },
                  ),
                ]),
          );
        },
        context: context);
  }

  showWakeUpDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return PopScope(
              canPop: false,
              child: AlertDialog(
                  title: const Text('你知道吗？'),
                  content: SizedBox(
                    width: 300,
                    child: ListView(
                      shrinkWrap: true,
                      children: const [
                        Text(
                            '极速农大现已支持导出课表功能，可导入WakeUp课程表。\nWakeUp课程表支持上课提醒、自定义课表等功能，可接入小布建议、YOYO建议、系统日程。'),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('确定'),
                      onPressed: () async {
                        final SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setBool("wakeup", true);
                        Navigator.pop(context);
                      },
                    ),
                  ]));
        });
  }

  getBackground() async {
    Directory? document = await getApplicationDocumentsDirectory();
    File bgFile = File('${document.path}/background');
    if (bgFile.existsSync()) {
      return bgFile;
    } else {
      return 114514;
    }
  }

  getPrefsValue(String key, String mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case 'double':
        return prefs.getDouble(key);

      case 'bool':
        return prefs.getBool(key);

      default:
        return 0;
    }
  }

  bool timelineLock = false;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const QuickActions().initialize((String shortcutType) {
        switch (shortcutType) {
          case 'code':
            if (qaLock1 == false) {
              showQrCode(false);
              refreshHome();
            }

          case 'calendar':
            if (qaLock2 == false) {
              openCalendar();
            }
        }
      });
    });

    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode(context) ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkMode(context) ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false);

    return Stack(fit: StackFit.expand, children: [
      FutureBuilder(
        future: getBackground(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              // 请求失败，显示错误
              return Container(
                  color: Theme.of(context).scaffoldBackgroundColor);
            } else {
              // 请求成功，显示数据
              if (snapshot.data == 114514) {
                return Container(
                    color: Theme.of(context).scaffoldBackgroundColor);
              } else {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      snapshot.data,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      color: isDarkMode(context)
                          ? const Color.fromRGBO(0, 0, 0, 0.8)
                          : const Color.fromRGBO(255, 255, 255, 0.8),
                    )
                  ],
                );
              }
            }
          } else {
            return Container(color: Theme.of(context).scaffoldBackgroundColor);
          }
        },
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          systemOverlayStyle: systemUiOverlayStyle,
          backgroundColor: Colors.transparent,
          actions: [
            FutureBuilder(
              future: getPrefsValue('timeline', 'bool'),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    // 请求失败，显示错误
                    return const SizedBox();
                  } else {
                    // 请求成功，显示数据
                    if (snapshot.data == false) {
                      return IconButton(
                          icon: const Icon(Icons.format_list_numbered),
                          tooltip: '设置',
                          onPressed: () {
                            if (timelineLock == false) {
                              showBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  enableDrag: false,
                                  builder: (context) {
                                    return SafeArea(
                                        minimum: const EdgeInsets.all(12),
                                        child: Opacity(
                                          opacity: 0.9,
                                          child: Card(
                                            clipBehavior: Clip.antiAlias,
                                            child: SizedBox(
                                              height: 300,
                                              child: todayWebView(0, true),
                                            ),
                                          ),
                                        ));
                                  });
                              timelineLock = true;
                            } else {
                              Navigator.pop(context);
                              timelineLock = false;
                            }
                          });
                    } else {
                      return const SizedBox();
                    }
                  }
                } else {
                  return const SizedBox();
                }
              },
            ),
            IconButton(
                icon: const Icon(Icons.settings),
                tooltip: '设置',
                onPressed: () => openSettings()),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 500) {
              // 横屏适配
              return Row(children: [
                showSchedule(1),
                FutureBuilder(
                  future: getPrefsValue('timeline', 'bool'),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        // 请求失败，显示错误
                        return const SizedBox();
                      } else {
                        // 请求成功，显示数据
                        if (snapshot.data == true) {
                          return Expanded(
                            flex: 1,
                            child: Padding(
                                padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top -
                                        kToolbarHeight +
                                        12),
                                child: todayWebView(0, false)),
                          );
                        } else {
                          return const SizedBox();
                        }
                      }
                    } else {
                      return const SizedBox();
                    }
                  },
                )
              ]);
            } else {
              // 手机
              return Column(
                children: [
                  showSchedule(2),
                  FutureBuilder(
                    future: getPrefsValue('timeline', 'bool'),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasError) {
                          // 请求失败，显示错误
                          return const SizedBox();
                        } else {
                          // 请求成功，显示数据
                          if (snapshot.data == true &&
                              constraints.maxHeight > 500) {
                            // 过小的屏幕将不显示时间线（如折叠屏、手表）
                            return Expanded(
                                flex: 1, child: todayWebView(0, false));
                          } else {
                            return const SizedBox();
                          }
                        }
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ],
              );
            }
          }),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: '虚拟校园卡',
          onPressed: () {
            showQrCode(true);
          },
          child: const Icon(Icons.qr_code),
        ),
        drawer: drawer(),
      ),
    ]);
  }

  Widget showSchedule(int flex) {
    return FutureBuilder(
      future: getPrefsValue('zoom', 'double'),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
            return const SizedBox();
          } else {
            // 请求成功，显示数据
            // 缩放开启
            if (snapshot.data != null) {
              if (Platform.isIOS) {
                // iOS使用另一种方法
                return Expanded(
                    flex: flex,
                    child: courseWebView(
                      InAppWebViewSettings(
                        transparentBackground: true,
                      ),
                      snapshot.data,
                      MediaQuery.of(context).padding.top,
                    ));
              } else {
                return Expanded(
                    flex: flex,
                    child: courseWebView(
                      InAppWebViewSettings(
                        transparentBackground: true,
                        loadWithOverviewMode: true,
                        useWideViewPort: false,
                        initialScale: snapshot.data.toInt(),
                      ),
                      0,
                      MediaQuery.of(context).padding.top,
                    ));
              }
            } else {
              // 缩放关闭
              return Expanded(
                  flex: flex,
                  child: courseWebView(
                    InAppWebViewSettings(
                      transparentBackground: true,
                    ),
                    1,
                    MediaQuery.of(context).padding.top - kToolbarHeight + 4,
                  ));
            }
          }
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget courseWebView(
      InAppWebViewSettings settings, double scale, double padding) {
    return Padding(
      padding: EdgeInsets.only(top: padding),
      child: InAppWebView(
        initialSettings: settings,
        initialUrlRequest: URLRequest(
            url: WebUri(
                'https://ids.byau.edu.cn/cas/login?service=https%3A%2F%2Flight.byau.edu.cn%2F_web%2F_lightapp%2Fschedule%2Fmobile%2Fstudent%2Findex.html')),
        onWebViewCreated: (controller) {
          courseWebViewController = controller;
        },
        onLoadStop: (controller, url) async {
          Directory? document = await getApplicationDocumentsDirectory();
          File backgroundFile = File('${document.path}/background');
          final SharedPreferences prefs = await SharedPreferences.getInstance();

          if (url!.path.contains('/cas/login')) {
            // 登录页面
            // 自动登录
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
              .contains('_web/_lightapp/schedule/mobile/student/index.html')) {
            // 登录成功
            retry = false;
            agendaWebViewController?.loadUrl(
                urlRequest: URLRequest(
                    url: WebUri(
                        'https://light.byau.edu.cn/_web/_customizes/byau/_lightapp/studentSchedul/card3.html')));
            codeWebViewController?.loadUrl(
                urlRequest: URLRequest(
                    url: WebUri(
                        'https://qrcode.byau.edu.cn/_web/_customizes/byau/lightapp/erweima/mobile/index.jsp')));

            // 提示导出课表
            if (prefs.getBool('wakeup') == null) showWakeUpDialog();

            String scaleForIOS() {
              double scalePercent = 100 / scale;

              if (prefs.getDouble('zoom') != null && Platform.isIOS) {
                // 缩放打开且为iOS设备
                return """
    document.body.style.transform = `scale($scale)`;
    document.body.style.transformOrigin = '0 0';
    document.body.style.width = `$scalePercent%`;
    document.body.style.height = `$scalePercent%`;
                        """;
              } else {
                return '';
              }
            }

            // 添加自定义课程
            String customCourse() {
              Directory custom = Directory('${document.path}/custom/');
              if (custom.existsSync()) {
                String script = '';
                custom.listSync().forEach((e) {
                  File file = File(e.path);
                  String albumJson = file.readAsStringSync();
                  final jsonMap = json.decode(albumJson);
                  Course course = Course.fromJson(jsonMap);
                  getColor() {
                    if (backgroundFile.existsSync()) {
                      return 'style="height: 96px;background-color: ${course.color};opacity: 0.7"';
                    } else {
                      return 'style="height: 96px;background-color: ${course.color}"';
                    }
                  }

                  String cell =
                      '${course.week + course.time * 7}'.padLeft(2, '0');

                  script =
                      """${script}array[$cell].innerHTML = '<div style="width: 100%;position: relative"><div class="contect-show clickc" ${getColor()}>${course.name}</div></div>';""";
                });
                return script;
              } else {
                return '';
              }
            }

            // 设置课表透明背景
            String scheduleBg() {
              if (prefs.getBool('transparent') != false ||
                  backgroundFile.existsSync() ||
                  isDarkMode(context)) {
                return """
bg(document.getElementsByTagName("div"));
bg(document.getElementsByTagName("ul"));
function bg(array){
    for(var i=0; i<array.length; i++) {
        array[i].style.backgroundColor="rgba(255, 255, 255, 0)";
    }
};

              """;
              } else {
                return '';
              }
            }

            // 设置课程背景
            String courseBg() {
              if (backgroundFile.existsSync()) {
                return """
course(document.getElementsByClassName("contect-show clickc"));
function course(array){
for(var i=0; i<array.length; i++) {
array[i].style.opacity="0.7";
}
};
                        """;
              } else {
                return '';
              }
            }

            // 删除分隔线
            String deleteDivider() {
              if (prefs.getBool('divider') != false) {
                return """
                ul(document.getElementsByTagName("td"));
                ul(document.getElementsByTagName("li"));
                ul(document.getElementsByTagName("div"));
                function ul(array){
                    for(var i=0; i<array.length; i++) {
                        array[i].style.borderStyle="none";
                    }
                };

                        """;
              } else {
                return '';
              }
            }

            await courseWebViewController?.evaluateJavascript(source: """

${scaleForIOS()}

// 更改课表背景
${scheduleBg()}

// 更改各课程背景/自定义课表
let scroll = 0;
var oldXHR = window.XMLHttpRequest;
function newXHR() {
    var realXHR = new oldXHR();
    realXHR.addEventListener('readystatechange', function() {
        if (realXHR.readyState == 4) {
            setTimeout(() => {
                scroll+=1;
                if(scroll == 5){
                    document.getElementById("cross").style.height = '';
                }

                ${deleteDivider()}
                ${courseBg()}
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
      ),
    );
  }

  Widget todayWebView(double padding, bool mode) {
    String initialUrl = mode
        ? 'https://light.byau.edu.cn/_web/_customizes/byau/_lightapp/studentSchedul/card3.html'
        : '';
    return Padding(
      padding: EdgeInsets.only(top: padding),
      child: InAppWebView(
        initialSettings: settings,
        initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
        onWebViewCreated: (controller) {
          agendaWebViewController = controller;
        },
        onLoadStop: (controller, url) async {
          // 删除更多按钮
          await agendaWebViewController?.evaluateJavascript(source: """
    var loadMore = document.getElementById("loadMore");
    loadMore.remove();
        """);

          // 深色模式适配
          if (isDarkMode(context)) {
            await agendaWebViewController?.evaluateJavascript(source: """
      bg(document.getElementsByTagName("div"));
            bg(document.getElementsByTagName("ul"));
            function bg(array){
              for(var i=0; i<array.length; i++) {
                array[i].style.backgroundColor="rgba(255, 255, 255, 0)";
              }
            };
           var oldXHR = window.XMLHttpRequest;
    function newXHR() {
        var realXHR = new oldXHR();
        realXHR.addEventListener('readystatechange', function() {
            if (realXHR.readyState == 4) {
                setTimeout(() => {
                    title(document.getElementsByTagName("h4"));
                    function title(array){
                        for(var i=0; i<array.length; i++) {
                            array[i].style.color="white";
                        }
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
      ),
    );
  }

  Widget drawer() {
    return NavigationDrawer(
      selectedIndex: 10,
      onDestinationSelected: handleDestinationSelected,
      children: <Widget>[
        ListTile(
          title:
              Text("极速农大", style: Theme.of(context).textTheme.headlineMedium),
          subtitle: GestureDetector(
            child: Text('版本 $version'),
            onDoubleTap: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) {
                  return AlertDialog(
                      title: const Text('你干嘛～哈哈～哎哟～'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('原始人，起洞'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        TextButton(
                          child: const Text('嗯，哼，哼，啊啊啊啊啊'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        TextButton(
                          child: const Text('Man! What can I say?'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ]);
                }),
          ),
        ),
        const NavigationDrawerDestination(
          label: Text(
            '成绩查询',
          ),
          icon: Icon(Icons.score),
        ),
        const NavigationDrawerDestination(
          label: Text(
            '校历',
          ),
          icon: Icon(Icons.calendar_month),
        ),
        const NavigationDrawerDestination(
          label: Text(
            '校园网',
          ),
          icon: Icon(Icons.wifi),
        ),
        const NavigationDrawerDestination(
          label: Text(
            'WebVPN',
          ),
          icon: Icon(Icons.vpn_key),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('WebVPN访问'),
          value: webVPN,
          onChanged: (bool value) {
            setState(() {
              webVPN = value;
            });
          },
        ),
        const NavigationDrawerDestination(
          label: Text(
            '教务系统',
          ),
          icon: Icon(Icons.class_),
        ),
        const NavigationDrawerDestination(
          label: Text(
            '图书馆系统',
          ),
          icon: Icon(Icons.library_books),
        ),
        const Divider(),
        const ListTile(
          title: Text('某科学的超哥发明'),
        ),
        const NavigationDrawerDestination(
          label: Text(
            '校园全景',
          ),
          icon: Icon(Icons.vrpano),
        ),
        const NavigationDrawerDestination(
          label: Text(
            '学生社区',
          ),
          icon: Icon(Icons.home_work),
        ),
      ],
    );
  }

  void handleDestinationSelected(int index) {
    switch (index) {
      case 0:
        openInquireScore();
      case 1:
        openCalendar();
      case 2:
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return AlertDialog(
                  title: const Text('校园网'),
                  content: SizedBox(
                    width: 300,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const Text(
                            'BYAU和BYAU-WINDOWS主要区别在认证方式不同，优先使用前者，支持自动登录。\n后者为网页登录，且离线一段时间后会自动注销。\n校园网密码与服务大厅密码不互通。'),
                        ListTile(
                          leading: const Icon(Icons.wifi),
                          title: const Text('连接校园网'),
                          onTap: () {
                            showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return AlertDialog(
                                      title: const Text('如何连接校园网'),
                                      content: SizedBox(
                                        width: 300,
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: const [
                                            Text(
                                                'EAP方法：PEAP\n阶段2身份验证：MSCHAPv2/不验证\nCA证书：无\n身份：学号\n匿名身份：空\n密码：校园网密码'),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('确定'),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ]);
                                });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.question_mark),
                          title: const Text('无法连接'),
                          onTap: () {
                            showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return AlertDialog(
                                      title: const Text('无法连接'),
                                      content: SizedBox(
                                        width: 300,
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: const [
                                            Text(
                                                '1. 确保BYAU和BYAU-WINDOWS均已关闭随机MAC地址/私有地址\n2. 连接BYAU-WINDOWS并进入管理，输入学号密码->自助服务，确保无感知认证已开启\n3. 点击左上角菜单->用户->绑定MAC，删除所有绑定\n4. 重新连接'),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('进入管理'),
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const WebViewPage(
                                                            title: '校园网管理',
                                                            address:
                                                                'http://10.1.2.1/')));
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('确定'),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ]);
                                });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.share),
                          title: const Text('开通经验分享'),
                          onTap: () {
                            showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return AlertDialog(
                                      title: const Text('开通经验分享'),
                                      content: SizedBox(
                                        width: 300,
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: const [
                                            Text(
                                                '更新于2025.4.28\n\n校园网办理需要大庆移动号码\n校内营业厅位置：一食堂和二食堂之间，洗浴中心旁\n校内营业厅只能办49元/月的校园卡，包含150G流量和300分钟通话。\n\n目前黑龙江移动最低资费为9元/月，没有流量和通话，需要到移动自有营业厅办理。（移动真™️贵）\n若需要办理，建议去自有大学学府营业厅。\n(本人去大庆分公司办说最低13元/月，实际上是9元/月的套餐+1年内每月赠送4个1元包。)'),
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
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.file_present),
                          title: const Text('官方入网指南'),
                          onTap: () {
                            launchInBrowser(
                                'https://nic.byau.edu.cn/2020/0721/c307a44407/page.htm');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('校园网管理'),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const WebViewPage(
                                        title: '校园网管理',
                                        address: 'http://10.1.2.1/')));
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('联系售后'),
                      onPressed: () {
                        showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) {
                              return AlertDialog(
                                  title: const Text('售后电话'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('服务时间：8:30至20:00'),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      ListTile(
                                          leading: const Icon(Icons.phone),
                                          title: const Text('198 4597 4477'),
                                          onTap: () => launchInBrowser(
                                              'tel:19845974477')),
                                      ListTile(
                                          leading: const Icon(Icons.phone),
                                          title: const Text('183 4550 0139'),
                                          onTap: () => launchInBrowser(
                                              'tel:18345500139')),
                                    ],
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('确定'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ]);
                            });
                      },
                    ),
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ]);
            });
      case 3:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const WebViewPage(
                      title: 'WebVPN',
                      address: 'https://webvpn.byau.edu.cn/',
                    )));
      case 4:
        if (webVPN == false) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const WebViewPage(
                        title: '教务系统',
                        address:
                            'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2F10.1.4.41%2Fjsxsd%2F',
                      )));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const WebViewPage(
                        title: '教务系统',
                        address:
                            'https://webvpn.byau.edu.cn/auth/login?returnUrl=https://http-10-255-255-130-80.webvpn.byau.edu.cn/jsxsd/',
                      )));
        }

      case 5:
        if (webVPN == false) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const WebViewPage(
                        title: '图书馆系统',
                        address:
                            'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2Filibopac.byau.edu.cn%2Freader%2Fhwthau.php',
                      )));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const WebViewPage(
                        title: '图书馆系统',
                        address:
                            'https://http-ilibopac-byau-edu-cn-80.webvpn.byau.edu.cn/reader/redr_info.php',
                      )));
        }

      case 6:
        launchInBrowser('https://www.720yun.com/vr/c50jzzeuea8');
      case 7:
        launchInBrowser('https://www.720yun.com/vr/075j5p4nOm1');
      case 8:
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                  title: const Text('必备应用'),
                  content: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('八一农大'),
                        subtitle: const Text('处理各种事务'),
                        onTap: () =>
                            launchInBrowser('https://apps2.byau.edu.cn/'),
                      ),
                    ],
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
  }

  refreshHome() async {
    retry = false;
    await courseWebViewController?.loadUrl(
        urlRequest: URLRequest(
            url: WebUri(
                'https://ids.byau.edu.cn/cas/login?service=https%3A%2F%2Flight.byau.edu.cn%2F_web%2F_lightapp%2Fschedule%2Fmobile%2Fstudent%2Findex.html')));
    setState(() {
      imageCache.clear();
    });
  }

  void showQrCode(bool value) async {
    qaLock1 = true;

    String initialUrl = value
        ? 'https://qrcode.byau.edu.cn/_web/_customizes/byau/lightapp/erweima/mobile/index.jsp'
        : '';
    bool refresh = false;
    await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        enableDrag: false,
        builder: (context) {
          return InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
            initialSettings: settings,
            onWebViewCreated: (controller) {
              codeWebViewController = controller;
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
              } else if (Platform.isIOS) {
                // 修复iOS端二维码无法显示
                await controller.evaluateJavascript(source: '''
                  let meta = document.createElement('meta');
                  meta.httpEquiv = "Content-Security-Policy";
                  meta.content = "upgrade-insecure-requests";
                  document.getElementsByTagName('head')[0].appendChild(meta);

                ''');
                if (refresh == false) {
                  await controller.evaluateJavascript(
                      source: 'location.reload();');
                  refresh = true;
                }
              }
            },
          );
        });
    qaLock1 = false;
  }

  openInquireScore() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const WebViewPage(
                  title: '成绩查询',
                  address:
                      'https://ids.byau.edu.cn/cas/login?service=https%3A%2F%2Flight.byau.edu.cn%2F_web%2F_lightapp%2FinquireScore%2Fmobile%2Findex.html',
                )));
  }

  openCalendar() async {
    qaLock2 = true;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const WebViewPage(
                  title: '校历',
                  address: 'https://www.byau.edu.cn/919/list.htm',
                )));
    qaLock2 = false;
  }

  void openSettings() async {
    Directory? document = await getApplicationDocumentsDirectory();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    File bgFile = File('${document.path}/background');

    getUsername() {
      if (prefs.getString('username') != null &&
          prefs.getString('username') != '') {
        return prefs.getString('username');
      } else {
        return '未设置';
      }
    }

    showModalBottomSheet(
        clipBehavior: Clip.antiAlias,
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setState) {
              return ListView(
                shrinkWrap: true,
                children: [
                  AppBar(
                    title: const Text('设置'),
                    backgroundColor: Colors.transparent,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: '刷新',
                        onPressed: () => refreshHome(),
                      )
                    ],
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: const Text('登录信息'),
                    subtitle: Text(
                      getUsername()!,
                    ),
                    onTap: () => showAutoLoginDialog(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text("自定义背景"),
                    subtitle: const Text('支持GIF动图'),
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image?.length() != null) {
                        imageCache.clear();
                        Uint8List imageBytes = await image!.readAsBytes();
                        bgFile.create();
                        await bgFile.writeAsBytes(imageBytes);
                        refreshHome();
                      }
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return AlertDialog(
                                title: const Text('删除自定义背景'),
                                content: const Text('将恢复默认背景'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('取消'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: const Text('确定'),
                                    onPressed: () {
                                      if (bgFile.existsSync()) {
                                        imageCache.clear();
                                        bgFile.delete();
                                        refreshHome();
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                ]);
                          }),
                    ),
                  ),
                  SwitchListTile(
                    value: prefs.getBool('transparent')!,
                    secondary: const Icon(Icons.wallpaper),
                    title: const Text('纯色背景'),
                    subtitle: const Text('启用深色模式或设置自定义背景后，此选项不生效'),
                    onChanged: (value) {
                      prefs.setBool('transparent', value);
                      setState(() {});
                      refreshHome();
                    },
                  ),
                  SwitchListTile(
                    value: prefs.getBool('divider')!,
                    secondary: const Icon(Icons.view_agenda),
                    title: const Text('删除分隔线'),
                    onChanged: (value) {
                      prefs.setBool('divider', value);
                      setState(() {});
                      refreshHome();
                    },
                  ),
                  SwitchListTile(
                    value: prefs.getBool('overview')!,
                    secondary: const Icon(Icons.zoom_in_map),
                    title: const Text('课表缩放'),
                    onChanged: (value) {
                      showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            final zoomEdit = TextEditingController();
                            if (prefs.getDouble('zoom') != null) {
                              zoomEdit.text = '${prefs.getDouble('zoom')}';
                            } else {
                              if (Platform.isIOS) {
                                zoomEdit.text = '1';
                              } else {
                                zoomEdit.text = '100';
                              }
                            }
                            return AlertDialog(
                                title: const Text('课表缩放'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      const SizedBox(height: 4),
                                      TextField(
                                        autofocus: true,
                                        controller: zoomEdit,
                                        onSubmitted: (value) {
                                          zoomEdit.text = value;
                                        },
                                        decoration: const InputDecoration(
                                            labelText: "放大数值",
                                            border: OutlineInputBorder()),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('关闭缩放'),
                                    onPressed: () {
                                      prefs.setBool('overview', false);
                                      prefs.remove('zoom');
                                      setState(() {});
                                      refreshHome();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('取消'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('确定'),
                                    onPressed: () {
                                      prefs.setBool('overview', true);
                                      double? number =
                                          double.tryParse(zoomEdit.text);
                                      if (number == null) {
                                        showDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (context) {
                                              final zoomEdit =
                                                  TextEditingController();
                                              if (prefs.getDouble('zoom') !=
                                                  null) {
                                                zoomEdit.text =
                                                    '${prefs.getDouble('zoom')}';
                                              } else {
                                                zoomEdit.text = '1';
                                              }
                                              return AlertDialog(
                                                  content:
                                                      const Text('请输入有效数字'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: const Text('确定'),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  ]);
                                            });
                                      } else {
                                        prefs.setDouble('zoom', number);
                                      }

                                      setState(() {});
                                      refreshHome();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ]);
                          });
                    },
                  ),
                  SwitchListTile(
                    value: prefs.getBool('timeline')!,
                    secondary: const Icon(Icons.schedule),
                    title: const Text('总是显示时间线'),
                    subtitle: const Text('此选项对过小的屏幕不生效'),
                    onChanged: (value) {
                      prefs.setBool('timeline', value);
                      setState(() {});
                      refreshHome();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('自定义课程'),
                    subtitle: const Text('添加值班、实验等未显示课程'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CustomCoursePage(
                                  document: document,
                                ))).then((val) => refreshHome()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload),
                    title: const Text(
                      '导入WakeUp课程表',
                    ),
                    subtitle: const Text('支持小组件、上课提醒'),
                    onTap: () => importWakeUp(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.message),
                    title: const Text('加入频道'),
                    subtitle: const Text("应用更新、反馈、吹水"),
                    onTap: () {
                      launchInBrowser('https://pd.qq.com/s/at5gp2fia?b=9');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Longhorn3683的小屋'),
                    subtitle: const Text("longhorn3683.github.io"),
                    onTap: () {
                      launchInBrowser('https://longhorn3683.github.io');
                    },
                  ),
                  ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text("项目地址"),
                      subtitle: const Text(
                          "https://github.com/Longhorn3683/byau_lite"),
                      onTap: () {
                        launchInBrowser(
                            "https://github.com/Longhorn3683/byau_lite");
                      }),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('隐私政策'),
                    onTap: () async {
                      String privacy = await rootBundle
                          .loadString('assets/privacy_policy.md');
                      showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return AlertDialog(
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [MarkdownBody(data: privacy)],
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
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text("关于"),
                    subtitle: Text("版本 $version"),
                    onTap: () => showAboutDialog(
                        context: context,
                        applicationIcon: Image.asset(
                          'assets/splash.png',
                          width: 50,
                          height: 50,
                        ),
                        applicationVersion: '版本 $version',
                        applicationLegalese:
                            '整合常用功能的八一农大第三方app\n免责声明：本应用由开发者独立开发，与学校无关。若有侵权内容，请联系开发者删除。'),
                  ),
                ],
              );
            }));
  }
}

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
                      'WakeUp课程表支持上课提醒、自定义课表等功能，可接入小布建议、YOYO建议、系统日程。\n若课表发生变化（如调课），需清空WakeUp课程表中的课程，删除已导入日程（若有），并重新进行第三步和第四步。\n\n以下为导出课表步骤：'),
                  ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('第一步'),
                      subtitle: const Text('下载WakeUp课程表'),
                      onTap: () => launchInBrowser('https://wakeup.fun/')),
                  ListTile(
                      leading: const Icon(Icons.file_present),
                      title: const Text('第二步'),
                      subtitle: const Text('保存课表模板'),
                      onTap: () async {
                        String template = await rootBundle.loadString(
                            'assets/wakeup_template.wakeup_schedule');
                        FlutterFileSaver().writeFileAsString(
                          fileName: '课表模板.wakeup_schedule',
                          data: template,
                        );
                      }),
                  ListTile(
                    leading: const Icon(Icons.web),
                    title: const Text('第三步'),
                    subtitle: const Text('从教务系统导出课表'),
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
                    leading: const Icon(Icons.article),
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
