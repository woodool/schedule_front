import 'package:flutter/material.dart';
import 'dart:io';
import 'title_input_field.dart';
import 'labeled_input_field.dart';
import '../../../../features/common_widgets/repeat_setting_box.dart';
import '../../../../features/common_widgets/category_setting_box.dart';
import '../../../../features/schedule/domain/models/schedule.dart';
import '../pages/club_room.dart';

class ClubRoomCreateDialog extends StatefulWidget {
  final Function(Schedule)? onSubmit;
  
  const ClubRoomCreateDialog({
    super.key,
    this.onSubmit,
  });

  static Future<Schedule?> show(BuildContext context) {
    return showDialog<Schedule>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.white,
        child: ClubRoomCreateDialog(),
      ),
    );
  }

  @override
  State<ClubRoomCreateDialog> createState() => _ClubRoomCreateDialogState();
}

class _ClubRoomCreateDialogState extends State<ClubRoomCreateDialog> {
  final TextEditingController _titleController = TextEditingController();
  File? _selectedImage;
  
  // 반복 일정 설정
  List<bool> _selectedDays = List.filled(7, false);
  String? _recurrenceDays;
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  
  // 시작일 설정
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  // 카테고리 설정
  String _selectedCategory = '-';
  int? _categoryId;
  
  // 참가인원 설정
  int _maxParticipants = 5;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // 날짜 선택 다이얼로그 표시
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 시간 설정 다이얼로그 표시
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  // 참가인원 설정 다이얼로그 표시
  Future<void> _selectParticipants(BuildContext context) async {
    int tempCount = _maxParticipants;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '참가인원 설정',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '최대 $tempCount명', 
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 20, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: tempCount.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  onChanged: (value) {
                    setState(() {
                      tempCount = value.round();
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(fontFamily: 'Pretendard'),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _maxParticipants = tempCount;
              });
              Navigator.pop(context);
            },
            child: const Text(
              '확인',
              style: TextStyle(fontFamily: 'Pretendard'),
            ),
          ),
        ],
      ),
    );
  }

  // 이미지 선택 콜백
  void _onImageSelected(File? image) {
    setState(() {
      _selectedImage = image;
    });
  }

  // 요일을 한글로 반환
  String _getDayOfWeekInKorean(int day) {
    const List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[(day - 1) % 7]; // 월요일=1, 화요일=2, ...
  }

  // AM/PM 시간 포맷
  String _formatTime(TimeOfDay time) {
    String period = time.hour < 12 ? '오전' : '오후';
    int hour = time.hour % 12;
    if (hour == 0) hour = 12;
    return '$period ${hour}시';
  }

  Schedule _createSchedule() {
    // 선택한 날짜와 시간으로 DateTime 생성
    final DateTime startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    // 종료 시간은 시작 시간 + 1시간
    final DateTime endTime = startTime.add(const Duration(hours: 1));
    
    return Schedule(
      title: _titleController.text,
      description: '', // 소개글은 빈 문자열로 설정
      startTime: startTime,
      endTime: endTime,
      recurrenceDays: _recurrenceDays,
      recurrenceStartDate: _recurrenceStartDate,
      recurrenceEndDate: _recurrenceEndDate,
      categoryId: _categoryId,
      displayOnCalendar: true,
      // 이미지 정보와 참가인원은 별도로 처리 필요
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Text(
                '모임 만들기',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.025,
                  color: Colors.black,
                ),
              ),
            ),
            
            // 모임 이름과 이미지 (수정된 위젯 사용)
            TitleInputField(
              controller: _titleController,
              onImageSelected: _onImageSelected,
            ),
            
            const SizedBox(height: 25),
            
            // 날짜 및 시간 정보 (이미지와 유사하게 표시)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '날짜 및 시간',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Text(
                      '${_selectedDate.month}월 ${_selectedDate.day}일 (${_getDayOfWeekInKorean(_selectedDate.weekday)})',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _selectTime(context),
                    child: Text(
                      _formatTime(_selectedTime),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            // 반복 설정 및 카테고리를 가운데 정렬
            Center(
              child: Column(
                children: [
                  Container(
                    width: 330,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 반복 설정
                          Container(
                            width: 150,
                            child: RepeatSettingBox(
                              selectedDays: _selectedDays,
                              onDaysChanged: (days) {
                                setState(() {
                                  _selectedDays = days;
                                });
                              },
                              onRecurrenceDaysChanged: (recurrenceDays) {
                                setState(() {
                                  _recurrenceDays = recurrenceDays;
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
                          ),
                          
                          const SizedBox(width: 24),
                          
                          // 카테고리
                          Container(
                            width: 150,
                            child: CategorySettingBox(
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 참가 인원 설정
                  Container(
                    width: 320, // 150 + 20 + 150 = 320
                    child: LabeledInputField(
                      label: '참가인원',
                      contentPadding: EdgeInsets.zero,
                      child: GestureDetector(
                        onTap: () => _selectParticipants(context),
                        child: InputContainer(
                          height: 45,
                          child: Center(
                            child: Text(
                              '$_maxParticipants명',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 방 만들기 버튼
            Container(
              width: 275,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모임 이름을 입력해주세요')),
                    );
                    return;
                  }
                  
                  final schedule = _createSchedule();
                  
                  if (widget.onSubmit != null) {
                    widget.onSubmit!(schedule);
                  }
                  
                  Navigator.of(context).pop(schedule);
                  
                  // 모임 생성 후 ClubRoom 페이지로 이동
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ClubRoom(
                        schedule: schedule,
                        isHost: true, // 모임을 생성한 사람은 방장
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0062FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Center(
                  child: Text(
                    '방 만들기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 