import 'dart:convert';
import 'dart:io';

import 'package:byau/course.dart';
import 'package:byau/custom_course.dart';
import 'package:byau/event_import.dart';
import 'package:byau/feature/fail_course.dart';
import 'package:byau/feature/login.dart';
import 'package:byau/get_dark_bool.dart';
import 'package:byau/launch_in_browser.dart';
import 'package:byau/feature/wakeup.dart';
import 'package:byau/webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      theme: ThemeData(
        colorSchemeSeed: const Color.fromRGBO(0, 120, 64, 1),
        appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color.fromRGBO(0, 120, 64, 1),
        appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
      ),
      home: const MyHomePage(),
      title: '极速农大',
      //debugShowCheckedModeBanner: false,
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

  //CookieManager cookieManager = CookieManager.instance();

  @override
  void initState() {
    //cookieManager.deleteAllCookies(); // 清除Cookies
    initApp();
    super.initState();
  }

  String version = '2.7.0';
  String firstrunVer = '2.7.0';

  bool qaLockCode = false;
  bool qaLockScore = false;
  bool qaLockCalendar = false;
  bool qaLockSeat = false;
  bool qaLockWifi = false;

  bool webVPN = false;

  @override
  dispose() {
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

    if (prefs.getBool('overview') == null) {
      prefs.setBool('overview', false);
    }

    // 弹出首次使用
    if (prefs.getString('version') != firstrunVer) {
      await showFirstRunDialog();
    }

    // 设置快捷菜单
    List<ShortcutItem> shortcutList = [
      const ShortcutItem(
        type: 'code',
        localizedTitle: '虚拟校园卡',
        icon: 'qa_code',
      ),
      const ShortcutItem(
        type: 'score',
        localizedTitle: '成绩查询',
        icon: 'qa_score',
      ),
      const ShortcutItem(
        type: 'seat',
        localizedTitle: '图书馆选座',
        icon: 'qa_seat',
      ),
      const ShortcutItem(
        type: 'calendar',
        localizedTitle: '校历',
        icon: 'qa_calendar',
      ),
      const ShortcutItem(type: 'wifi', localizedTitle: '校园网', icon: 'qa_wifi'),
    ];
    const QuickActions().setShortcutItems(shortcutList);
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
                  const Text(
                    '免责声明：本应用属于非官方应用，由开发者独立开发，与黑龙江八一农垦大学无任何关联，开发者不对使用本应用产生的一切后果负责。\n\n请认准以下官方渠道：\n官方网站：www.byau.edu.cn\n官方APP：八一农大',
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.file_present),
                    title: const Text('使用协议'),
                    onTap: () async {
                      String privacy = await rootBundle.loadString(
                        'assets/terms_of_use.md',
                      );
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
                            ],
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('隐私政策'),
                    onTap: () async {
                      String privacy = await rootBundle.loadString(
                        'assets/privacy_policy.md',
                      );
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
                            ],
                          );
                        },
                      );
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
                          content: const Text('本APP需要同意使用协议和隐私政策才能使用。'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text("确定"),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    context: context,
                  );
                },
              ),
              TextButton(
                child: const Text('同意'),
                onPressed: () async {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setString("version", firstrunVer);

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const QuickActions().initialize((String shortcutType) {
        switch (shortcutType) {
          case 'code':
            if (qaLockCode == false) {
              showQrCode();
            }

          case 'score':
            if (qaLockScore == false) {
              qaLockScore = true;
              openInquireScore();
            }

          case 'seat':
            if (qaLockSeat == false) {
              qaLockSeat = true;
              openLibrarySeat();
            }

          case 'calendar':
            if (qaLockCalendar == false) {
              openCalendar();
            }

          case 'wifi':
            if (qaLockWifi == false) {
              openCampusWifi();
            }
        }
      });
    });

    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode(context)
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDarkMode(context)
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder(
          future: getBackground(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                // 请求失败，显示错误
                return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                );
              } else {
                // 请求成功，显示数据
                if (snapshot.data == 114514) {
                  return Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  );
                } else {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(snapshot.data, fit: BoxFit.cover),
                      Container(
                        color: isDarkMode(context)
                            ? const Color.fromRGBO(0, 0, 0, 0.3)
                            : const Color.fromRGBO(255, 255, 255, 0.3),
                      ),
                    ],
                  );
                }
              }
            } else {
              return const SizedBox();
            }
          },
        ),
        classicUI(),
      ],
    );
  }

  Widget classicUI() {
    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode(context)
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDarkMode(context)
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 500) {
          // 宽屏适配
          return Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              systemOverlayStyle: systemUiOverlayStyle,
              backgroundColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: '设置',
                  onPressed: () => openSettings(),
                ),
              ],
            ),
            body: Row(
              children: [
                Expanded(child: showScheduleClassic(true)),
                Expanded(child: todayWebView()),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              tooltip: '虚拟校园卡',
              onPressed: () {
                showQrCode();
              },
              child: const Icon(Icons.qr_code),
            ),
            drawer: drawer(),
          );
        } else {
          return Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              systemOverlayStyle: systemUiOverlayStyle,
              backgroundColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: '设置',
                  onPressed: () => openSettings(),
                ),
              ],
            ),
            body: widgetLayer(
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(flex: 2, child: showScheduleClassic(false)),
                    Expanded(child: todayWebView()),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              tooltip: '虚拟校园卡',
              onPressed: () {
                showQrCode();
              },
              child: const Icon(Icons.qr_code),
            ),
            drawer: drawer(),
          );
        }
      },
    );
  }

  refreshUI() async {
    if (logon == true) {
      courseWebViewController?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(
            'https://ids.byau.edu.cn/cas/login?service=https://light.byau.edu.cn/_web/_lightapp/schedule/mobile/student/index.html',
          ),
        ),
      );
    }
  }

  bool logon = false;
  HeadlessInAppWebView? headlessWebView;

  getAccountStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('username') != null &&
        prefs.getString('password') != null &&
        logon == false) {
      // 有自动登录信息且未登录
      logon = true;
      return logon;
    } else if (logon == true) {
      //已登录
      return logon;
    } else {
      // 无登录信息
      logon = false;
      return logon;
    }
  }

  Widget widgetLayer(Widget widget) {
    return FutureBuilder(
      future: getAccountStatus(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
            return const Icon(Icons.error);
          } else {
            // 请求成功，显示数据
            if (snapshot.data == true) {
              // 已登录
              return widget;
            } else {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.error, size: 52),
                    ),
                    Text(
                      '登录信息未设置',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              );
            }
          }
        } else {
          return SizedBox();
        }
      },
    );
  }

  Widget showScheduleClassic(bool tablet) {
    return FutureBuilder(
      future: getPrefsValue('zoom', 'double'),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        double topPadding = tablet ? 0 : MediaQuery.of(context).padding.top;
        double topPaddingCourse = tablet
            ? 0
            : MediaQuery.of(context).padding.top - kToolbarHeight + 4;
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
                return Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: courseWebView(
                    InAppWebViewSettings(transparentBackground: true),
                    snapshot.data,
                  ),
                );
              } else {
                // 非iOS
                return Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: courseWebView(
                    InAppWebViewSettings(
                      transparentBackground: true,
                      useHybridComposition: false,
                      loadWithOverviewMode: true,
                      useWideViewPort: false,
                      initialScale: snapshot.data.toInt(),
                    ),
                    0,
                  ),
                );
              }
            } else {
              // 缩放关闭
              return Padding(
                padding: EdgeInsets.only(top: topPaddingCourse),
                child: courseWebView(
                  InAppWebViewSettings(
                    transparentBackground: true,
                    useHybridComposition: false,
                  ),
                  1,
                ),
              );
            }
          }
        } else {
          return const SizedBox();
        }
      },
    );
  }

  bool retry = false;
  Widget courseWebView(InAppWebViewSettings settings, double scale) {
    return InAppWebView(
      initialSettings: settings,
      initialUrlRequest: URLRequest(
        url: WebUri(
          'https://ids.byau.edu.cn/cas/login?service=https://light.byau.edu.cn/_web/_lightapp/schedule/mobile/student/index.html',
        ),
      ),
      onWebViewCreated: (controller) {
        courseWebViewController = controller;
      },
      onLoadStart: (controller, url) {},
      onLoadStop: (controller, url) async {
        Directory? document = await getApplicationDocumentsDirectory();
        File backgroundFile = File('${document.path}/background');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        if (url!.path.contains('/cas/login') && retry == false) {
          // 检测到登录页面且未触发重试，自动登录
          await controller.evaluateJavascript(
            source:
                'fm1.username.value="${prefs.getString('username')}";fm1.password.value="${prefs.getString('password')}";fm1.passbutton.click()',
          );
          retry = true;
        } else if (url!.path.contains(
          '_web/_lightapp/schedule/mobile/student/index.html',
        )) {
          // 登录成功，重置重试状态
          retry = false;

          // 刷新今日课程
          agendaWebViewController?.loadUrl(
            urlRequest: URLRequest(
              url: WebUri(
                'https://light.byau.edu.cn/_web/_customizes/byau/_lightapp/studentSchedul/card3.html',
              ),
            ),
          );

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

                String cell = '${course.week + course.time * 7}'.padLeft(
                  2,
                  '0',
                );

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

          await courseWebViewController?.evaluateJavascript(
            source:
                """
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
            """,
          );
        }
      },
      onConsoleMessage: (controller, consoleMessage) async {
        if (consoleMessage.message.contains('登录失败')) {
          showDialog(
            context: context,
            builder: (context) {
              logon = false;
              return AlertDialog(
                title: const Text('登录失败'),
                content: const Text('密码可能已被修改或学号因毕业被注销，请重新设置登录信息。'),
                actions: <Widget>[
                  TextButton(
                    child: const Text("打开设置"),
                    onPressed: () => openSettings(),
                  ),
                  TextButton(
                    child: const Text('确定'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }

  Widget todayWebView() {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        useHybridComposition: false,
      ),
      onWebViewCreated: (controller) {
        agendaWebViewController = controller;
      },
      onLoadStop: (controller, url) async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // 删除元素
        if (prefs.getBool('beta') == true) {
          await agendaWebViewController?.evaluateJavascript(
            source: """
            document.getElementsByClassName("m-news-title m-news-flex ui-border-b")[0].remove()
          """,
          );
        } else {
          await agendaWebViewController?.evaluateJavascript(
            source: """
            var loadMore = document.getElementById("loadMore");
            loadMore.remove();
          """,
          );
        }

        // 深色模式适配
        if (isDarkMode(context)) {
          await agendaWebViewController?.evaluateJavascript(
            source: """
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
          """,
          );
        }
      },
    );
  }

  Widget codeWebview() {
    bool refresh = false;
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(
          'https://ids.byau.edu.cn/cas/login?service=http://qrcode.byau.edu.cn/_web/_customizes/byau/lightapp/erweima/mobile/index.jsp',
        ),
      ),
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        useHybridComposition: false,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      ),
      onWebViewCreated: (controller) {
        codeWebViewController = controller;
      },
      onLoadStop: (controller, url) async {
        if (url!.path.contains(
          '_web/_customizes/byau/lightapp/erweima/mobile/index.jsp',
        )) {
          await controller.evaluateJavascript(
            source:
                'document.body.style.backgroundColor = "transparent";document.getElementsByClassName("container")[0].style.borderRadius = "24px";',
          );
          if (Platform.isIOS) {
            // 修复iOS端二维码显示
            await controller.evaluateJavascript(
              source: '''
                  let meta = document.createElement('meta');
                  meta.httpEquiv = "Content-Security-Policy";
                  meta.content = "upgrade-insecure-requests";
                  document.getElementsByTagName('head')[0].appendChild(meta);

                ''',
            );
            if (refresh == false) {
              await controller.evaluateJavascript(source: 'location.reload();');
              refresh = true;
            }
          }
        }
      },
    );
  }

  Widget drawer() {
    return NavigationDrawer(
      selectedIndex: 1145141919810,
      onDestinationSelected: handleDestinationSelected,
      children: <Widget>[
        ListTile(
          title: Text(
            "极速农大",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
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
                  ],
                );
              },
            ),
          ),
        ),
        const NavigationDrawerDestination(
          label: Text('成绩查询'),
          icon: Icon(Icons.score),
        ),
        const NavigationDrawerDestination(
          label: Text('图书馆选座'),
          icon: Icon(Icons.local_library),
        ),
        const NavigationDrawerDestination(
          label: Text('校历'),
          icon: Icon(Icons.calendar_month),
        ),
        const NavigationDrawerDestination(
          label: Text('校园网'),
          icon: Icon(Icons.wifi),
        ),
        const NavigationDrawerDestination(
          label: Text('WebVPN'),
          icon: Icon(Icons.vpn_key),
        ),
        const Divider(),
        StatefulBuilder(
          builder: (context, setState2) {
            return SwitchListTile(
              title: const Text('WebVPN访问'),
              value: webVPN,
              onChanged: (bool value) {
                setState2(() {
                  webVPN = value;
                });
              },
            );
          },
        ),
        const NavigationDrawerDestination(
          label: Text('挂了吗'),
          icon: Icon(Icons.close),
        ),
        const NavigationDrawerDestination(
          label: Text('教务系统'),
          icon: Icon(Icons.class_),
        ),
        const NavigationDrawerDestination(
          label: Text('图书馆系统'),
          icon: Icon(Icons.library_books),
        ),
        const Divider(),
        const ListTile(title: Text('某科学的超哥发明')),
        const NavigationDrawerDestination(
          label: Text('校园全景'),
          icon: Icon(Icons.vrpano),
        ),
        const NavigationDrawerDestination(
          label: Text('学生社区'),
          icon: Icon(Icons.home_work),
        ),
        const SizedBox(height: kFloatingActionButtonMargin),
      ],
    );
  }

  Future<void> handleDestinationSelected(int index) async {
    switch (index) {
      case 0:
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return AlertDialog(
              content: const Text('此选项为八一农大APP的成绩查询页面，数据更新比教务系统慢，建议使用教务系统查询。'),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('继续'),
                  onPressed: () => openInquireScore(),
                ),
              ],
            );
          },
        );
      case 1:
        openLibrarySeat();
      case 2:
        openCalendar();
      case 3:
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return AlertDialog(
              title: const Text('校园网'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'BYAU和BYAU-WINDOWS主要区别在认证方式不同，建议优先使用前者，支持自动登录。\n后者为网页登录，且离线一段时间后需重新登录。',
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('联系售后'),
                      onTap: () => showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('售后电话'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '服务时间：08:30-20:00\n校园卡解封需前往东北石油大学附近营业厅（也就是离学校最近的自有营业厅）。',
                                ),
                                const SizedBox(height: 4),
                                ListTile(
                                  leading: const Icon(Icons.phone),
                                  title: const Text('198 4597 4477'),
                                  onTap: () =>
                                      launchInBrowser('tel:19845974477'),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.phone),
                                  title: const Text('183 4550 0139'),
                                  onTap: () =>
                                      launchInBrowser('tel:18345500139'),
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('确定'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('前往管理'),
                  onPressed: () {
                    openCampusWifi();
                  },
                ),
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WebViewPage(
              title: 'WebVPN',
              address: 'https://webvpn.byau.edu.cn/',
            ),
          ),
        );
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FailCoursePage(webVPN: webVPN),
          ),
        );
      case 6:
        if (webVPN == false) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebViewPage(
                title: '教务系统',
                address:
                    'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2F10.1.4.41%2Fjsxsd%2F',
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebViewPage(
                title: '教务系统',
                address:
                    'https://webvpn.byau.edu.cn/auth/login?returnUrl=https://http-10-255-255-130-80.webvpn.byau.edu.cn/jsxsd/',
              ),
            ),
          );
        }

      case 7:
        if (webVPN == false) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebViewPage(
                title: '图书馆系统',
                address: 'https://ilibopac.byau.edu.cn/space/reader/readerHome',
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebViewPage(
                title: '图书馆系统',
                address:
                    'https://webvpn.byau.edu.cn/_webvpn_*/https://ilibopac.byau.edu.cn/space/reader/readerHome',
              ),
            ),
          );
        }

      case 8:
        launchInBrowser('https://www.720yun.com/vr/c50jzzeuea8');
      case 9:
        launchInBrowser('https://www.720yun.com/vr/075j5p4nOm1');
    }
  }

  void showQrCode() async {
    qaLockCode = true;
    await showModalBottomSheet(
      context: context,
      enableDrag: false,
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        return codeWebview();
      },
    );
    qaLockCode = false;
  }

  openInquireScore() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebViewPage(
          title: '成绩查询',
          address:
              'https://ids.byau.edu.cn/cas/login?service=https%3A%2F%2Flight.byau.edu.cn%2F_web%2F_lightapp%2FinquireScore%2Fmobile%2Findex.html',
        ),
      ),
    ).then((val) {
      if (qaLockScore == true) {
        setState(() {
          qaLockScore = false;
        });
      }
    });
  }

  openLibrarySeat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebViewPage(
          title: '图书馆选座',
          address: 'http://libseat.byau.edu.cn/',
        ),
      ),
    ).then((val) {
      if (qaLockSeat == true) {
        setState(() {
          qaLockSeat = false;
        });
      }
    });
  }

  openCalendar() async {
    qaLockCalendar = true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebViewPage(
          title: '校历',
          address: 'https://www.byau.edu.cn/919/list.htm',
        ),
      ),
    );
    qaLockCalendar = false;
  }

  openCampusWifi() async {
    qaLockWifi = true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const WebViewPage(title: '校园网管理', address: 'http://10.252.102.21/'),
      ),
    );
    qaLockWifi = false;
  }

  void openSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    getUsername() {
      if (prefs.getString('username') != null &&
          prefs.getString('username') != '') {
        return prefs.getString('username');
      } else {
        return '未知学号';
      }
    }

    showModalBottomSheet(
      clipBehavior: Clip.antiAlias,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSettingsState) {
          return ListView(
            shrinkWrap: true,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: '刷新',
                    onPressed: () => refreshUI(),
                  ),
                ],
              ),
              ListTile(
                contentPadding: EdgeInsets.only(left: 16, right: 8),
                leading: const Icon(Icons.account_circle),
                title: Text('自动登录'),
                subtitle: Text(getUsername()!),
                trailing: MenuAnchor(
                  builder:
                      (
                        BuildContext context,
                        MenuController controller,
                        Widget? child,
                      ) {
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
                      leadingIcon: Icon(Icons.info),
                      child: Text('个人信息'),
                      onPressed: () {},
                    ),
                    MenuItemButton(
                      leadingIcon: Icon(Icons.logout),
                      child: Text('退出登录'),
                      onPressed: () {},
                    ),
                  ],
                ),
                onTap: () async {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (prefs.getString('username') == null) {
                    // 登录信息未设置
                    showAutoLoginDialog(context).then((value) {
                      print(value);
                      if (value == true) {
                        refreshUI();
                        setSettingsState(() {});
                        login = false;
                      }
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebViewPage(
                          title: '个人信息',
                          address:
                              'https://imp.byau.edu.cn/_ids_mobile/myIndex',
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_agenda),
                title: const Text('主页设置'),
                onTap: () => showScheduleSettings(),
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('日程导入助手'),
                subtitle: const Text('接入系统日历'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EventImportPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('导入WakeUp课程表'),
                onTap: () => importWakeUp(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cast_for_education),
                title: const Text('学习通课程'),
                subtitle: const Text("应用更新、意见反馈、校园攻略"),
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('学习通课程邀请码'),
                        content: const Text('71572560'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('复制邀请码'),
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(text: '71572560'),
                              );
                            },
                          ),
                          TextButton(
                            child: const Text('确定'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('QQ频道'),
                subtitle: const Text("应用更新、二手交易、吹水"),
                onTap: () {
                  launchInBrowser('https://pd.qq.com/s/at5gp2fia?b=9');
                },
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Longhorn3683的小屋'),
                subtitle: const Text("来开发者的小屋坐坐吧"),
                onTap: () {
                  launchInBrowser('https://longhorn3683.github.io');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text("项目地址"),
                subtitle: const Text(
                  "https://github.com/Longhorn3683/byau_lite",
                ),
                onTap: () {
                  launchInBrowser("https://github.com/Longhorn3683/byau_lite");
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_present),
                title: const Text('使用协议'),
                onTap: () async {
                  String privacy = await rootBundle.loadString(
                    'assets/terms_of_use.md',
                  );
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
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('隐私政策'),
                onTap: () async {
                  String privacy = await rootBundle.loadString(
                    'assets/privacy_policy.md',
                  );
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
                        ],
                      );
                    },
                  );
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
                      '免责声明：本应用由开发者独立开发，与学校无关。若有侵权内容，请联系开发者删除。',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void showScheduleSettings() async {
    Directory? document = await getApplicationDocumentsDirectory();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    File bgFile = File('${document.path}/background');

    Navigator.pop(context);
    await showModalBottomSheet(
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.transparent,
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor.withOpacity(0.9),
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState2) {
          return ListView(
            shrinkWrap: true,
            children: [
              AppBar(
                title: const Text('主页设置'),
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    onPressed: () {
                      refreshUI();
                    },
                    icon: Icon(Icons.refresh),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('课程表'),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("自定义背景"),
                subtitle: const Text('支持GIF动图'),
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image?.length() != null) {
                    imageCache.clear();
                    Uint8List imageBytes = await image!.readAsBytes();
                    bgFile.create();
                    await bgFile.writeAsBytes(imageBytes);
                    setState(() {});
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
                                setState(() {});
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SwitchListTile(
                value: prefs.getBool('transparent')!,
                secondary: const Icon(Icons.wallpaper),
                title: const Text('纯色背景'),
                subtitle: const Text('深色模式或自定义背景不生效'),
                onChanged: (value) {
                  prefs.setBool('transparent', value);
                  setState2(() {
                    refreshUI();
                  });
                },
              ),
              SwitchListTile(
                value: prefs.getBool('divider')!,
                secondary: const Icon(Icons.view_agenda),
                title: const Text('删除分隔线'),
                onChanged: (value) {
                  prefs.setBool('divider', value);
                  setState2(() {
                    refreshUI();
                  });
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
                                  border: OutlineInputBorder(),
                                ),
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
                              setState2(() {});
                              setState(() {});
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
                              double? number = double.tryParse(zoomEdit.text);
                              if (number == null) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) {
                                    final zoomEdit = TextEditingController();
                                    if (prefs.getDouble('zoom') != null) {
                                      zoomEdit.text =
                                          '${prefs.getDouble('zoom')}';
                                    } else {
                                      zoomEdit.text = '1';
                                    }
                                    return AlertDialog(
                                      content: const Text('请输入有效数字'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('确定'),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                prefs.setDouble('zoom', number);
                              }

                              setState2(() {});
                              setState(() {});
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('自定义课程'),
                subtitle: const Text('添加值班/实验/重修/补修等未显示课程'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomCoursePage(document: document),
                  ),
                ).then((val) => refreshUI()),
              ),
            ],
          );
        },
      ),
    );
    openSettings();
  }
}
