import 'dart:convert';

class ScheduleItem {
  String title;
  List<String> days;
  String startTime;
  String endTime;
  String recurrenceStartDate;
  String recurrenceEndDate;
  bool isEnabled;

  ScheduleItem({
    required this.title,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.recurrenceStartDate,
    required this.recurrenceEndDate,
    this.isEnabled = false,
  });

  /// 복사용 메서드: 원본과 동일한 값으로 새로운 인스턴스를 만듭니다.
  ScheduleItem copy() {
    return ScheduleItem(
      title: title,
      days: List.from(days),
      startTime: startTime,
      endTime: endTime,
      recurrenceStartDate: recurrenceStartDate,
      recurrenceEndDate: recurrenceEndDate,
      isEnabled: isEnabled,
    );
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
        title: j['title'] as String,
        days: List<String>.from(j['recurrenceDays'] as List),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        recurrenceStartDate: j['recurrenceStartDate'] as String,
        recurrenceEndDate: j['recurrenceEndDate'] as String,
        isEnabled: false,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'recurrenceDays': days,
        'startTime': startTime,
        'endTime': endTime,
        'recurrenceStartDate': recurrenceStartDate,
        'recurrenceEndDate': recurrenceEndDate,
      };
}