import 'package:byau/launch_in_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

final usernameEdit = TextEditingController();
final passwordEdit = TextEditingController();
late String name;
late String username;

bool login = false;

showAutoLoginDialog(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getString('username') != null &&
      prefs.getString('password') != null) {
    usernameEdit.text = prefs.getString('username')!;
    passwordEdit.text = prefs.getString('password')!;
  } else {
    usernameEdit.text = '';
    passwordEdit.text = '';
  }

  await showDialog(
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
            title: const Text("登录信息"),
            content: SizedBox(
              width: 250,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    controller: usernameEdit,
                    onSubmitted: (value) {
                      usernameEdit.text = value;
                    },
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
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
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
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
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                              title: const Text('忘记密码'),
                              content: SizedBox(
                                width: 300,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: const [
                                    Text('若忘记密码，请使用八一农大APP或前往网页重置。'),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('前往网页'),
                                  onPressed: () {
                                    launchInBrowser(
                                        'https://imp.byau.edu.cn/_web/_apps/ids/api/passwordRecovery/new.rst');
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
                  }),
              TextButton(
                child: const Text("取消"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("确定"),
                onPressed: () async {
                  if (usernameEdit.text.isEmpty | passwordEdit.text.isEmpty) {
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
                    showLoginWindow(
                        context, usernameEdit.text, passwordEdit.text);
                  }
                },
              ),
            ]);
      },
      context: context);
  return login;
}

showLoginWindow(BuildContext context, String username, String password) async {
  // 验证用户信息
  showDialog(
      builder: (context) {
        return AlertDialog(
            content: SizedBox(
              width: 250,
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                    url: WebUri(
                        'https://ids.byau.edu.cn/cas/login?service=https%3A%2F%2Fimp.byau.edu.cn%2F_ids_mobile%2FmyIndex')),
                initialSettings: InAppWebViewSettings(
                  transparentBackground: true,
                ),
                onLoadStop: (controller, url) async {
                  if (url!.path.contains('/cas/login')) {
                    // 检测到登录页面，自动登录
                    await controller.evaluateJavascript(
                        source:
                            'var msg=document.getElementById("msg1");if(msg){console.log("登录失败");}else{fm1.username.value="$username";fm1.password.value="$password";fm1.passbutton.click()};');
                  } else {
                    // 登录成功，抓取信息
                    await controller.evaluateJavascript(
                        source:
                            'console.log("姓名："+document.getElementsByClassName("username")[0].innerHTML);console.log("学号："+document.getElementsByClassName("account")[0].innerHTML);');
                    Navigator.pop(context);
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                              title: const Text('您的用户信息'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text('姓名'),
                                    subtitle: Text(name),
                                  ),
                                  ListTile(
                                    title: Text('学号'),
                                    subtitle: Text(username),
                                  ),
                                ],
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text("取消"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                TextButton(
                                  child: const Text('确定'),
                                  onPressed: () async {
                                    final SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    prefs.setString(
                                        'username', usernameEdit.text);
                                    prefs.setString(
                                        'password', passwordEdit.text);
                                    prefs.setString('name', name);
                                    login = true;
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    usernameEdit.clear();
                                    passwordEdit.clear();
                                  },
                                ),
                              ]);
                        });
                  }
                },
                onConsoleMessage: (controller, consoleMessage) async {
                  if (consoleMessage.message.contains('登录失败')) {
                    Navigator.pop(context);
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                              title: const Text('登录失败'),
                              content: const Text(
                                  '检查学号和密码是否正确。若忘记密码，请使用八一农大APP或前往网页重置。'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text("前往网页"),
                                  onPressed: () => launchInBrowser(
                                      'https://imp.byau.edu.cn/_web/_apps/ids/api/passwordRecovery/new.rst'),
                                ),
                                TextButton(
                                  child: const Text('确定'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ]);
                        });
                  } else if (consoleMessage.message.contains('姓名：')) {
                    name = consoleMessage.message.replaceAll('姓名：', '');
                  } else if (consoleMessage.message.contains('学号：')) {
                    username = consoleMessage.message.replaceAll('学号：', '');
                  }
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("取消"),
                onPressed: () => Navigator.pop(context),
              ),
            ]);
      },
      context: context);
}
