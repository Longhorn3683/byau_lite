import 'package:byau/feature/webview.dart';
import 'package:byau/launch_in_browser.dart';
import 'package:flutter/material.dart';

class CampusNetPage extends StatefulWidget {
  const CampusNetPage({super.key});

  @override
  _CampusNetPageState createState() => _CampusNetPageState();
}

class _CampusNetPageState extends State<CampusNetPage> {
  @override
  void initState() {
    super.initState();
  }

  final List<Item> _connectItems = connectItems();
  final List<Item> _faqItems = faqItems();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          const SliverAppBar.large(title: Text("校园网FAQ")),
          const SliverToBoxAdapter(
            child: ListTile(title: Text('还没连上校园网？校园网连不上了？')),
          ),
          SliverToBoxAdapter(
            child: Card(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)), // 设置圆角半径
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('校园网管理'),
                    subtitle: const Text('需连接校园网访问'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebViewPage(
                          title: '校园网管理',
                          address: 'http://10.252.102.21/',
                          campusNetAddress: '',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)), // 设置圆角半径
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    titleAlignment: ListTileTitleAlignment.top,
                    leading: Icon(Icons.wifi, size: 52),
                    title: Text('连接校园网'),
                    subtitle: Text(
                      '默认密码：身份证后六位（与智慧校园服务大厅和八一农大APP不通用）\n建议关闭随机MAC地址/私有Wi-Fi地址。',
                    ),
                  ),
                  ExpansionPanelList(
                    elevation: 0,
                    materialGapSize: 0,
                    dividerColor: Colors.transparent,
                    expansionCallback: (int index, bool isExpanded) {
                      setState(() {
                        _connectItems[index].isExpanded = isExpanded;
                      });
                    },
                    children: _connectItems.map<ExpansionPanel>((Item item) {
                      return ExpansionPanel(
                        canTapOnHeader: true,
                        backgroundColor: Colors.transparent,
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(title: Text(item.headerValue));
                        },
                        body: ListTile(title: Text(item.expandedValue)),
                        isExpanded: item.isExpanded,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)), // 设置圆角半径
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    titleAlignment: ListTileTitleAlignment.top,
                    leading: Icon(Icons.question_mark, size: 52),
                    title: Text('常见问题'),
                    subtitle: Text('需要抢课？密码错误？网连不上？这里都有答案。'),
                  ),
                  ExpansionPanelList(
                    elevation: 0,
                    materialGapSize: 0,
                    dividerColor: Colors.transparent,
                    expansionCallback: (int index, bool isExpanded) {
                      setState(() {
                        _faqItems[index].isExpanded = isExpanded;
                      });
                    },
                    children: _faqItems.map<ExpansionPanel>((Item item) {
                      return ExpansionPanel(
                        backgroundColor: Colors.transparent,
                        canTapOnHeader: true,
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(title: Text(item.headerValue));
                        },
                        body: ListTile(title: Text(item.expandedValue)),
                        isExpanded: item.isExpanded,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)), // 设置圆角半径
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    titleAlignment: ListTileTitleAlignment.top,
                    leading: Icon(Icons.file_present, size: 52),
                    title: Text('其他资源'),
                    subtitle: Text('若问题仍未解决，可拨打服务热线或查看官方指南。'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('服务热线'),
                    subtitle: const Text('服务时间：08:30-20:00'),
                    onTap: () => showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('服务热线'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              ListTile(
                                title: const Text('+86 198 4597 4477'),
                                onTap: () => launchInBrowser('tel:19845974477'),
                              ),
                              ListTile(
                                title: const Text('+86 183 4550 0139'),
                                onTap: () => launchInBrowser('tel:18345500139'),
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
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('官方入网指南'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebViewPage(
                          title: '入网指南',
                          address:
                              'https://nic.byau.edu.cn/2020/0721/c307a44407/page.htm',
                          campusNetAddress: '',
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('官方疑难解答'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebViewPage(
                          title: '疑难解答',
                          address:
                              'https://nic.byau.edu.cn/2023/0831/c307a108976/page.psp',
                          campusNetAddress: '',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: kFloatingActionButtonMargin),
          ),
        ],
      ),
    );
  }
}

class Item {
  Item({
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
  });

  String expandedValue;
  String headerValue;
  bool isExpanded;
}

List<Item> connectItems() {
  return [
    Item(
      headerValue: '连接BYAU（推荐）',
      expandedValue:
          '苹果和Windows可直接输入学号和密码登录（提示证书不可信请点击信任）。\n\n安卓配置如下：\nEAP方法：PEAP\n阶段2身份验证：MSCHAPv2\nCA证书：无\n身份：学号\n匿名身份：留空\n密码：校园网密码',
    ),
    Item(
      headerValue: '连接BYAU-WINDOWS',
      expandedValue:
          '此接入点使用网页认证且离线时间过长需要重新登录。\n连接后会自动弹出网页，在网页输入学号和密码并登录即可。\n若网页没有自动弹出，请在浏览器访问：http://10.252.102.21',
    ),
  ];
}

List<Item> faqItems() {
  return [
    Item(
      headerValue: '抢课一定要办校园网吗？',
      expandedValue:
          '校园网实际上不需要办理，但默认只能访问校内资源（其中包括抢选修课、成绩查询）。学校里常说的“办校园网”指的是办理宽带接入，也就是互联网访问。',
    ),
    Item(
      headerValue: '为什么突然上不了网/访问不了互联网？',
      expandedValue:
          '1. 确认电话卡没有欠费\n2. 打开校园网管理，输入学号和密码，点击“自助服务”。若“在线信息”中的“产品名称”为“移动宽带”则正常，“访问校内资源”则办理的宽带已过期。',
    ),
    Item(headerValue: '校园网没有有线连接？', expandedValue: '目前只有教学区可以有线连接，其他地方只能无线。'),
    Item(
      headerValue: '学号和密码正确，提示连接失败/您当前使用的设备非该账号绑定设备',
      expandedValue:
          '校园网限制最多2个设备使用，若无法使用已绑定的设备，可连接BYAU-WINDOWS并在弹出的网页（若未弹出可使用校园网管理）输入学号和密码，点击“自助服务”，点击左上角菜单->用户->绑定MAC，删除所有设备并重新连接（建议关闭随机MAC地址/私有Wi-Fi地址）。',
    ),
  ];
}
