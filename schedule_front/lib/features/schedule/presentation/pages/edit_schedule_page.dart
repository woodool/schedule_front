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
import '../../domain/models/Recurrence_option.Dart';
import '../../domain/services/schedule_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';

enum RecurrenceEditMode {
  single,      // 이 일정만 수정
  thisAndFuture, // 이 일정 및 향후 모든 일정 수정
  allSeries    // 전체 시리즈 수정
}

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
  
  // 반복 일정 관련 변수 추가
  bool _isRecurringEvent = false;
  RecurrenceEditMode _recurrenceEditMode = RecurrenceEditMode.allSeries;

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
    
    // 반복 설정 초기화
    _recurrenceDays = widget.schedule.recurrenceDays;
    print('반복 설정 초기화: 요일 문자열=$_recurrenceDays');
    
    // 반복 설정 있으면 처리
    if (_recurrenceDays != null && _recurrenceDays!.isNotEmpty) {
      // "1,0,1,0,1,0,0" 형식 (0/1로 표시된 요일 패턴)
      if (_recurrenceDays!.split(',').length == 7) {
        final days = _recurrenceDays!.split(',');
        for (int i = 0; i < 7 && i < days.length; i++) {
          _selectedDays[i] = days[i] == '1';
        }
        print('요일 패턴으로 설정된 요일: $_selectedDays');
      }
      // "1,3,5" 형식 (요일 번호 리스트) 
      else if (_recurrenceDays!.contains(',')) {
        final dayNumbers = _recurrenceDays!.split(',');
        for (int i = 0; i < 7; i++) {
          // 1부터 시작하는 요일 번호 (1=월요일, 7=일요일)
          _selectedDays[i] = dayNumbers.contains('${i + 1}');
        }
        print('요일 번호로 설정된 요일: $_selectedDays');
      }
      // 단일 요일 번호 (예: "3")
      else if (_recurrenceDays!.trim().isNotEmpty) {
        try {
          final dayNumber = int.parse(_recurrenceDays!.trim());
          if (dayNumber >= 1 && dayNumber <= 7) {
            for (int i = 0; i < 7; i++) {
              _selectedDays[i] = (i + 1 == dayNumber);
            }
            print('단일 요일 번호로 설정된 요일: $_selectedDays');
          }
        } catch (e) {
          print('요일 번호 파싱 실패: $_recurrenceDays');
        }
      }
      
      // 반복 일정인지 확인 (최소 하나의 요일이 선택되어 있으면 반복 일정)
      _isRecurringEvent = _selectedDays.contains(true);
      print('반복 일정 여부: $_isRecurringEvent');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 반복 일정 편집 모드 선택 다이얼로그 표시
  Future<RecurrenceEditMode?> _showRecurrenceEditDialog() async {
    return showDialog<RecurrenceEditMode>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('반복 일정 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('이 반복 일정을 어떻게 수정하시겠습니까?'),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('이 일정만 수정'),
                subtitle: const Text('현재 선택한 날짜의 일정만 수정합니다'),
                onTap: () {
                  Navigator.of(context).pop(RecurrenceEditMode.single);
                },
              ),
              ListTile(
                title: const Text('이 일정 및 향후 모든 일정 수정'),
                subtitle: const Text('선택한 날짜 및 향후 모든 일정을 수정합니다'),
                onTap: () {
                  Navigator.of(context).pop(RecurrenceEditMode.thisAndFuture);
                },
              ),
              ListTile(
                title: const Text('전체 시리즈 수정'),
                subtitle: const Text('모든 반복 일정을 수정합니다'),
                onTap: () {
                  Navigator.of(context).pop(RecurrenceEditMode.allSeries);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateSchedule() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }
    
    try {
      // 기본값으로 전체 시리즈 수정 모드 설정
      RecurrenceEditMode editMode = RecurrenceEditMode.allSeries;
      
      // 원래 일정에 반복 설정이 있거나, 사용자가 새로 반복 설정을 했는지 검사
      final bool originalHasRecurrence = widget.schedule.recurrenceDays != null && 
                                         widget.schedule.recurrenceDays!.isNotEmpty &&
                                         widget.schedule.recurrenceDays != "0,0,0,0,0,0,0";
      final bool currentHasRecurrence = _selectedDays.contains(true);
      
      // 원본이 반복 일정이거나 현재 반복 설정이 있는 경우 다이얼로그 표시
      if (originalHasRecurrence || currentHasRecurrence) {
        print('반복 일정 수정 모드 선택 다이얼로그 표시');
        final selectedMode = await _showRecurrenceEditDialog();
        if (selectedMode == null) {
          // 사용자가 취소함
          print('사용자가 수정 모드 선택을 취소함');
          return;
        }
        editMode = selectedMode;
        print('선택된 수정 모드: $editMode');
      }

      print('일정 수정 요청 - 원본 ID: ${widget.schedule.scheduleId}, 편집 모드: $editMode');
      final schedule = Schedule(
        id: widget.schedule.scheduleId,
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

      switch (editMode) {
        case RecurrenceEditMode.single:
          // 이 일정만 수정
          await _updateSingleOccurrence(schedule);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('일정이 수정되었습니다.'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        case RecurrenceEditMode.thisAndFuture:
          // 이 일정 및 향후 모든 일정 수정
          await _updateThisAndFutureOccurrences(schedule);
          // thisAndFuture에서는 내부적으로 Navigator.pop(context, true)를 호출하므로 여기서는 return
          return;
        case RecurrenceEditMode.allSeries:
          // 전체 시리즈 수정
          // 일정 객체에 옵션 필드 추가
          final Map<String, dynamic> scheduleJson = schedule.toJson();
          scheduleJson['option'] = 'ALL'; // 백엔드 DTO의 option 필드에 명시적 매핑
          
          // 로깅
          print('전체 시리즈 수정 - option 필드 추가: $scheduleJson');
          
          await _scheduleService.updateSchedule(
            schedule,
            option: 'ALL',
            preserveExcludedDates: true, // excludedDates 보존
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('반복 일정이 수정되었습니다.'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
      }

      if (mounted) {
        Navigator.of(context).pop(true); // true 반환하여 캘린더 새로고침 유도
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 수정 실패: $e')),
        );
      }
    }
  }
  
  // 이 일정만 수정하는 메서드
  Future<void> _updateSingleOccurrence(Schedule schedule) async {
    try {
      final scheduleId = widget.schedule.scheduleId;
      
      if (scheduleId == null) {
        throw Exception('일정 ID가 없습니다');
      }
      
      // 현재 날짜 구하기
      final currentDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        schedule.startTime.hour,
        schedule.startTime.minute,
      );
      
      print('단일 일정 수정 - 선택된 날짜: $currentDate');
      
      // 원본 일정 정보 가져오기 (시작일 확인 및 제외 로직을 위해)
      final originalSchedule = await _scheduleService.getScheduleById(scheduleId);
      
      // 반복 일정인지 확인
      final bool isRecurringEvent = originalSchedule.recurrenceDays != null && 
                                    originalSchedule.recurrenceDays!.isNotEmpty && 
                                    originalSchedule.recurrenceDays != "0,0,0,0,0,0,0";
      
      // 시작일 수정인지 확인
      bool isModifyingStartDate = false;
      if (isRecurringEvent && originalSchedule.recurrenceStartDate != null) {
        // 날짜 비교 (시간 무시)
        final modifyingDay = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final startDay = DateTime(
          originalSchedule.recurrenceStartDate!.year, 
          originalSchedule.recurrenceStartDate!.month, 
          originalSchedule.recurrenceStartDate!.day
        );
        
        isModifyingStartDate = modifyingDay.isAtSameMomentAs(startDay);
        print('시작일 수정 여부: $isModifyingStartDate');
      }
      
      // 시작일 수정인 경우: 기존 일정의 시작일을 다음 반복일로 변경
      if (isRecurringEvent && isModifyingStartDate) {
        print('시작일 수정 로직 실행: 기존 일정의 시작일을 다음 반복일로 변경');
        
        try {
          // 1. 다음 발생 일자 계산
          final List<int> activeDays = [];
          if (originalSchedule.recurrenceDays != null) {
            final dayList = originalSchedule.recurrenceDays!.split(',');
            for (int i = 0; i < dayList.length && i < 7; i++) {
              if (dayList[i] == '1') {
                activeDays.add(i);
              }
            }
          }
          
          // 제외된 날짜 목록
          List<String> excludedDates = [];
          if (originalSchedule.excludedDates != null && originalSchedule.excludedDates!.isNotEmpty) {
            excludedDates = originalSchedule.excludedDates!
                .split(',')
                .where((d) => d.isNotEmpty)
                .toList();
          }
          
          // 다음 발생일 계산
          DateTime? nextOccurrence;
          if (activeDays.isNotEmpty) {
            // 다음 날부터 최대 30일까지 검색
            for (int i = 1; i <= 30; i++) {
              final candidate = currentDate.add(Duration(days: i));
              // 요일 확인 (0:월, 1:화, ..., 6:일)
              final weekday = candidate.weekday % 7; // 0:일, 1:월, ..., 6:토 => 요일 변환 필요
              final adjustedWeekday = weekday == 0 ? 6 : weekday - 1; // 월:0, 화:1, ..., 일:6
              
              if (activeDays.contains(adjustedWeekday)) {
                // 이미 제외된 날짜인지 확인
                final candidateDateStr = candidate.toIso8601String().split('T')[0];
                if (!excludedDates.contains(candidateDateStr)) {
                  nextOccurrence = candidate;
                  break;
                }
              }
            }
          }
          
          if (nextOccurrence == null) {
            throw Exception('다음 반복 일자를 찾을 수 없습니다');
          }
          
          print('새로운 시작일: $nextOccurrence');
          
          // 2. 원본 일정 업데이트 (시작일 변경)
          final updateScheduleRequest = originalSchedule.copyWith(
            recurrenceStartDate: nextOccurrence,
            // startTime도 함께 변경 - 시간은 유지
            startTime: DateTime(
              nextOccurrence.year,
              nextOccurrence.month,
              nextOccurrence.day,
              originalSchedule.startTime.hour,
              originalSchedule.startTime.minute,
            ),
          );
          
          // 3. 백엔드에 일정 업데이트 요청 (ALL 옵션)
          await _scheduleService.updateSchedule(
            updateScheduleRequest,
            option: 'ALL',
          );
          
          print('기존 반복 일정 시작일 변경 완료');
        } catch (e) {
          print('시작일 변경 중 오류: $e');
          throw Exception('반복 일정 시작일 변경 실패: $e');
        }
      } 
      // 시작일이 아닌 경우: 기존 일정에 해당 날짜 제외 처리
      else if (isRecurringEvent) {
        // 날짜 문자열 형식 (yyyy-MM-dd)
        final dateStr = currentDate.toIso8601String().split('T')[0];
        
        // 제외된 날짜 목록
        List<String> excludedDates = [];
        if (originalSchedule.excludedDates != null && originalSchedule.excludedDates!.isNotEmpty) {
          excludedDates = originalSchedule.excludedDates!
              .split(',')
              .where((d) => d.isNotEmpty)
              .toList();
        }
        
        // 이미 제외 목록에 없는 경우에만 추가
        if (!excludedDates.contains(dateStr)) {
          excludedDates.add(dateStr);
          
          // 원본 일정 업데이트
          final updateExcludeRequest = originalSchedule.copyWith(
            excludedDates: excludedDates.join(','),
          );
          
          print('기존 일정에 해당 날짜 제외 처리: $dateStr');
          
          // 백엔드에 일정 업데이트 요청 (ALL 옵션)
          await _scheduleService.updateSchedule(
            updateExcludeRequest,
            option: 'ALL',
          );
          
          print('기존 일정에 날짜 제외 처리 완료');
        }
      }
      
      // 새 일정 생성 (단일 일정)
      final newSchedule = Schedule(
        title: schedule.title,
        description: schedule.description,
        startTime: currentDate,
        endTime: DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          schedule.endTime.hour,
          schedule.endTime.minute,
        ),
        categoryId: schedule.categoryId,
        priority: schedule.priority,
        displayOnCalendar: schedule.displayOnCalendar,
        reminderMinutesBefore: schedule.reminderMinutesBefore,
        // 중요: 반복 설정을 제거하고 단일 일정으로 변경
        recurrenceDays: "0,0,0,0,0,0,0",
        recurrenceStartDate: null,
        recurrenceEndDate: null,
      );
      
      // 새 일정 생성 요청
      await _scheduleService.createSchedule(newSchedule);
      
      print('단일 일정 수정 완료 (기존 일정 변경 후 새 일정 생성)');
    } catch (e) {
      print('단일 일정 수정 오류: $e');
      rethrow;
    }
  }
  
  // 이 일정 및 향후 모든 일정 수정하는 메서드
  Future<void> _updateThisAndFutureOccurrences(Schedule schedule) async {
    try {
      final scheduleId = widget.schedule.scheduleId;
      
      if (scheduleId == null) {
        throw Exception('일정 ID가 없습니다');
      }
      
      // 현재 날짜(선택한 일정 날짜) 구하기 - 시간까지 포함하여 정확한 발생일 지정
      final currentDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        schedule.startTime.hour,
        schedule.startTime.minute,
      );
      
      print('향후 일정 수정 - 선택된 날짜: $currentDate');
      
      // 서비스를 통해 이후 일정 모두 수정 (preserveExcludedDates 옵션 추가)
      await _scheduleService.updateSchedule(
        schedule,
        option: 'FUTURE',
        occurrenceDate: currentDate,
        preserveExcludedDates: true, // excludedDates 보존
      );
      
      print('향후 일정 수정 완료');
      
      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('향후 일정 수정이 완료되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // 캘린더 페이지로 이동하고 결과 true 반환 (캘린더에서 새로고침하도록)
      Navigator.pop(context, true);
    } catch (e) {
      print('향후 일정 수정 오류: $e');
      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('향후 일정 수정 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

