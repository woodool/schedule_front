import 'package:flutter/material.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/reminder.dart';
import '../../domain/services/schedule_service.dart';
import '../../domain/services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScheduleService _scheduleService = ScheduleService();
  final ReminderService _reminderService = ReminderService();
  List<Schedule> _schedules = [];
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _username = '';
  DateTime? _createdAt;
  int _daysSinceCreation = 0;
  
  // 체크박스 상태를 전역으로 관리
  Map<String, bool> _checkedState = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken(true);
        
        final response = await http.get(
          Uri.parse(ApiConfig.userEndpoint),
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        );

        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          if (mounted) {
            setState(() {
              _username = userData['username'] ?? '';
              if (userData['createdAt'] != null) {
                _createdAt = DateTime.parse(userData['createdAt']);
                _daysSinceCreation = DateTime.now().difference(_createdAt!).inDays;
              }
            });
          }
        }
      }
    } catch (e) {
      // 사용자 정보 로드 실패 시 기본값 사용
      if (mounted) {
        setState(() {
          _username = FirebaseAuth.instance.currentUser?.displayName ?? '';
        });
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final schedules = await _scheduleService.getSchedules();
      final reminders = await _reminderService.getReminders();

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
        _reminders = reminders;
        _isLoading = false;
        
        // 체크박스 상태 초기화
        for (var reminder in _reminders) {
          if (reminder.reminderId != null) {
            _checkedState[reminder.reminderId!.toString()] = reminder.isActive == false;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 로드 실패: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      // 날짜가 변경되면 데이터 다시 로드
      _loadData();
    }
  }

  String _getFormattedDate() {
    final weekdayKorean = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayIndex = _selectedDate.weekday - 1; // 1(월) ~ 7(일) -> 0 ~ 6
    return '${DateFormat('yyyy/MM/dd').format(_selectedDate)}(${weekdayKorean[weekdayIndex]})';
  }

  // 체크박스 상태 변경 핸들러
  void _handleCheckboxChange(Reminder reminder, bool? value) async {
    if (reminder.reminderId == null) {
      print('리마인더 ID가 null입니다: $reminder');
      return;
    }
    
    final reminderId = reminder.reminderId.toString();
    
    // 즉시 UI 업데이트
    setState(() {
      _checkedState[reminderId] = value ?? false;
      
      // 체크된 항목은 목록 하단으로 이동하도록 정렬
      _getActiveReminders();
    });
    
    try {
      // 현재 날짜/시간 정보
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayString = today.toIso8601String();
      
      // 리마인더 객체 복사 및 isActive 업데이트
      Reminder updatedReminder = reminder.copyWith(
        isActive: !(value ?? false), // value true면 isActive false로
        date: todayString, // 항상 오늘 날짜로 설정
      );
      
      // 백엔드 업데이트 (백그라운드에서 처리)
      _reminderService.updateReminder(updatedReminder).catchError((e) {
        print('리마인더 업데이트 실패: $e');
        // 실패 시 체크 상태 원복
        if (mounted) {
          setState(() {
            _checkedState[reminderId] = !(value ?? false);
          });
        }
        return null;
      });
    } catch (e) {
      print('리마인더 업데이트 실패: $e');
      // 실패 시 체크 상태 원복
      if (mounted) {
        setState(() {
          _checkedState[reminderId] = !(value ?? false);
        });
      }
    }
  }
  
  // 활성화된 리마인더만 필터링 및 정렬
  List<Reminder> _getActiveReminders() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    // 1. 모든 리마인더 복사
    List<Reminder> filteredReminders = [..._reminders];
    
    // 2. 비활성화된 리마인더 중 오늘 이전 날짜인 것만 필터링
    filteredReminders = filteredReminders.where((reminder) {
      // 활성 상태면 항상 표시
      if (reminder.isActive == true) {
        return true;
      }
      
      // 비활성 상태(체크됨)인 경우
      if (reminder.isActive == false) {
        // date 필드가 없으면 필터링하지 않음 (오늘 체크된 항목으로 간주)
        if (reminder.date == null) {
          return true;
        }
        
        try {
          // 날짜 파싱
          final reminderDate = DateTime.parse(reminder.date!);
          final reminderDateOnly = DateTime(
            reminderDate.year, 
            reminderDate.month, 
            reminderDate.day
          );
          
          // 오늘 날짜면 표시, 오늘 이전이면 필터링
          return reminderDateOnly.isAtSameMomentAs(todayOnly);
        } catch (e) {
          // 날짜 파싱 오류 시 안전하게 표시
          print('날짜 파싱 오류: $e, reminder: $reminder');
          return true;
        }
      }
      
      return true; // 기본값은 표시
    }).toList();
    
    // 3. 정렬: 체크되지 않은 항목 먼저, 체크된 항목은 나중에
    filteredReminders.sort((a, b) {
      final reminderId1 = a.reminderId?.toString() ?? '';
      final reminderId2 = b.reminderId?.toString() ?? '';
      
      final isAChecked = _checkedState[reminderId1] ?? false;
      final isBChecked = _checkedState[reminderId2] ?? false;
      
      if (isAChecked && !isBChecked) return 1;
      if (!isAChecked && isBChecked) return -1;
      return 0;
    });
    
    return filteredReminders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: null,
      body: Column(
        children: [
          // 상단 흰색 배경 확장 (상태바까지)
          Container(
            color: Colors.white,
            width: double.infinity,
            child: Column(
              children: [
                // 상단 마진 44픽셀
                SizedBox(height: 44),
                // 커스텀 상단 프레임 (높이 50)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 왼쪽: 날짜 표시
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Text(
                          _getFormattedDate(),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w400, // Regular
                            height: 1.4, // 140% line height
                            letterSpacing: -0.4, // -2.5% letter spacing (16 * -0.025 = -0.4)
                            color: Color(0xFF0062FF), // 0062FF 색상
                          ),
                        ),
                      ),
                      // 오른쪽: 사용자 정보
                      Row(
                        children: [
                          Text(
                            '$_username님, $_daysSinceCreation일차',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w400, // Regular
                              height: 1.4, // 140% line height
                              letterSpacing: -0.4,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            'assets/images/userpage.png',
                            width: 28,
                            height: 28,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 메인 콘텐츠
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('오류: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 리마인더 섹션 (날짜 프레임과 거리 20)
                                const SizedBox(height: 20),
                                // 리마인더 제목
                                const Text(
                                  '리마인더',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600, // SemiBold
                                    height: 1.4,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF0062FF),
                                  ),
                                ),
                                // 리마인더 제목과 박스 사이 거리 10
                                const SizedBox(height: 10),
                                // 리마인더 박스
                                if (_reminders.isEmpty)
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Center(
                                        child: Text(
                                          '등록된 리마인더가 없습니다',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                            letterSpacing: -0.4,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _getActiveReminders().length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 5),
                                      itemBuilder: (context, index) {
                                        final reminder = _getActiveReminders()[index];
                                        final reminderId = reminder.reminderId?.toString() ?? '';
                                        final isChecked = _checkedState[reminderId] ?? false;
                                        
                                        return Container(
                                          height: 50,
                                          padding: const EdgeInsets.symmetric(horizontal: 5),
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: isChecked,
                                                onChanged: (value) {
                                                  _handleCheckboxChange(reminder, value);
                                                },
                                                activeColor: Colors.black,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  reminder.title,
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.4,
                                                    letterSpacing: -0.4,
                                                    color: isChecked 
                                                        ? const Color(0xFF767676)
                                                        : Colors.black,
                                                    decoration: isChecked 
                                                        ? TextDecoration.lineThrough 
                                                        : TextDecoration.none,
                                                    decorationColor: const Color(0xFF767676),
                                                    decorationThickness: 2,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                
                                // 일정 섹션
                                const SizedBox(height: 20),
                                const Text(
                                  '일정',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600, // SemiBold
                                    height: 1.4,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF0062FF),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                
                                if (_schedules.isEmpty)
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Center(
                                        child: Text(
                                          '등록된 일정이 없습니다',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                            letterSpacing: -0.4,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _schedules.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 5),
                                      itemBuilder: (context, index) {
                                        final schedule = _schedules[index];
                                        return Container(
                                          height: 50,
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  schedule.title,
                                                  style: const TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.4,
                                                    letterSpacing: -0.4,
                                                    color: Colors.black,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              if (schedule.priority != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEEF2FF),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '우선순위 ${schedule.priority}',
                                                    style: const TextStyle(
                                                      fontFamily: 'Pretendard',
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w400,
                                                      color: Color(0xFF0062FF),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                
                                // 추가 공간
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: AddButton(
        items: [
          AddButtonItem(
            label: '사진으로 일정 추가',
            iconPath: 'assets/images/image.png',
            onPressed: () {
              // TODO: 사진으로 일정 추가 기능 구현
            },
          ),
          AddButtonItem(
            label: '리마인더 추가',
            iconPath: 'assets/images/reminder.png',
            onPressed: () {
              Navigator.pushNamed(context, '/add_reminder').then((value) {
                if (value == true) _loadData();
              });
            },
          ),
          AddButtonItem(
            label: '일정 추가',
            iconPath: 'assets/images/schedule.png',
            onPressed: () {
              Navigator.pushNamed(context, '/add_schedule').then((value) {
                if (value == true) _loadData();
              });
            },
          ),
        ],
      ),
    );
  }
}
