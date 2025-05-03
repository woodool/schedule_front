class Reminder {
  final String? reminderId;
  final String reminder_title;
  final String recurrenceDays;
  final int? reminderMinutesBefore;
  final bool? isActive;
  final String? date;
  final DateTime? checkedDate;
  final DateTime? recurrenceStartDate;
  final DateTime? recurrenceEndDate;
  final String? excludedDates;

  Reminder({
    this.reminderId,
    required this.reminder_title,
    required this.recurrenceDays,
    this.reminderMinutesBefore,
    this.isActive = true,
    this.date,
    this.checkedDate,
    this.recurrenceStartDate,
    this.recurrenceEndDate,
    this.excludedDates,
  });

  Reminder copyWith({
    String? reminderId,
    String? reminder_title,
    String? recurrenceDays,
    int? reminderMinutesBefore,
    bool? isActive,
    String? date,
    DateTime? checkedDate,
    DateTime? recurrenceStartDate,
    DateTime? recurrenceEndDate,
    String? excludedDates,
  }) {
    return Reminder(
      reminderId: reminderId ?? this.reminderId,
      reminder_title: reminder_title ?? this.reminder_title,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      isActive: isActive ?? this.isActive,
      date: date ?? this.date,
      checkedDate: checkedDate ?? this.checkedDate,
      recurrenceStartDate: recurrenceStartDate ?? this.recurrenceStartDate,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      excludedDates: excludedDates ?? this.excludedDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (reminderId != null) 'id': reminderId,
      'reminderTitle': reminder_title,
      'recurrenceDays': recurrenceDays,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isActive': isActive,
      'date': date,
      if (checkedDate != null) 'checkedDate': checkedDate!.toIso8601String(),
      if (recurrenceStartDate != null) 'recurrenceStartDate': recurrenceStartDate!.toIso8601String(),
      if (recurrenceEndDate != null) 'recurrenceEndDate': recurrenceEndDate!.toIso8601String(),
      'excludedDates': excludedDates,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      reminderId: json['id']?.toString() ?? json['reminderId'] as String?,
      reminder_title: json['reminderTitle'] as String,
      recurrenceDays: json['recurrenceDays'] as String,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
      isActive: json['isActive'] as bool?,
      date: json['date'] as String?,
      checkedDate: json['checkedDate'] != null 
          ? DateTime.parse(json['checkedDate'] as String) 
          : null,
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