class Schedule {
  final int? scheduleId;
  final String title;
  final String? description;
  final int? categoryId;
  final DateTime startTime;
  final DateTime endTime;
  final String? recurrenceDays;
  final DateTime? recurrenceStartDate;
  final DateTime? recurrenceEndDate;
  final String? excludedDates;
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
    this.recurrenceStartDate,
    this.recurrenceEndDate,
    this.excludedDates,
    this.priority,
    this.displayOnCalendar = true,
    this.reminderMinutesBefore,
  });

  Map<String, dynamic> toJson() {
    return {
      if (scheduleId != null) 'id': scheduleId,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'recurrenceDays': recurrenceDays,
      'recurrenceStartDate': recurrenceStartDate?.toIso8601String(),
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'excludedDates': excludedDates,
      'priority': priority,
      'displayOnCalendar': displayOnCalendar,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      scheduleId: json['id'] ?? json['scheduleId'],
      title: json['title'],
      description: json['description'],
      categoryId: json['categoryId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      recurrenceDays: json['recurrenceDays'],
      recurrenceStartDate: json['recurrenceStartDate'] != null ? DateTime.parse(json['recurrenceStartDate']) : null,
      recurrenceEndDate: json['recurrenceEndDate'] != null ? DateTime.parse(json['recurrenceEndDate']) : null,
      excludedDates: json['excludedDates'],
      priority: json['priority'],
      displayOnCalendar: json['displayOnCalendar'] ?? true,
      reminderMinutesBefore: json['reminderMinutesBefore'],
    );
  }

  // 복사본 생성을 위한 메서드
  Schedule copyWith({
    int? scheduleId,
    String? title,
    String? description,
    int? categoryId,
    DateTime? startTime,
    DateTime? endTime,
    String? recurrenceDays,
    DateTime? recurrenceStartDate,
    DateTime? recurrenceEndDate,
    String? excludedDates,
    int? priority,
    bool? displayOnCalendar,
    int? reminderMinutesBefore,
  }) {
    return Schedule(
      scheduleId: scheduleId ?? this.scheduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      recurrenceStartDate: recurrenceStartDate ?? this.recurrenceStartDate,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      excludedDates: excludedDates ?? this.excludedDates,
      priority: priority ?? this.priority,
      displayOnCalendar: displayOnCalendar ?? this.displayOnCalendar,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }
} 