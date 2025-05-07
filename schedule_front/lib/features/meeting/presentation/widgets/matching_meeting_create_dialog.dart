import 'package:flutter/material.dart';
import '../../../../features/schedule/presentation/widgets/action_buttons.dart';
import '../../../../features/common_widgets/date_time_selector.dart';
import '../../../../features/common_widgets/category_setting_box.dart';
import '../../../../features/common_widgets/priority_setting_box.dart';
import 'title_input_field.dart';
import '../../../../features/schedule/domain/models/priority.dart';
import '../../../../features/schedule/domain/models/schedule.dart';
import '../pages/matching_schedule_room.dart';

class MatchingMeetingCreateDialog extends StatefulWidget {
  final Function(Schedule)? onSubmit;
  final String initialTitle; // 제목 초기값
  
  const MatchingMeetingCreateDialog({
    super.key,
    this.onSubmit,
    this.initialTitle = '',
  });

  static Future<Schedule?> show(BuildContext context, {String initialTitle = ''}) {
    return showDialog<Schedule>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.white,
        child: MatchingMeetingCreateDialog(initialTitle: initialTitle),
      ),
    );
  }

  @override
  State<MatchingMeetingCreateDialog> createState() => _MatchingMeetingCreateDialogState();
}

class _MatchingMeetingCreateDialogState extends State<MatchingMeetingCreateDialog> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  String _selectedCategory = '-';
  int? _categoryId;
  Priority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    // 제목 초기화 (제목만 유지)
    if (widget.initialTitle.isNotEmpty) {
      _titleController.text = widget.initialTitle;
    }
    
    // 현재 시간으로 시작 시간 설정
    _startDate = DateTime.now();
    // 마감 시간은 시작 시간 + 1시간으로 설정
    _endDate = _startDate.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Schedule _createSchedule() {
    return Schedule(
      title: _titleController.text,
      description: '매칭 미팅',
      startTime: _startDate,
      endTime: _endDate,
      categoryId: _categoryId,
      priority: _selectedPriority?.value,
      displayOnCalendar: true,
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
                '일정 잡기',
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
            
            // 일정 이름 (공통 위젯 사용)
            TitleInputField(
              controller: _titleController,
            ),
            
            // 기간 설정
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DateTimeSelector(
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
            ),
            
            // 카테고리 & 우선순위
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
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
                  const SizedBox(width: 20),
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
            ),
            
            // 방 만들기 버튼
            Container(
              width: 275,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('일정 이름을 입력해주세요')),
                    );
                    return;
                  }
                  
                  final schedule = _createSchedule();
                  
                  if (widget.onSubmit != null) {
                    widget.onSubmit!(schedule);
                  }
                  
                  // 방 만들기 후 매칭 일정 화면으로 이동
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MatchingScheduleRoom(
                        schedule: schedule,
                        participantCount: 6, // 기본값
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