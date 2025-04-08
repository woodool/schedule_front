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

class AddSchedulePage extends StatefulWidget {
  const AddSchedulePage({super.key});

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<bool> _selectedDays = [false, false, false, false, false, false, false];
  NotificationType _notificationType = NotificationType.none;
  int? _customMinutes;
  String _selectedCategory = '-';  // 기본값 설정
  Priority? _selectedPriority;
  CalendarDisplayType _calendarDisplayType = CalendarDisplayType.show; // 기본값은 달력 표시

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
                onSubmitPressed: () {
                  // 나중에 DB 연결 시 여기에 일정 저장 로직 추가
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
