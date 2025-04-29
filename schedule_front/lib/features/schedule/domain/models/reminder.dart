class Reminder {
  final String? reminderId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String recurrenceDays;
  final int? reminderMinutesBefore;

  Reminder({
    this.reminderId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.recurrenceDays,
    this.reminderMinutesBefore,
  });

  Map<String, dynamic> toJson() {
    return {
      if (reminderId != null) 'reminderId': reminderId,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'recurrenceDays': recurrenceDays,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      reminderId: json['reminderId'] as String?,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      recurrenceDays: json['recurrenceDays'] as String,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
    );
  }
} 