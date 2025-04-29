class Schedule {
  final int? scheduleId;
  final String title;
  final String? description;
  final int? categoryId;
  final DateTime startTime;
  final DateTime endTime;
  final String? recurrenceDays;
  final int? priority;
  final bool displayOnCalendar;
  final int? reminderMinutesBefore;

  Schedule({
    this.scheduleId,
    required this.title,
    this.description,
    this.categoryId,
    required this.startTime,
    required this.endTime,
    this.recurrenceDays,
    this.priority,
    this.displayOnCalendar = true,
    this.reminderMinutesBefore,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'recurrenceDays': recurrenceDays,
      'priority': priority,
      'displayOnCalendar': displayOnCalendar,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      scheduleId: json['scheduleId'],
      title: json['title'],
      description: json['description'],
      categoryId: json['categoryId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      recurrenceDays: json['recurrenceDays'],
      priority: json['priority'],
      displayOnCalendar: json['displayOnCalendar'] ?? true,
      reminderMinutesBefore: json['reminderMinutesBefore'],
    );
  }
} 