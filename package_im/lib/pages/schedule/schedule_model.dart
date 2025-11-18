


/// 日程数据模型
class Schedule {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String color;

  Schedule({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'color': color,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      color: json['color'],
    );
  }
}

