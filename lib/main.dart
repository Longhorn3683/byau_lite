import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:sp_util/sp_util.dart';

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

  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW);

  String url = "";
  double progress = 0;
  CookieManager cookieManager = CookieManager.instance();
  List<String> titleList = [
    "课程表",
    '虚拟校园卡',
    '校园网',
    '教务系统',
    '图书馆系统',
  ];
  List<String> addressList = [
    "https://ids.byau.edu.cn/cas/login?service=https%3A%2F%2Flight.byau.edu.cn%2F_web%2F_lightapp%2Fschedule%2Fmobile%2Fstudent%2Findex.html",
    'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2Fqrcode.byau.edu.cn%2F_web%2F_customizes%2Fbyau%2Flightapp%2Ferweima%2Fmobile%2Findex.html',
    'http://10.1.2.1/srun_portal_pc?ac_id=2',
    'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2F10.1.4.41%2Fjsxsd%2F',
    'https://ids.byau.edu.cn/cas/login?service=http%3A%2F%2Filibopac.byau.edu.cn%2Freader%2Fhwthau.php',
  ];
  int selectedIndex = 0;

  @override
  void initState() {
    initializeQuickActions();
    cookieManager.deleteAllCookies();
    initApp();

    super.initState();
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
                      const Text("填写以下内容以启用自动登录，有一处留空则关闭自动登录。\n设置完成后请手动刷新。"),
                      TextField(
                        autofocus: false,
                        controller: _usernameEdit,
                        onSubmitted: (value) {
                          _usernameEdit.text = value;
                        },
                        decoration: const InputDecoration(labelText: "账号"),
                      ),
                      TextField(
                        autofocus: false,
                        controller: _passwordEdit,
                        onSubmitted: (value) {
                          _passwordEdit.text = value;
                        },
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
                        Navigator.pop(context);
                      },
                    ),
                  ]));
        },
        context: context);
  }

  initializeQuickActions() {
    quickActions.initialize((String shortcutType) {
      switch (shortcutType) {
        case '课程表':
          setState(() {
            selectedIndex = 0;
            webViewController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(addressList[0])));
          });

          return;
        case '虚拟校园卡':
          setState(() {
            selectedIndex = 1;
            webViewController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(addressList[1])));
          });

          return;
        case '校园网':
          setState(() {
            selectedIndex = 2;
            webViewController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(addressList[2])));
          });

          return;
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: '课程表', localizedTitle: '课程表', icon: 'icon_main'),
      const ShortcutItem(
          type: '虚拟校园卡', localizedTitle: '虚拟校园卡', icon: 'icon_help'),
      const ShortcutItem(type: '校园网', localizedTitle: '校园网', icon: 'icon_help')
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
              onPressed: () {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: WebUri(addressList[selectedIndex])));
              },
              icon: const Icon(Icons.refresh),
              tooltip: "刷新",
            ),
          ],
        ),
        body: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              webViewEnvironment: webViewEnvironment,
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
                    await webViewController?.evaluateJavascript(
                        source:
                            """javascript:document.body.style.background = 'url(${SpUtil.getString('background')}) no-repeat center fixed';
                            teste(document.getElementsByTagName("div"));

                        function teste(array){
        for(var i=0; i<array.length; i++)
        {
            array[i].style.backgroundColor="rgba(255, 255, 255,0.1)";
            teste(array[i].getElementsByTagName("div"));
        }
    }""");
                  }
                }

                setState(() {
                  this.url = url.toString();
                });
              },
              onReceivedError: (controller, request, error) {},
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
            NavigationDrawerDestination(
              label: Text(titleList[0]),
              icon: const Icon(Icons.calendar_month),
            ),
            NavigationDrawerDestination(
              label: Text(titleList[1]),
              icon: const Icon(Icons.qr_code),
            ),
            const Divider(),
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
                context: context,
                //半透明红色
                isDismissible: true,
                enableDrag: true,
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
                          leading: const Icon(Icons.delete),
                          title: const Text("清除数据"),
                          subtitle: const Text("若遇到无法登录等异常可尝试此项"),
                          onTap: () {
                            cookieManager.deleteAllCookies;
                            webViewController?.loadUrl(
                                urlRequest: URLRequest(
                                    url: WebUri(addressList[selectedIndex])));
                            Navigator.pop(context);
                          }),
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
                                          const Text(
                                              "仅对课程表、虚拟校园卡、校园网管理生效。刷新以应用更改。"),
                                          TextField(
                                            autofocus: false,
                                            controller: _backgroundEdit,
                                            onSubmitted: (value) {
                                              _backgroundEdit.text = value;
                                            },
                                            decoration: const InputDecoration(
                                                labelText:
                                                    "图片地址（需为 http/https）"),
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
                                            await SpUtil.putString('background',
                                                _backgroundEdit.text);
                                            setState(() {
                                              _background = SpUtil.getString(
                                                  'background')!;
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
                          title: const Text("项目地址"),
                          subtitle: const Text(
                              "https://github.com/Longhorn3683/byau_lite"),
                          onTap: () {
                            Clipboard.setData(const ClipboardData(
                                text:
                                    "https://github.com/Longhorn3683/byau_lite"));

                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Yay! A SnackBar!'),
                            ));
                          }),
                    ],
                  );
                });
          },
          child: const Icon(Icons.settings),
        ));
  }

  void handleDestinationSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
    webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(addressList[index])));
    Navigator.pop(context);
  }
}
