import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:sp_util/sp_util.dart';
import 'package:url_launcher/url_launcher.dart';

WebViewEnvironment? webViewEnvironment;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(const BYAUApp());
}

class BYAUApp extends StatelessWidget {
  const BYAUApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      darkTheme: ThemeData.dark(),
      home: const MyHomePage(title: '极速农大'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final QuickActions quickActions = const QuickActions();

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW);

  String url = "";

  double progress = 0;
  CookieManager cookieManager = CookieManager.instance();
  List<String> titleList = [
    "课程表",
    '虚拟校园卡',
    '校园网管理',
    '教务系统',
    '图书馆系统',
    '校园全景',
    '学生社区',
  ];
  List<String> addressList = [
    "https://ids.byau.edu.cn/cas/login?service=https%3A%2F%2Flight.byau.edu.cn%2F_web%2F_lightapp%2Fschedule%2Fmobile%2Fstudent%2Findex.html",
    'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2Fqrcode.byau.edu.cn%2F_web%2F_customizes%2Fbyau%2Flightapp%2Ferweima%2Fmobile%2Findex.html',
    'http://10.1.2.1/srun_portal_pc?ac_id=2',
    'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2F10.1.4.41%2Fjsxsd%2F',
    'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2Filibopac.byau.edu.cn%2Freader%2Fhwthau.php',
    'https://www.720yun.com/vr/c50jzzeuea8',
    'https://www.720yun.com/vr/075j5p4nOm1',
  ];
  int selectedIndex = 0;

  @override
  void initState() {
    cookieManager.deleteAllCookies();
    initApp();
    super.initState();
    WidgetsBinding widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      initializeQuickActions();
    });
  }

  late String _username;
  late String _password;
  late String _background;
  final _usernameEdit = TextEditingController();
  final _passwordEdit = TextEditingController();
  final _backgroundEdit = TextEditingController();

  @override
  dispose() {
    _usernameEdit.dispose();
    _passwordEdit.dispose();
    _backgroundEdit.dispose();
    super.dispose();
  }

  initApp() async {
    await SpUtil.getInstance();
    _username = SpUtil.getString('byau_username', defValue: '')!;
    _password = SpUtil.getString('byau_password', defValue: '')!;
    _background = SpUtil.getString('background', defValue: '')!;
    SpUtil.getBool('auto_login', defValue: false)!;
    if (SpUtil.getBool('first_run', defValue: false)! == false) {
      await showAutoLoginDialog();
    }
  }

  showAutoLoginDialog() {
    _usernameEdit.text = _username;
    _passwordEdit.text = _password;

    showDialog(
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
              canPop: false,
              child: AlertDialog(
                  title: const Text("自动登录"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("填写以下内容以启用自动登录，留空则关闭自动登录。"),
                      TextField(
                        autofocus: true,
                        controller: _usernameEdit,
                        onSubmitted: (value) {
                          _usernameEdit.text = value;
                        },
                        onEditingComplete: () =>
                            FocusScope.of(context).nextFocus(),
                        decoration: const InputDecoration(labelText: "账号"),
                      ),
                      TextField(
                        autofocus: true,
                        controller: _passwordEdit,
                        onSubmitted: (value) {
                          _passwordEdit.text = value;
                        },
                        onEditingComplete: () =>
                            FocusScope.of(context).unfocus(),
                        minLines: 1,
                        maxLines: 1,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '密码'),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("取消"),
                      onPressed: () {
                        SpUtil.putBool("first_run", true);
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: const Text("确定"),
                      onPressed: () async {
                        if (_usernameEdit.text.isNotEmpty &&
                            _passwordEdit.text.isNotEmpty) {
                          setState(() {
                            SpUtil.putBool("auto_login", true);
                          });
                        } else {
                          await SpUtil.putBool("auto_login", false);
                        }
                        await SpUtil.putString(
                            "byau_username", _usernameEdit.text);
                        _username = _usernameEdit.text;
                        await SpUtil.putString(
                            "byau_password", _passwordEdit.text);
                        _password = _passwordEdit.text;
                        SpUtil.putBool("first_run", true);
                        webViewController?.loadUrl(
                            urlRequest: URLRequest(url: WebUri(url)));
                        Navigator.pop(context);
                      },
                    ),
                  ]));
        },
        context: context);
  }

  initializeQuickActions() async {
    await quickActions.initialize((String shortcutType) {
      switch (shortcutType) {
        case '课程表':
          setState(() {
            selectedIndex = 0;
            webViewController?.loadUrl(
                urlRequest:
                    URLRequest(url: WebUri(addressList[selectedIndex])));
          });
          return;

        case '虚拟校园卡':
          setState(() {
            selectedIndex = 1;
            webViewController?.loadUrl(
                urlRequest:
                    URLRequest(url: WebUri(addressList[selectedIndex])));
          });
          return;

        case '校园网':
          setState(() {
            selectedIndex = 2;
            webViewController?.loadUrl(
                urlRequest:
                    URLRequest(url: WebUri(addressList[selectedIndex])));
          });
          return;
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: '课程表', localizedTitle: '课程表', icon: 'qa_calendar'),
      const ShortcutItem(
          type: '虚拟校园卡', localizedTitle: '虚拟校园卡', icon: 'qa_code'),
      const ShortcutItem(type: '校园网', localizedTitle: '校园网', icon: 'qa_wifi')
    ]);
  }

  String getUsername() {
    if (_username != '') {
      return _username;
    } else {
      return '未设置用户名';
    }
  }

  String getBackground() {
    if (_background != '') {
      return _background;
    } else {
      return '未设置';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titleList[selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: "在浏览器打开",
            onPressed: () => launchUrl(Uri.parse(addressList[selectedIndex])),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "刷新",
            onPressed: () => webViewController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(url))),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest:
                URLRequest(url: WebUri(addressList[selectedIndex])),
            initialSettings: settings,
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                this.url = url.toString();
              });
            },
            onLoadStop: (controller, url) async {
              // 自动登录
              if (url!.path.contains('/cas/login') &&
                  SpUtil.getBool('auto_login')! == true) {
                await webViewController?.evaluateJavascript(
                    source:
                        'javascript:fm1.username.value="$_username";fm1.password.value="$_password";fm1.passbutton.click()');
              }
              // 设置自定义背景
              if (SpUtil.getString('background')! != "") {
                if (url.path.contains('srun_portal') |
                    url.path.contains('lightapp')) {
                  await webViewController?.evaluateJavascript(source: """
                            javascript:
                            document.body.style.background = 'url(${SpUtil.getString('background')}) center no-repeat';
                            document.body.style.backgroundSize = 'cover';
                            teste(document.getElementsByTagName("div"));
                            function teste(array){
                              for(var i=0; i<array.length; i++) {
                                array[i].style.backgroundColor="rgba(255, 255, 255, 0.1)";
                                teste(array[i].getElementsByTagName("div"));
                                teste(array[i].getElementsByTagName("ul"));
                              }
                            }
                            """);
                }
              }
              setState(() {
                this.url = url.toString();
              });
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                this.progress = progress / 100;
              });
            },
          ),
          progress < 1.0
              ? LinearProgressIndicator(value: progress)
              : Container(),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: handleDestinationSelected,
        children: <Widget>[
          ListTile(
            title:
                Text("极速农大", style: Theme.of(context).textTheme.headlineMedium),
            subtitle: const Text('版本 1.1.0'),
            trailing: IconButton(
                onPressed: () => openSettings(),
                icon: const Icon(Icons.settings)),
          ),
          NavigationDrawerDestination(
            label: Text(titleList[0]),
            icon: const Icon(Icons.calendar_month),
          ),
          NavigationDrawerDestination(
            label: Text(titleList[1]),
            icon: const Icon(Icons.qr_code),
          ),
          const Divider(),
          const ListTile(
            title: Text('内网资源'),
          ),
          NavigationDrawerDestination(
            label: Text(titleList[2]),
            icon: const Icon(Icons.wifi),
          ),
          NavigationDrawerDestination(
            label: Text(titleList[3]),
            icon: const Icon(Icons.class_),
          ),
          NavigationDrawerDestination(
            label: Text(titleList[4]),
            icon: const Icon(Icons.library_books),
          ),
          const Divider(),
          const ListTile(
            title: Text('看点好看的'),
          ),
          NavigationDrawerDestination(
            label: Text(titleList[5]),
            icon: const Icon(Icons.vrpano),
          ),
          NavigationDrawerDestination(
            label: Text(titleList[6]),
            icon: const Icon(Icons.home_work),
          ),
        ],
      ),
    );
  }

  void handleDestinationSelected(int index) {
    switch (index) {
      case 5 || 6 || 7:
        launchUrl(Uri.parse(addressList[index]));
        return;
      default:
        setState(() {
          selectedIndex = index;
        });
        webViewController?.loadUrl(
            urlRequest: URLRequest(url: WebUri(addressList[index])));
        Navigator.pop(context);
    }
  }

  void openSettings() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return ListView(
            shrinkWrap: true,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                title: const Text("设置"),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.login),
                title: const Text("自动登录"),
                subtitle: Text(
                  getUsername(),
                  maxLines: 1,
                ),
                onChanged: (bool value) {
                  showAutoLoginDialog();
                },
                value: SpUtil.getBool('auto_login')!,
              ),
              ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text("自定义背景"),
                  subtitle: Text(getBackground()),
                  onTap: () {
                    showDialog(
                        barrierDismissible: true,
                        builder: (context) {
                          _backgroundEdit.text = _background;
                          return AlertDialog(
                              title: const Text("自定义背景"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("仅对课程表、虚拟校园卡、校园网管理生效。"),
                                  TextField(
                                    autofocus: true,
                                    controller: _backgroundEdit,
                                    onSubmitted: (value) {
                                      _backgroundEdit.text = value;
                                    },
                                    decoration: const InputDecoration(
                                        labelText: "图片地址（需为 http/https）"),
                                  ),
                                ],
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text("取消"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                TextButton(
                                  child: const Text("确定"),
                                  onPressed: () async {
                                    await SpUtil.putString(
                                        'background', _backgroundEdit.text);
                                    setState(() {
                                      _background =
                                          SpUtil.getString('background')!;
                                      webViewController?.loadUrl(
                                          urlRequest:
                                              URLRequest(url: WebUri(url)));
                                    });

                                    Navigator.pop(context);
                                  },
                                ),
                              ]);
                        },
                        context: context);
                  }),
              const Divider(),
              ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text("关于"),
                  subtitle: const Text("整合常用功能的八一农大第三方app"),
                  onTap: () {}),
              ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text("项目地址（长按复制）"),
                  subtitle:
                      const Text("https://github.com/Longhorn3683/byau_lite"),
                  onTap: () {
                    Clipboard.setData(const ClipboardData(
                        text: "https://github.com/Longhorn3683/byau_lite"));
                  }),
            ],
          );
        });
  }
}
