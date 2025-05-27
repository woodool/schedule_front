import 'package:flutter/material.dart';
import '../widgets/title_input.dart';
import '../../../common_widgets/date_time_selector.dart';
import '../../../common_widgets/repeat_setting_box.dart';
import '../../../common_widgets/notification_setting_box.dart';
import '../../../common_widgets/category_setting_box.dart';
import '../../../common_widgets/priority_setting_box.dart';
import '../widgets/memo_input.dart';
import '../../../common_widgets/calendar_display_selector.dart';
import '../widgets/action_buttons.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/schedule.dart';
import '../../domain/services/schedule_service.dart';

class AddSchedulePage extends StatefulWidget {
  final DateTime? initialDate;
  
  const AddSchedulePage({
    super.key,
    this.initialDate,
  });

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  List<bool> _selectedDays = [false, false, false, false, false, false, false];
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  NotificationType _notificationType = NotificationType.none;
  int? _customMinutes;
  String _selectedCategory = '-';
  int? _categoryId;
  Priority? _selectedPriority;
  CalendarDisplayType _calendarDisplayType = CalendarDisplayType.show;
  String? _recurrenceDays;
  final ScheduleService _scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
    // 선택된 날짜가 있으면 해당 날짜를 사용, 없으면 현재 날짜 사용
    final DateTime now = widget.initialDate ?? DateTime.now();
    // 선택된 날짜의 날짜 정보만 가져옴
    _startDate = DateTime(
      now.year, 
      now.month, 
      now.day, 
      DateTime.now().hour, 
      DateTime.now().minute
    );
    // 마감 시간은 시작 시간 + 1시간으로 설정
    _endDate = _startDate.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    try {
      // recurrenceDays 설정
      String? recurrenceDays;
      if (_selectedDays.contains(true)) {
        recurrenceDays = _selectedDays.map((selected) => selected ? '1' : '0').join(',');
      }
      
      final schedule = Schedule(
        title: _titleController.text,
        description: _contentController.text,
        startTime: _startDate,
        endTime: _endDate,
        categoryId: _categoryId,
        priority: _selectedPriority?.value,
        displayOnCalendar: _calendarDisplayType == CalendarDisplayType.show,
        reminderMinutesBefore: _customMinutes,
        recurrenceDays: recurrenceDays,
        recurrenceStartDate: _recurrenceStartDate,
        recurrenceEndDate: _recurrenceEndDate,
      );

      await _scheduleService.createSchedule(schedule);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정이 성공적으로 등록되었습니다.')),
        );
        Navigator.of(context).pop(true); // ✅ 등록 성공했다는 표시
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TitleInput(
                      controller: _titleController,
                      onChanged: (value) {},
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
                          recurrenceStartDate: _recurrenceStartDate,
                          recurrenceEndDate: _recurrenceEndDate,
                          onDaysChanged: (days) {
                            setState(() {
                              _selectedDays = days;
                            });
                          },
                          onRecurrenceDaysChanged: (days) {
                            setState(() {
                              _recurrenceDays = days;
                            });
                          },
                          onRecurrenceStartDateChanged: (date) {
                            setState(() {
                              _recurrenceStartDate = date;
                            });
                          },
                          onRecurrenceEndDateChanged: (date) {
                            setState(() {
                              _recurrenceEndDate = date;
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
                    const SizedBox(height: 32),
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
                          onCategoryIdChanged: (id) {
                            setState(() {
                              _categoryId = id;
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
                      onChanged: (value) {},
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
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ActionButtons(
          onCancelPressed: () {
            Navigator.of(context).pop();
          },
          onSubmitPressed: _saveSchedule,
        ),
      ),
    );
  }
}
