import 'dart:convert';
import 'dart:io';

import 'package:byau/course.dart';
import 'package:byau/launch_in_browser.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CustomCoursePage extends StatefulWidget {
  const CustomCoursePage({super.key, required this.directory});
  final Directory directory;

  @override
  _CustomCoursePageState createState() => _CustomCoursePageState();
}

final courseNameEdit = TextEditingController();
final courseColorEdit = TextEditingController();

class _CustomCoursePageState extends State<CustomCoursePage> {
  @override
  void initState() {
    super.initState();
  }

  List customList() {
    if (!widget.directory.existsSync()) {
      widget.directory.create();
      return [];
    } else {
      return widget.directory.listSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          const SliverAppBar(
            title: Text("自定义课程"),
          ),
          const SliverToBoxAdapter(
            child: ListTile(
              leading: Icon(
                Icons.warning,
                color: Colors.orange,
              ),
              title: Text(
                '不再建议使用此功能，建议导出课表并导入WakeUp课程表。\nWakeUp课程表可接入小布建议、YOYO建议，可导入系统日程，支持自定义课表、小组件、上课提醒等功能。',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              leading: const Icon(Icons.upload),
              title: const Text(
                '导出教程',
              ),
              onTap: () => launchInBrowser('https://pd.qq.com/s/bbjc2guo9?b=2'),
            ),
          ),
          const SliverToBoxAdapter(
            child: Divider(),
          ),
          const SliverToBoxAdapter(
            child: ListTile(
              title: Text('添加的课程不支持点击查看课程信息，且会覆盖对应开始时间的课程。\n暂不支持添加到时间线。'),
            ),
          ),
          SliverList.builder(
              itemCount: customList().length,
              itemBuilder: (context, index) {
                String courseJson = customList()[index].readAsStringSync();
                final jsonMap = json.decode(courseJson);
                Course course = Course.fromJson(jsonMap);

                return ListTile(
                  title: Text(course.name),
                  subtitle: Text(
                      "${getWeekString(course.week)} ${getTimeString(course.time)}"),
                  onTap: () {
                    showCustomCourseDialog(context, false, course.name,
                        course.week, course.time, course.color);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('删除课程？'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('取消'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                TextButton(
                                  child: const Text('确定'),
                                  onPressed: () {
                                    customList()[index].delete().then((e) {
                                      setState(() {});
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          });
                    },
                  ),
                );
              }),
          SliverToBoxAdapter(
            child: ListTile(
              leading: const Icon(Icons.add),
              title: const Text('添加课程'),
              onTap: () {
                showCustomCourseDialog(context, true, '', 0, 0, '#114514');
              },
            ),
          ),
        ],
      ),
    );
  }

  showCustomCourseDialog(BuildContext context, bool edit, String name, int week,
      int time, String color) async {
    Directory? document = await getApplicationDocumentsDirectory();
    Directory custom = Directory('${document.path}/custom/');
    courseNameEdit.text = name;
    courseColorEdit.text = color;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: SizedBox(
                width: 200,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      autofocus: true,
                      controller: courseNameEdit,
                      onSubmitted: (value) {
                        courseNameEdit.text = value;
                      },
                      decoration: const InputDecoration(
                          labelText: "课程名称（<br>换行）",
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<String>(
                      initialSelection: '$week',
                      enabled: edit,
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(label: '周一', value: '0'),
                        DropdownMenuEntry(label: '周二', value: '1'),
                        DropdownMenuEntry(label: '周三', value: '2'),
                        DropdownMenuEntry(label: '周四', value: '3'),
                        DropdownMenuEntry(label: '周五', value: '4'),
                        DropdownMenuEntry(label: '周六', value: '5'),
                        DropdownMenuEntry(label: '周日', value: '6'),
                      ],
                      onSelected: (value) {
                        week = int.parse(value!);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<String>(
                      initialSelection: '$time',
                      enabled: edit,
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(label: '08:00~09:35', value: '0'),
                        DropdownMenuEntry(label: '10:05~11:40', value: '2'),
                        DropdownMenuEntry(label: '13:30~15:05', value: '4'),
                        DropdownMenuEntry(label: '15:35~17:10', value: '6'),
                        DropdownMenuEntry(label: '18:30~20:05', value: '8'),
                      ],
                      onSelected: (value) {
                        time = int.parse(value!);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: false,
                      controller: courseColorEdit,
                      onSubmitted: (value) {
                        courseColorEdit.text = value;
                      },
                      decoration: const InputDecoration(
                          labelText: "卡片颜色（HEX/RGB/RGBA）",
                          border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.pop(context);
                    courseNameEdit.clear();
                    courseColorEdit.clear();
                  },
                ),
                TextButton(
                  child: const Text('确定'),
                  onPressed: () async {
                    String cell = '${week + time * 7}'.padLeft(2, '0');
                    if (courseNameEdit.text != '' &&
                        courseColorEdit.text != '') {
                      File courseFile = File("${custom.path}$cell");
                      if (edit == true && courseFile.existsSync()) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                content: const Text('此时段已存在自定义课程'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('确定'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            });
                      } else {
                        await courseFile.create();
                        var course = {
                          "name": courseNameEdit.text,
                          "week": week,
                          "time": time,
                          "color": courseColorEdit.text,
                        };
                        await courseFile.writeAsString(jsonEncode(course));
                        courseNameEdit.clear();
                        courseColorEdit.clear();
                        setState(() {});
                        Navigator.pop(context);
                      }
                    } else {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: const Text('课程信息未填写完整'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('确定'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          });
                    }
                  },
                ),
              ]);
        });
  }
}
