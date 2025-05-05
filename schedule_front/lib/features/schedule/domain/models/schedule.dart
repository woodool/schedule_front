import 'dart:convert';

class Schedule {
  final int? id;
  final String title;
  final String? description;
  final int? categoryId;
  final DateTime startTime;
  final DateTime endTime;
  final String? recurrenceDays;         // ex. "1,0,0,1,0,0,0"
  final DateTime? recurrenceStartDate;
  final DateTime? recurrenceEndDate;
  final String? excludedDates;          // ex. "2025-05-01,2025-05-03"
  final int? reminderMinutesBefore;
  final DateTime? reminderTime;         // backend 계산
  final int? priority;
  final bool displayOnCalendar;

  Schedule({
    this.id,
    required this.title,
    this.description,
    this.categoryId,
    required this.startTime,
    required this.endTime,
    this.recurrenceDays,
    this.recurrenceStartDate,
    this.recurrenceEndDate,
    this.excludedDates,
    this.reminderMinutesBefore,
    this.reminderTime,
    this.priority,
    required this.displayOnCalendar,
  });

  int? get scheduleId => id;

  Schedule copyWith({
    int? id,
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
    int? reminderMinutesBefore,
    DateTime? reminderTime,
    int? priority,
    bool? displayOnCalendar,
  }) {
    return Schedule(
      id: scheduleId ?? id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      recurrenceStartDate: recurrenceStartDate ?? this.recurrenceStartDate,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      excludedDates: excludedDates ?? this.excludedDates,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      reminderTime: reminderTime ?? this.reminderTime,
      priority: priority ?? this.priority,
      displayOnCalendar: displayOnCalendar ?? this.displayOnCalendar,
    );
  }

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        categoryId: json['categoryId'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        recurrenceDays: json['recurrenceDays'],
        recurrenceStartDate: json['recurrenceStartDate'] != null
            ? DateTime.parse(json['recurrenceStartDate'])
            : null,
        recurrenceEndDate: json['recurrenceEndDate'] != null
            ? DateTime.parse(json['recurrenceEndDate'])
            : null,
        excludedDates: json['excludedDates'],
        reminderMinutesBefore: json['reminderMinutesBefore'],
        reminderTime: json['reminderTime'] != null
            ? DateTime.parse(json['reminderTime'])
            : null,
        priority: json['priority'],
        displayOnCalendar: json['displayOnCalendar'],
      );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'option': 'ALL',
      'displayOnCalendar': displayOnCalendar,
    };

    // NULL이 아닌 필드만 추가
    if (id != null) data['scheduleId'] = id;
    if (categoryId != null) data['categoryId'] = categoryId;
    
    if (recurrenceDays != null) data['recurrenceDays'] = recurrenceDays;
    if (recurrenceStartDate != null) data['recurrenceStartDate'] = recurrenceStartDate?.toIso8601String();
    if (recurrenceEndDate != null) data['recurrenceEndDate'] = recurrenceEndDate?.toIso8601String();
    if (excludedDates != null) data['excludedDates'] = excludedDates;
    
    if (reminderMinutesBefore != null) data['reminderMinutesBefore'] = reminderMinutesBefore;
    if (reminderTime != null) data['reminderTime'] = reminderTime?.toIso8601String();
    if (priority != null) data['priority'] = priority;

    // 디버그 출력
    print('Schedule.toJson() 호출: $data');
    
    return data;
  }

  Map<String, dynamic> toJsonForCreate() => {
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'recurrenceDays': recurrenceDays,
        'recurrenceStartDate': recurrenceStartDate != null
            ? recurrenceStartDate?.toIso8601String()
            : (recurrenceDays != null && recurrenceDays != "0,0,0,0,0,0,0"
                ? startTime.add(Duration(days: 1)).toIso8601String()
                : null),
        'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
        'reminderMinutesBefore': reminderMinutesBefore,
        'priority': priority,
        'displayOnCalendar': displayOnCalendar,
        'excludedDates': excludedDates,
      };

  Map<String, dynamic> toJsonForUpdate({required String option, DateTime? occurrenceDate}) {
    final m = toJsonForCreate();
    m['option'] = option;
    if (occurrenceDate != null) {
      m['fromDate'] = occurrenceDate.toIso8601String();
      m['occurrenceDate'] = occurrenceDate.toIso8601String(); // 백엔드 요청 필드명 일치
    }
    
    // displayOnCalendar 필드가 존재하는지 확인
    if (!m.containsKey('displayOnCalendar')) {
      m['displayOnCalendar'] = displayOnCalendar;
    }
    
    return m;
  }
}
