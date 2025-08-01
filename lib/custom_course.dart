import 'dart:convert';
import 'dart:io';

import 'package:byau/course.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomCoursePage extends StatefulWidget {
  const CustomCoursePage({super.key, required this.document});
  final Directory document;

  @override
  _CustomCoursePageState createState() => _CustomCoursePageState();
}

final courseNameEdit = TextEditingController();
final courseColorEdit = TextEditingController();

class _CustomCoursePageState extends State<CustomCoursePage> {
  @override
  void initState() {
    super.initState();
    initSp();
  }

  bool transparent = true;
  bool divider = true;
  bool timeline = true;

  initSp() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    transparent = prefs.getBool('transparent')!;
    divider = prefs.getBool('divider')!;
    timeline = prefs.getBool('timeline')!;
    setState(() {});
  }

  setSpBool(String key, bool bool) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, bool);
    setState(() {});
  }

  List customList() {
    Directory custom = Directory('${widget.document.path}/custom/');

    if (!custom.existsSync()) {
      custom.create();
      return [];
    } else {
      return custom.listSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          SliverAppBar(
            title: const Text("自定义课程"),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () =>
                    showCustomCourseDialog(context, true, '', 0, 0, '#114514'),
              )
            ],
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
