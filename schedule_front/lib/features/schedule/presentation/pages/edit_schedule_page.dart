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
import '../../domain/models/schedule.dart';
import '../../domain/services/schedule_service.dart';

class EditSchedulePage extends StatefulWidget {
  final Schedule schedule;

  const EditSchedulePage({super.key, required this.schedule});

  @override
  State<EditSchedulePage> createState() => _EditSchedulePageState();
}

class _EditSchedulePageState extends State<EditSchedulePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  List<bool> _selectedDays = [false, false, false, false, false, false, false];
  NotificationType _notificationType = NotificationType.none;
  int? _customMinutes;
  String _selectedCategory = '-';
  late int? _categoryId;
  Priority? _selectedPriority;
  CalendarDisplayType _calendarDisplayType = CalendarDisplayType.show;
  String? _recurrenceDays;
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  final ScheduleService _scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    print('일정 수정 초기화 - ID: ${widget.schedule.scheduleId}');
    
    _titleController.text = widget.schedule.title;
    _contentController.text = widget.schedule.description ?? '';
    _startDate = widget.schedule.startTime;
    _endDate = widget.schedule.endTime;
    _categoryId = widget.schedule.categoryId;
    _selectedPriority = Priority.fromValue(widget.schedule.priority);
    _calendarDisplayType = widget.schedule.displayOnCalendar ?? true 
        ? CalendarDisplayType.show 
        : CalendarDisplayType.hide;
    _customMinutes = widget.schedule.reminderMinutesBefore;
    _recurrenceStartDate = widget.schedule.recurrenceStartDate;
    _recurrenceEndDate = widget.schedule.recurrenceEndDate;
    
    // 카테고리 정보 초기화
    if (_categoryId != null) {
      // 카테고리 ID에 따른 이름 설정
      switch (_categoryId) {
        case 14:
          _selectedCategory = '업무';
          break;
        case 15:
          _selectedCategory = '학업';
          break;
        case 16:
          _selectedCategory = '약속';
          break;
        case 17:
          _selectedCategory = '운동';
          break;
        case 18:
          _selectedCategory = '취미';
          break;
        case 19:
          _selectedCategory = '-';
          break;
        default:
          _selectedCategory = '-';
      }
      print('카테고리 초기화: ID=$_categoryId, 이름=$_selectedCategory');
    }
    
    // 알림 타입 설정
    if (widget.schedule.reminderMinutesBefore != null) {
      final minutes = widget.schedule.reminderMinutesBefore!;
      if (minutes == 10) {
        _notificationType = NotificationType.tenMinutes;
      } else if (minutes == 60) {
        _notificationType = NotificationType.oneHour;
      } else if (minutes == 1440) { // 24시간 (1일)
        _notificationType = NotificationType.oneDay;
      } else if (minutes > 0) {
        _notificationType = NotificationType.custom;
        _customMinutes = minutes;
      } else {
        _notificationType = NotificationType.none;
      }
      print('알림 설정 초기화: 분=$minutes, 타입=$_notificationType');
    } else {
      _notificationType = NotificationType.none;
    }
    
    // 반복 설정
    _recurrenceDays = widget.schedule.recurrenceDays;
    if (_recurrenceDays != null && _recurrenceDays!.isNotEmpty) {
      print('반복 설정: $_recurrenceDays');
      final days = _recurrenceDays!.split(',');
      if (days.length == 7) {
        for (int i = 0; i < 7; i++) {
          _selectedDays[i] = days[i] == '1';
        }
        print('선택된 요일: $_selectedDays');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updateSchedule() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    try {
      print('일정 수정 요청 - 원본 ID: ${widget.schedule.scheduleId}');
      final schedule = Schedule(
        scheduleId: widget.schedule.scheduleId,
        title: _titleController.text,
        description: _contentController.text,
        startTime: _startDate,
        endTime: _endDate,
        categoryId: _categoryId,
        priority: _selectedPriority?.value,
        displayOnCalendar: _calendarDisplayType == CalendarDisplayType.show,
        reminderMinutesBefore: _customMinutes,
        recurrenceDays: _selectedDays.map((selected) => selected ? '1' : '0').join(','),
        recurrenceStartDate: _recurrenceStartDate,
        recurrenceEndDate: _recurrenceEndDate,
      );
      print('수정할 일정 데이터: ${schedule.toJson()}');

      await _scheduleService.updateSchedule(schedule);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 수정 실패: $e')),
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
                          recurrenceStartDate: _recurrenceStartDate,
                          recurrenceEndDate: _recurrenceEndDate,
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
                          categoryId: _categoryId,
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
          onSubmitPressed: _updateSchedule,
          submitText: '수정',
        ),
      ),
    );
  }
}

