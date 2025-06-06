import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../schedule/presentation/widgets/action_buttons.dart';
import '../../../common_widgets/title_input_field.dart';
import '../../../common_widgets/category_setting_box.dart';
import '../../../common_widgets/repeat_setting_box.dart';
import '../../domain/models/meeting_room.dart';
import '../../domain/services/meeting_service.dart';

class MeetingRoomCreatePage extends StatefulWidget {
  final String initialTitle;

  const MeetingRoomCreatePage({
    super.key,
    this.initialTitle = '',
  });

  @override
  State<MeetingRoomCreatePage> createState() => _MeetingRoomCreatePageState();
}

class _MeetingRoomCreatePageState extends State<MeetingRoomCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _meetingService = MeetingService();
  
  final _titleController = TextEditingController();
  String _selectedCategory = '-';
  int? _categoryId;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  // 반복 설정을 위한 상태
  List<bool> _selectedDays = List.generate(7, (_) => false);
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  String? _recurrenceDays;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle.isNotEmpty) {
      _titleController.text = widget.initialTitle;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0062FF),
              onPrimary: Colors.white,
              surface: Color(0xFF222222),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }
  
  Future<void> _createMeetingRoom() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');

      final meetingRoom = MeetingRoom(
        meetingName: _titleController.text,
        photoUrl: null,
        startDate: _recurrenceStartDate ?? DateTime.now(),
        endDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
        recurrenceStart: _recurrenceStartDate ?? DateTime.now(),
        recurrenceEnd: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
        timeOfDay: _time,
        categoryId: _categoryId!,  // null이 아님이 보장됨
        categoryName: _selectedCategory,
        capacity: 100,
        description: _descriptionController.text,
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      final createdRoom = await _meetingService.createMeetingRoom(meetingRoom);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모임방이 성공적으로 생성되었습니다.')),
        );
        Navigator.pop(context, createdRoom);
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모임방 생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '모임 만들기',
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                        // 모임 이름
                TitleInputField(
                  controller: _titleController,
                          hintText: '모임 이름을 입력하세요',
                ),
                const SizedBox(height: 32),
                
                        // 시간 선택
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                              '모임 시간',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                              onTap: _selectTime,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0062FF),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                
                        // 반복 설정과 카테고리를 같은 행에 배치
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
                              const SizedBox(width: 24),
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
                          ],
                        ),
                        const SizedBox(height: 32),

                        // 소개글
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '소개글',
                              style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 5,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: '모임을 소개해주세요',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.black),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.black),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.black),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '소개글을 입력해주세요';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                const SizedBox(height: 60),
              ],
                    ),
            ),
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
          onSubmitPressed: _createMeetingRoom,
        ),
      ),
    );
  }
}