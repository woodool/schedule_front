import 'package:flutter/material.dart';
import '../widgets/title_input.dart';
import '../widgets/repeat_setting_box.dart';
import '../widgets/notification_setting_box.dart';
import '../widgets/action_buttons.dart';
import '../../domain/models/reminder.dart';
import '../../domain/services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';

// 반복 일정 편집 모드 enum 정의
enum RecurrenceEditMode {
  single,      // 이 일정만 수정/삭제
  allSeries    // 전체 시리즈 수정/삭제
}

class EditReminderPage extends StatefulWidget {
  final Reminder reminder;

  const EditReminderPage({super.key, required this.reminder});

  @override
  State<EditReminderPage> createState() => _EditReminderPageState();
}

class _EditReminderPageState extends State<EditReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  List<bool> _selectedDays = [false, false, false, false, false, false, false];
  NotificationType _notificationType = NotificationType.none;
  int? _customMinutes;
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  DateTime? _checkedDate;
  final ReminderService _reminderService = ReminderService();
  
  // 반복 리마인더 관련 변수 추가
  bool _isRecurringReminder = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _titleController.text = widget.reminder.reminder_title;
    _customMinutes = widget.reminder.reminderMinutesBefore;
    _notificationType = _customMinutes != null ? NotificationType.custom : NotificationType.none;
    _recurrenceStartDate = widget.reminder.recurrenceStartDate;
    _recurrenceEndDate = widget.reminder.recurrenceEndDate;
    _checkedDate = widget.reminder.checkedDate;
    
    // 반복 설정 초기화
    String recurrenceDays = widget.reminder.recurrenceDays;
    print('리마인더 반복 설정 초기화: 요일 문자열=$recurrenceDays');
    
    // 반복 설정 있으면 처리
    if (recurrenceDays.isNotEmpty) {
      // "1,0,1,0,1,0,0" 형식 (0/1로 표시된 요일 패턴)
      if (recurrenceDays.split(',').length == 7) {
        final days = recurrenceDays.split(',');
        for (int i = 0; i < 7 && i < days.length; i++) {
        _selectedDays[i] = days[i] == '1';
      }
        print('요일 패턴으로 설정된 요일: $_selectedDays');
      }
      // "1,3,5" 형식 (요일 번호 리스트) 
      else if (recurrenceDays.contains(',')) {
        final dayNumbers = recurrenceDays.split(',');
        for (int i = 0; i < 7; i++) {
          // 1부터 시작하는 요일 번호 (1=월요일, 7=일요일)
          _selectedDays[i] = dayNumbers.contains('${i + 1}');
        }
        print('요일 번호로 설정된 요일: $_selectedDays');
      }
      // 단일 요일 번호 (예: "3")
      else if (recurrenceDays.trim().isNotEmpty) {
        try {
          final dayNumber = int.parse(recurrenceDays.trim());
          if (dayNumber >= 1 && dayNumber <= 7) {
            for (int i = 0; i < 7; i++) {
              _selectedDays[i] = (i + 1 == dayNumber);
            }
            print('단일 요일 번호로 설정된 요일: $_selectedDays');
          }
        } catch (e) {
          print('요일 번호 파싱 실패: $recurrenceDays');
        }
      }
      
      // 반복 리마인더인지 확인 (최소 하나의 요일이 선택되어 있으면 반복 리마인더)
      _isRecurringReminder = _selectedDays.contains(true);
      print('반복 리마인더 여부: $_isRecurringReminder');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  // 반복 리마인더 편집 모드 선택 다이얼로그 표시
  Future<RecurrenceEditMode?> _showRecurrenceEditDialog() async {
    return showDialog<RecurrenceEditMode>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('반복 리마인더 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('이 반복 리마인더를 어떻게 수정하시겠습니까?'),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('이 리마인더만 수정'),
                subtitle: const Text('현재 선택한 날짜의 리마인더만 수정합니다'),
                onTap: () {
                  Navigator.of(context).pop(RecurrenceEditMode.single);
                },
              ),
              ListTile(
                title: const Text('모든 반복 리마인더 삭제'),
                subtitle: const Text('이 반복 리마인더의 모든 일정을 삭제합니다'),
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

  Future<void> _updateReminder() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    try {
      // 수정 시 항상 전체 반복 리마인더에 적용
      final reminder = Reminder(
        reminderId: widget.reminder.reminderId,
        reminder_title: _titleController.text,
        recurrenceDays: _selectedDays.map((day) => day ? '1' : '0').join(','),
        reminderMinutesBefore: _customMinutes,
        isActive: widget.reminder.isActive,
        date: widget.reminder.date,
        checkedDate: _checkedDate,
        recurrenceStartDate: _recurrenceStartDate,
        recurrenceEndDate: _recurrenceEndDate,
      );

      // 모든 반복 리마인더에 변경사항 적용
      await _reminderService.updateReminder(reminder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리마인더가 성공적으로 수정되었습니다.')),
        );
        // 'updated' 상태와 함께 결과 반환
        Navigator.of(context).pop({'status': 'updated', 'data': reminder});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리마인더 수정 실패: $e')),
        );
      }
    }
  }
  
  // 리마인더 삭제 다이얼로그 표시
  Future<bool> _showDeleteConfirmDialog() async {
    // 반복 리마인더인지 확인
    final isRecurring = widget.reminder.recurrenceDays.isNotEmpty && 
                       widget.reminder.recurrenceDays != "0,0,0,0,0,0,0";
    
    RecurrenceEditMode? deleteMode;
    
    // 반복 리마인더인 경우에만 다이얼로그 표시
    if (isRecurring) {
      deleteMode = await showDialog<RecurrenceEditMode>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('리마인더 삭제'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('삭제 범위를 선택해주세요'),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('이 리마인더만 삭제'),
                  subtitle: const Text('현재 선택한 날짜의 리마인더만 삭제합니다'),
                  onTap: () {
                    Navigator.of(context).pop(RecurrenceEditMode.single);
                  },
                ),
                ListTile(
                  title: const Text('모든 반복 리마인더 삭제'),
                  subtitle: const Text('이 반복 리마인더의 모든 일정을 삭제합니다'),
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
    } else {
      // 반복 리마인더가 아닌 경우 확인 다이얼로그만 표시
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('리마인더 삭제'),
            content: const Text('이 리마인더를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('삭제'),
              ),
            ],
          );
        },
      );
      
      if (confirm != true) {
        return false; // 삭제 취소
      }
      
      // 일회성 리마인더는 항상 전체 삭제
      deleteMode = RecurrenceEditMode.allSeries;
    }

    if (deleteMode == null) {
      return false; // 삭제 취소
    }

    try {
      if (deleteMode == RecurrenceEditMode.single) {
        // 이 리마인더만 삭제
        await _deleteSingleOccurrence();
      } else {
        // 전체 시리즈 삭제
        await _deleteAllSeries();
      }
      
      if (mounted) {
        if (deleteMode == RecurrenceEditMode.single) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('해당 리마인더가 삭제되었습니다')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리마인더가 삭제되었습니다')),
          );
        }
      }
      
      return true; // 삭제 성공
    } catch (e) {
      print('리마인더 삭제 중 오류 발생: $e');
      
      // 이미 삭제된 경우 성공으로 처리
      if (e.toString().contains('리마인더를 찾을 수 없습니다') || 
          e.toString().contains('404') || 
          e.toString().contains('400')) {
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리마인더가 삭제되었습니다')),
          );
        }
        return true;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리마인더 삭제 실패: $e')),
        );
      }
      return false; // 삭제 실패
    }
  }

  // 이 리마인더만 삭제
  Future<void> _deleteSingleOccurrence() async {
    // 현재 날짜 계산
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final reminderId = widget.reminder.reminderId;
    
    if (reminderId == null) {
      throw Exception('리마인더 ID가 없습니다');
    }
    
    // 반복 리마인더인지 확인
    final isRecurring = widget.reminder.recurrenceDays.isNotEmpty && 
                        widget.reminder.recurrenceDays != "0,0,0,0,0,0,0";
    
    if (isRecurring) {
      try {
        // 백엔드 API 호출: 반복 리마인더에서 현재 날짜 제외
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');
        
        final idToken = await user.getIdToken(true);
        
        // 반복 리마인더에서 특정 날짜 제외하는 API 호출
        final excludeResponse = await http.post(
          Uri.parse('${ApiConfig.remindersEndpoint}/$reminderId/exclude-occurrence'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: json.encode({
            'excludeDate': todayDate.toIso8601String(),
          }),
        );
        
        if (excludeResponse.statusCode != 200) {
          // 서버 응답 내용 확인
          print('서버 응답: ${excludeResponse.body}');
          
          // 404 또는 리마인더를 찾을 수 없는 오류는 이미 삭제된 것으로 간주하고 성공으로 처리
          if (excludeResponse.statusCode == 404 || 
              excludeResponse.statusCode == 400 ||
              excludeResponse.body.contains('리마인더를 찾을 수 없습니다')) {
            print('리마인더가 이미 삭제되었거나 존재하지 않습니다.');
            return; // 에러를 무시하고 성공으로 처리
          }
          
          throw Exception('반복 리마인더에서 날짜 제외 실패: ${excludeResponse.statusCode}');
        }
      } catch (e) {
        print('반복 리마인더에서 날짜 제외 오류: $e');
        
        // 404 또는 리마인더를 찾을 수 없는 오류는 이미 삭제된 것으로 간주하고 성공으로 처리
        if (e.toString().contains('리마인더를 찾을 수 없습니다') || 
            e.toString().contains('404') || 
            e.toString().contains('400')) {
          print('리마인더가 이미 삭제되었거나 존재하지 않습니다.');
          return; // 에러를 무시하고 성공으로 처리
        }
        
        rethrow; // 다른 종류의 오류는 다시 발생시킴
      }
    } else {
      // 일회성 리마인더인 경우 완전히 삭제
      try {
        await _reminderService.deleteReminder(reminderId);
      } catch (e) {
        print('리마인더 삭제 오류: $e');
        
        // 404 또는 리마인더를 찾을 수 없는 오류는 이미 삭제된 것으로 간주하고 성공으로 처리
        if (e.toString().contains('리마인더를 찾을 수 없습니다') || 
            e.toString().contains('404') || 
            e.toString().contains('400')) {
          print('리마인더가 이미 삭제되었거나 존재하지 않습니다.');
          return; // 에러를 무시하고 성공으로 처리
        }
        
        rethrow; // 다른 종류의 오류는 다시 발생시킴
      }
    }
  }

  // 전체 시리즈 삭제
  Future<void> _deleteAllSeries() async {
    final reminderId = widget.reminder.reminderId;
    
    if (reminderId == null) {
      throw Exception('리마인더 ID가 없습니다');
    }
    
    try {
      await _reminderService.deleteReminder(reminderId);
    } catch (e) {
      print('리마인더 삭제 오류: $e');
      // 404 또는 리마인더를 찾을 수 없는 오류는 이미 삭제된 것으로 간주하고 성공으로 처리
      if (e.toString().contains('리마인더를 찾을 수 없습니다') || 
          e.toString().contains('404') || 
          e.toString().contains('400')) {
        print('리마인더가 이미 삭제되었거나 존재하지 않습니다.');
        return; // 에러를 무시하고 성공으로 처리
      }
      rethrow; // 다른 종류의 오류는 다시 발생시킴
    }
  }

  // 삭제 성공 시 결과값 반환하는 함수
  void _returnDeleteResult() {
    if (mounted) {
      // 'deleted' 상태와 함께 결과 반환
      Navigator.of(context).pop({'status': 'deleted', 'id': widget.reminder.reminderId});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final deleted = await _showDeleteConfirmDialog();
              if (deleted && mounted) {
                _returnDeleteResult();
              }
            },
          ),
        ],
      ),
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
                            // recurrenceDays 값 저장 로직 (필요 시)
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
          onSubmitPressed: _updateReminder,
          submitText: '수정',
        ),
      ),
    );
  }
} 