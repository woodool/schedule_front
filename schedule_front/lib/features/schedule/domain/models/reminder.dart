class Reminder {
  final String? reminderId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String recurrenceDays;
  final int? reminderMinutesBefore;
  final bool? isActive;
  final String? date;
  final DateTime? recurrenceStartDate;
  final DateTime? recurrenceEndDate;
  final String? excludedDates;

  Reminder({
    this.reminderId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.recurrenceDays,
    this.reminderMinutesBefore,
    this.isActive = true,
    this.date,
    this.recurrenceStartDate,
    this.recurrenceEndDate,
    this.excludedDates,
  });

  Reminder copyWith({
    String? reminderId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? recurrenceDays,
    int? reminderMinutesBefore,
    bool? isActive,
    String? date,
    DateTime? recurrenceStartDate,
    DateTime? recurrenceEndDate,
    String? excludedDates,
  }) {
    return Reminder(
      reminderId: reminderId ?? this.reminderId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      isActive: isActive ?? this.isActive,
      date: date ?? this.date,
      recurrenceStartDate: recurrenceStartDate ?? this.recurrenceStartDate,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      excludedDates: excludedDates ?? this.excludedDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (reminderId != null) 'id': reminderId,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'recurrenceDays': recurrenceDays,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isActive': isActive,
      'date': date,
      if (recurrenceStartDate != null) 'recurrenceStartDate': recurrenceStartDate!.toIso8601String(),
      if (recurrenceEndDate != null) 'recurrenceEndDate': recurrenceEndDate!.toIso8601String(),
      'excludedDates': excludedDates,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      reminderId: json['id']?.toString() ?? json['reminderId'] as String?,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      recurrenceDays: json['recurrenceDays'] as String,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
      isActive: json['isActive'] as bool?,
      date: json['date'] as String?,
      recurrenceStartDate: json['recurrenceStartDate'] != null 
          ? DateTime.parse(json['recurrenceStartDate'] as String) 
          : null,
      recurrenceEndDate: json['recurrenceEndDate'] != null 
          ? DateTime.parse(json['recurrenceEndDate'] as String) 
          : null,
      excludedDates: json['excludedDates'] as String?,
    );
  }
} 