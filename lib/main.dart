import 'dart:convert';
import 'dart:io';

import 'package:byau/course.dart';
import 'package:byau/custom_course.dart';
import 'package:byau/launch_in_browser.dart';
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
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(const BYAUApp());
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

  String courseUrl =
      'https://ids.byau.edu.cn/cas/login?service=https%3A%2F%2Flight.byau.edu.cn%2F_web%2F_lightapp%2Fschedule%2Fmobile%2Fstudent%2Findex.html';
  String agendaUrl =
      'https://ids.byau.edu.cn/cas/login?service=https%3A%2F%2Flight.byau.edu.cn%2F_web%2F_customizes%2Fbyau%2F_lightapp%2FstudentSchedul%2Fcard3.html';

  CookieManager cookieManager = CookieManager.instance();

  bool byau_net = false;

  @override
  void initState() {
    cookieManager.deleteAllCookies(); // 清除Cookies
    initApp();
    super.initState();
    WidgetsBinding widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      if (Platform.isAndroid || Platform.isIOS) {
        initializeQuickActions();
      }
    });
  }

  final usernameEdit = TextEditingController();
  final passwordEdit = TextEditingController();

  @override
  dispose() {
    usernameEdit.dispose();
    passwordEdit.dispose();
    super.dispose();
  }

  initApp() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('first_run') == null) {
      await showFirstRunDialog();
      await showAutoLoginDialog();
    }
  }

  showFirstRunDialog() async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
              canPop: false,
              child: AlertDialog(
                  title: const Text('欢迎使用极速农大'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('免责声明：本应用由开发者独立开发，与学校无关。若有侵权内容，请及时联系开发者删除。'),
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
                    ],
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
                        prefs.setBool("first_run", true);

                        Navigator.pop(context);
                      },
                    ),
                  ]));
        });
  }

  showAutoLoginDialog() async {
    Directory? document = await getApplicationDocumentsDirectory();
    File usernameFile = File('${document.path}/username');
    File passwordFile = File('${document.path}/password');
    if (usernameFile.existsSync()) {
      usernameEdit.text = usernameFile.readAsStringSync();
    } else {
      usernameEdit.text = '';
    }
    if (passwordFile.existsSync()) {
      passwordEdit.text = passwordFile.readAsStringSync();
    } else {
      passwordEdit.text = '';
    }

    showDialog(
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
              canPop: false,
              child: AlertDialog(
                  title: const Text("自动登录"),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 4),
                        ListTile(
                          leading: const Icon(Icons.question_mark),
                          title: const Text("忘记密码"),
                          onTap: () async {
                            launchInBrowser(
                                'https://imp.byau.edu.cn/_web/_apps/ids/api/passwordRecovery/new.rst');
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("取消"),
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: const Text("确定"),
                      onPressed: () async {
                        if (usernameEdit.text.isNotEmpty) {
                          await usernameFile.create();
                          await usernameFile.writeAsString(usernameEdit.text);
                        } else if (usernameFile.existsSync()) {
                          await usernameFile.delete();
                        }
                        if (passwordEdit.text.isNotEmpty) {
                          await passwordFile.create();
                          await passwordFile.writeAsString(passwordEdit.text);
                        } else if (passwordFile.existsSync()) {
                          await passwordFile.delete();
                        }
                        if (usernameEdit.text.isNotEmpty &&
                            passwordEdit.text.isNotEmpty) {
                          courseWebViewController?.loadUrl(
                              urlRequest: URLRequest(url: WebUri(courseUrl)));
                          agendaWebViewController?.loadUrl(
                              urlRequest: URLRequest(url: WebUri(agendaUrl)));
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ]));
        },
        context: context);
  }

  initializeQuickActions() async {
    const QuickActions quickActions = QuickActions();

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: '虚拟校园卡', localizedTitle: '虚拟校园卡', icon: 'qa_code'),
      const ShortcutItem(
          type: '成绩查询', localizedTitle: '成绩查询', icon: 'qa_score'),
      const ShortcutItem(type: '校历', localizedTitle: '校历', icon: 'qa_calendar'),
    ]);

    await quickActions.initialize((String shortcutType) {
      switch (shortcutType) {
        case '虚拟校园卡':
          showQrCode();
          return;

        case '成绩查询':
          openInquireScore();
          return;

        case '校历':
          openCalendar();
          return;
      }
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

  @override
  Widget build(BuildContext context) {
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
                    color: ThemeData.light().scaffoldBackgroundColor);
              } else {
                // 请求成功，显示数据
                if (snapshot.data == 114514) {
                  return Container(
                      color: ThemeData.light().scaffoldBackgroundColor);
                } else {
                  return Image.file(
                    snapshot.data,
                    fit: BoxFit.cover,
                  );
                }
              }
            } else {
              return Container(
                  color: ThemeData.light().scaffoldBackgroundColor);
            }
          },
        ),
        Container(
          color: Colors.white54,
        ),
        Scaffold(
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size(double.infinity, kToolbarHeight),
            child: Theme(
              data: ThemeData.light(),
              child: AppBar(
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => refreshHome()),
                  IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => openSettings()),
                ],
              ),
            ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [switchHome()],
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.qr_code),
            onPressed: () {
              showQrCode();
            },
          ),
          drawer: NavigationDrawer(
            selectedIndex: 10,
            onDestinationSelected: handleDestinationSelected,
            children: <Widget>[
              ListTile(
                title: Text("极速农大",
                    style: Theme.of(context).textTheme.headlineMedium),
                subtitle: GestureDetector(
                  child: const Text('版本 2.1.0-beta2'),
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
                title: const Text('内网访问'),
                value: byau_net,
                onChanged: (bool value) {
                  setState(() {
                    byau_net = value;
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
          ),
        ),
      ],
    );
  }

  switchHome() {
    if (Platform.isMacOS) {
      return Container();
    } else {
      return Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top + 4,
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(courseUrl)),
              initialSettings: settings,
              onWebViewCreated: (controller) {
                courseWebViewController = controller;
              },
              onLoadStop: (controller, url) async {
                Directory? document = await getApplicationDocumentsDirectory();
                File backgroundFile = File('${document.path}/background');
                // 自动登录
                File usernameFile = File('${document.path}/username');
                File passwordFile = File('${document.path}/password');
                String username = usernameFile.readAsStringSync();
                String password = passwordFile.readAsStringSync();
                if (url!.path.contains('/cas/login') &&
                    username.isNotEmpty &&
                    password.isNotEmpty) {
                  await courseWebViewController?.evaluateJavascript(
                      source:
                          'javascript:fm1.username.value="$username";fm1.password.value="$password";fm1.passbutton.click()');
                }

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
                          return 'style="height: 96px;background-color: rgb(255, 255, 255, 0.5);color: #000000"';
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

                // 设置背景
                String scheduleBg() {
                  if (backgroundFile.existsSync()) {
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

                String courseBg() {
                  if (backgroundFile.existsSync()) {
                    return """
                                                course(document.getElementsByClassName("contect-show clickc"));
                                                function course(array){
                                                    for(var i=0; i<array.length; i++) {
                                                        array[i].style.backgroundColor="rgb(255, 255, 255, 0.5)";
                                                        array[i].style.color="#000000";
                                                    }
                                                };

                        """;
                  } else {
                    return '';
                  }
                }

                await courseWebViewController?.evaluateJavascript(source: """
                                // 更改背景
                                ${scheduleBg()}

                                // 更改各课程背景/自定义课表
                                var oldXHR = window.XMLHttpRequest;
                                function newXHR() {
                                    var realXHR = new oldXHR();
                                    realXHR.addEventListener('readystatechange', function() {
                                        if (realXHR.readyState == 4) {
                                            setTimeout(() => {
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
              },
            ),
          ),
          SizedBox(
            height: 200,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(agendaUrl)),
              initialSettings: settings,
              onWebViewCreated: (controller) {
                agendaWebViewController = controller;
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
                  await agendaWebViewController?.evaluateJavascript(
                      source:
                          'javascript:fm1.username.value="$username";fm1.password.value="$password";fm1.passbutton.click()');
                }

                // 删除顶栏
                await agendaWebViewController?.evaluateJavascript(source: """
                              // 删除顶栏
                              tab(document.getElementsByClassName('m-news-title m-news-flex ui-border-b'));
                              function tab(array){
                                  for(var i=0; i<array.length; i++) {
                                      array[i].remove();
                                  }
                              };
                              """);

                // 清除背景
                File backgroundFile = File('${document.path}/background');

                if (backgroundFile.existsSync()) {
                  await agendaWebViewController?.evaluateJavascript(source: """
                                // 更改背景
                                bg(document.getElementsByTagName("div"));
                                bg(document.getElementsByTagName("ul"));
                                function bg(array){
                                    for(var i=0; i<array.length; i++) {
                                        array[i].style.backgroundColor="rgba(255, 255, 255, 0)";
                                    }
                                };
                            """);
                }
              },
            ),
          ),
        ],
      );
    }
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
                    width: double.maxFinite,
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
                                        width: double.maxFinite,
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
                                        width: double.maxFinite,
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
                                        width: double.maxFinite,
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
        if (byau_net == true) {
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
        if (byau_net == true) {
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

  refreshHome() {
    setState(() {
      courseWebViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(courseUrl)));
      agendaWebViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(agendaUrl)));
    });
  }

  void showQrCode() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return InAppWebView(
            initialUrlRequest: URLRequest(
                url: WebUri(
                    'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2Fqrcode.byau.edu.cn%2F_web%2F_customizes%2Fbyau%2Flightapp%2Ferweima%2Fmobile%2Findex.jsp')),
            initialSettings: InAppWebViewSettings(
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW),
            onWebViewCreated: (controller) {
              codeWebViewController = controller;
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
                await codeWebViewController?.evaluateJavascript(
                    source:
                        'javascript:fm1.username.value="$username";fm1.password.value="$password";fm1.passbutton.click()');
              }
            },
          );
        });
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

  openCalendar() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const WebViewPage(
                  title: '校历',
                  address: 'https://www.byau.edu.cn/919/list.htm',
                )));
  }

  void openSettings() async {
    Directory? document = await getApplicationDocumentsDirectory();
    File bgFile = File('${document.path}/background');
    Directory custom = Directory('${document.path}/custom/');

    getUsername() {
      File usernameFile = File('${document.path}/username');
      if (usernameFile.existsSync()) {
        String username = usernameFile.readAsStringSync();
        return username;
      } else {
        return '未设置';
      }
    }

    showModalBottomSheet(
        clipBehavior: Clip.antiAlias,
        context: context,
        builder: (context) {
          return ListView(
            shrinkWrap: true,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                title: const Text("设置"),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(
                  getUsername(),
                  maxLines: 1,
                ),
                onTap: () {
                  showAutoLoginDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("更换背景"),
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
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    if (bgFile.existsSync()) {
                      bgFile.delete();
                      refreshHome();
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text(
                  '导出课表',
                ),
                subtitle: const Text('可导入WakeUp课程表，支持课程提醒'),
                onTap: () => launchInBrowser(
                    'https://longhorn3683.github.io/2025/04/26/%E5%85%AB%E4%B8%80%E5%86%9C%E5%A4%A7%E8%AF%BE%E7%A8%8B%E8%A1%A8%E6%8F%90%E5%8F%96/'),
              ),
              ListTile(
                leading: const Icon(Icons.view_agenda),
                title: const Text('自定义课程'),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CustomCoursePage(
                              directory: custom,
                            ))).then((val) => refreshHome()),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('隐私政策'),
                onTap: () async {
                  String privacy =
                      await rootBundle.loadString('assets/privacy_policy.md');
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
                  subtitle:
                      const Text("https://github.com/Longhorn3683/byau_lite"),
                  onTap: () {
                    launchInBrowser(
                        "https://github.com/Longhorn3683/byau_lite");
                  }),
              const ListTile(
                leading: Icon(Icons.info),
                title: Text("关于"),
                subtitle: Text("整合常用功能的八一农大第三方app"),
              ),
            ],
          );
        });
  }
}
