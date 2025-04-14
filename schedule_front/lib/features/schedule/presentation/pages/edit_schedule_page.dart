import 'package:flutter/material.dart';
import '../widgets/title_input.dart';
import '../widgets/date_time_selector.dart';
import '../widgets/repeat_setting_box.dart';
import '../widgets/notification_setting_box.dart';
import '../widgets/category_setting_box.dart';
import '../widgets/priority_setting_box.dart';
import '../widgets/memo_input.dart';
import '../widgets/calendar_display_selector.dart';
import '../widgets/action_buttons.dart';
import '../../domain/models/priority.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditSchedulePage extends ConsumerStatefulWidget {
  const EditSchedulePage({super.key});

  @override
  ConsumerState<EditSchedulePage> createState() => _EditSchedulePageState();
}

class _EditSchedulePageState extends ConsumerState<EditSchedulePage> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _startDate = DateTime(2023, 12, 12, 22); // 12월 12일 오후 10시
  DateTime _endDate = DateTime(2023, 12, 15, 23); // 12월 15일 오후 11시
  List<bool> _selectedDays = [false, false, false, false, false, false, false];
  NotificationType _notificationType = NotificationType.none;
  int? _customMinutes;
  String? _selectedCategory;
  Priority? _selectedPriority;
  CalendarDisplayType _calendarDisplayType =
      CalendarDisplayType.show; // 기본값은 달력 표시

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleId = ref.watch(scheduleIdProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      TitleInput(
                        controller: _titleController,
                        onChanged: (value) {
                          // TODO: 제목 변경 처리
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DateTimeSelector(
                            startDate: _startDate,
                            endDate: _endDate,
                            onStartDateChanged: (date) {
                              setState(() {
                                _startDate = date;
                              });
                            },
                            onEndDateChanged: (date) {
                              setState(() {
                                _endDate = date;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RepeatSettingBox(
                            selectedDays: _selectedDays,
                            onDaysChanged: (days) {
                              setState(() {
                                _selectedDays = days;
                              });
                            },
                          ),
                          const SizedBox(width: 35),
                          NotificationSettingBox(
                            notificationType: _notificationType,
                            customMinutes: _customMinutes,
                            onTypeChanged: (type) {
                              setState(() {
                                _notificationType = type;
                              });
                            },
                            onCustomMinutesChanged: (minutes) {
                              setState(() {
                                _customMinutes = minutes;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CategorySettingBox(
                            selectedCategory: _selectedCategory,
                          ),
                          const SizedBox(width: 35),
                          PrioritySettingBox(
                            selectedPriority: _selectedPriority,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      MemoInput(
                        controller: _memoController,
                        onChanged: (value) {
                          // TODO: 메모 변경 처리
                        },
                      ),
                      const SizedBox(height: 32),
                      CalendarDisplaySelector(
                        selectedType: _calendarDisplayType,
                        onTypeSelected: (type) {
                          setState(() {
                            _calendarDisplayType = type;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ActionButtons(
                onCancelPressed: () {
                  Navigator.of(context).pop();
                },
                onSubmitPressed: () async {
                  if (scheduleId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('잘못된 접근입니다 (ID 없음).')),
                    );
                    return;
                  }

                  final title = _titleController.text.trim();
                  final memo = _memoController.text.trim();
                  final start = _startDate.toIso8601String();
                  final end = _endDate.toIso8601String();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('제목을 입력해주세요.')),
                    );
                    return;
                  }

                  if (_endDate.isBefore(_startDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('종료 시간이 시작 시간보다 빠를 수 없습니다.')),
                    );
                    return;
                  }

                  final recurrenceDays = <int>[];
                  for (int i = 0; i < _selectedDays.length; i++) {
                    if (_selectedDays[i]) recurrenceDays.add(i);
                  }
                  final isRecurring = recurrenceDays.isNotEmpty;
                  final reminderMinutesBefore = getMinutesFromNotificationType(
                      _notificationType.name, _customMinutes);
                  final priorityValue = _selectedPriority?.toInt() ?? 4;
                  final body = jsonEncode({
                    'title': title,
                    'startTime': start,
                    'endTime': end,
                    'isRecurring': isRecurring,
                    'recurrenceDays': recurrenceDays,
                    'reminderMinutesBefore': reminderMinutesBefore,
                    'categoryId': _selectedCategory,
                    'priority': priorityValue,
                    'memo': memo,
                    'displayOnCalendar':
                        _calendarDisplayType == CalendarDisplayType.show,
                  });

                  final response = await http.put(
                    Uri.parse('http://10.0.2.2:8080/api/schedules/$scheduleId'),
                    headers: {'Content-Type': 'application/json'},
                    body: body,
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('일정이 성공적으로 수정되었습니다.')),
                    );
                    Navigator.of(context).pop();
                  } else {
                    print('일정 수정 실패: ${response.body}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('일정 수정에 실패했습니다.')),
                    );
                  }
                },
                cancelText: '취소',
                submitText: '수정',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
