class Course {
  String name;
  int week;
  int time;
  String color;

  Course(
      {required this.name,
      required this.week,
      required this.time,
      required this.color});

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      name: json['name'],
      week: json['week'],
      time: json['time'],
      color: json['color'],
    );
  }
}

getWeekString(int number) {
  switch (number) {
    case 0:
      return '周一';
    case 1:
      return '周二';
    case 2:
      return '周三';
    case 3:
      return '周四';
    case 4:
      return '周五';
    case 5:
      return '周六';
    case 6:
      return '周日';
  }
}

getTimeString(int number) {
  switch (number) {
    case 0:
      return '08:00~09:35';
    case 2:
      return '10:05~11:40';
    case 4:
      return '13:30~15:05';
    case 6:
      return '15:35~17:10';
    case 8:
      return '18:30~20:05';
  }
}
