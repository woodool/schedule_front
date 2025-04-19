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
import '../../domain/models/notification_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'schedule_id_provider.dart';

class AddSchedulePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends ConsumerState<AddSchedulePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<bool> _selectedDays = [false, false, false, false, false, false, false];
  NotificationType _notificationType = NotificationType.none;
  int? _customMinutes;
  String _selectedCategory = '-'; // 기본값 설정
  Priority? _selectedPriority;
  CalendarDisplayType _calendarDisplayType =
      CalendarDisplayType.show; // 기본값은 달력 표시

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                            onCategoryChanged: (category) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                          const SizedBox(width: 35),
                          PrioritySettingBox(
                            selectedPriority: _selectedPriority,
                            onPriorityChanged: (priority) {
                              setState(() {
                                _selectedPriority = priority;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      MemoInput(
                        controller: _contentController,
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
                  final title = _titleController.text;
                  final start = _startDate.toIso8601String();
                  final end = _endDate.toIso8601String();
                  final memo = _contentController.text;

                  if (title.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("제목을 입력해주세요.")),
                    );
                    return;
                  }

                  if (_startDate.isAfter(_endDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("시작 시간이 종료 시간보다 늦을 수 없습니다.")),
                    );
                    return;
                  }

                  final priorityValue = _selectedPriority?.toInt() ?? 4;
                  final categoryId = CategorySettingBox.getCategoryIdFromName(
                      _selectedCategory);
                  final recurrenceDays = <int>[];
                  for (int i = 0; i < _selectedDays.length; i++) {
                    if (_selectedDays[i]) recurrenceDays.add(i);
                  }
                  final isRecurring = recurrenceDays.isNotEmpty;
                  final reminderMinutesBefore = getMinutesFromNotificationType(_notificationType.name, _customMinutes);
                  final User? user = _auth.currentUser; 
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("로그인 상태를 확인할 수 없습니다.")),
                    );
                    return;
                  }
                  final String userUid = user.uid;

                  final response = await http.post(
                    Uri.parse('http://10.0.2.2:8080/api/ScheduleDTO'),
                    headers: {'Content-Type':'application/json'},
                    body: jsonEncode({
                      'firebaseUid': userUid,
                      'title' : title,
                      'startTime' : start,
                      'endTime' : end,
                      'memo' : memo,
                      'priority': priorityValue,
                      'categoryId': categoryId,
                      'isRecurring': isRecurring,
                      'recurrenceDays': recurrenceDays,
                      'reminderMinutesBefore': reminderMinutesBefore,
                      'displayOnCalendar': _calendarDisplayType == CalendarDisplayType.show,
                    }),
                  );
                  if (response.statusCode == 201) {
                    final data = jsonDecode(response.body);
                    final scheduleId = data['id'];

                    ref.read(scheduleIdProvider.notifier).state = scheduleId;

                    Navigator.of(context).pop();
                  } else {
                    print("스케줄 저장 실패: ${response.body}");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("스케줄 저장에 실패했습니다.")),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
