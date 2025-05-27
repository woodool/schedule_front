import 'package:flutter/material.dart';
import '../../../schedule/presentation/widgets/action_buttons.dart';
import '../../../common_widgets/date_time_selector.dart';
import '../../../common_widgets/date_only_selector.dart';
import '../../../common_widgets/category_setting_box.dart';
import '../../../common_widgets/priority_setting_box.dart';
import '../../../common_widgets/title_input_field.dart';
import '../../../schedule/domain/models/priority.dart';
import '../../domain/models/planning_room.dart';
import '../../domain/services/planning_service.dart';
import 'package:go_router/go_router.dart';

class CreatePlanningPage extends StatefulWidget {
  final String initialTitle;
  
  const CreatePlanningPage({
    super.key,
    this.initialTitle = '',
  });

  @override
  State<CreatePlanningPage> createState() => _CreatePlanningPageState();
}

class _CreatePlanningPageState extends State<CreatePlanningPage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _selectedCategory = '-';
  int? _categoryId;
  Priority? _selectedPriority;
  int _timeSlotUnit = 30; // 기본값 30분
  final TextEditingController _customTimeController = TextEditingController();
  final PlanningService _planningService = PlanningService();
  bool _isLoading = false;

  // 시간 옵션과 일 옵션을 분리
  final List<int> _timeSlotOptions = [30, 60, 120]; // 30분, 1시간, 2시간
  final List<int> _daySlotOptions = [1, 2, 3]; // 1일, 2일, 3일

  @override
  void initState() {
    super.initState();
    // 제목 초기화 (제목만 유지)
    if (widget.initialTitle.isNotEmpty) {
      _titleController.text = widget.initialTitle;
    }
    
    // 현재 날짜로 시작 날짜 설정
    _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // 마감 날짜는 시작 날짜 + 1일로 설정
    _endDate = DateTime(_startDate.year, _startDate.month, _startDate.day + 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customTimeController.dispose();
    super.dispose();
  }

  // 시간 단위 표시 텍스트
  String _getTimeSlotUnitText(int minutes) {
    if (minutes < 60) {
      return '$minutes분';
    } else if (minutes < 1440) { // 1440분 = 24시간 = 1일
      return '${minutes ~/ 60}시간';
    } else {
      return '${minutes ~/ 1440}일';
    }
  }

  // 시간 단위 선택 모달 바텀 시트
  void _selectTimeSlotUnit() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '시간 단위 선택',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '시간 단위',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _timeSlotOptions.map((option) {
                  return ChoiceChip(
                    label: Text(_getTimeSlotUnitText(option)),
                    selected: _timeSlotUnit == option,
                    onSelected: (selected) {
                      if (selected) {
                        this.setState(() {
                          _timeSlotUnit = option;
                        });
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                '일 단위',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _daySlotOptions.map((days) {
                  final minutes = days * 1440; // 1일 = 1440분
                  return ChoiceChip(
                    label: Text('$days일'),
                    selected: _timeSlotUnit == minutes,
                    onSelected: (selected) {
                      if (selected) {
                        this.setState(() {
                          _timeSlotUnit = minutes;
                        });
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('직접 설정'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showCustomTimeDialog();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0062FF),
                    side: const BorderSide(color: Color(0xFF0062FF)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 직접 설정 다이얼로그
  void _showCustomTimeDialog() {
    _customTimeController.text = _timeSlotUnit >= 1440
        ? (_timeSlotUnit ~/ 1440).toString() // 일 단위로 변환
        : _timeSlotUnit.toString(); // 분 단위 그대로
    
    // 단위 선택용 라디오 버튼 상태
    String _selectedUnitType = _timeSlotUnit >= 1440 ? 'day' : 'minute';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              '시간 단위 직접 설정',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customTimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _selectedUnitType == 'day'
                        ? '일 단위 입력 (1~30)'
                        : '분 단위 입력 (5~120)',
                    labelStyle: const TextStyle(
                      fontFamily: 'Pretendard',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 단위 선택 라디오 버튼
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          '분',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                          ),
                        ),
                        value: 'minute',
                        groupValue: _selectedUnitType,
                        onChanged: (value) {
                          setState(() {
                            _selectedUnitType = value!;
                            // 일에서 분으로 변환된 경우 기본값 30분 설정
                            if (value == 'minute') {
                              _customTimeController.text = '30';
                            }
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          '일',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                          ),
                        ),
                        value: 'day',
                        groupValue: _selectedUnitType,
                        onChanged: (value) {
                          setState(() {
                            _selectedUnitType = value!;
                            // 분에서 일로 변환된 경우 기본값 1일 설정
                            if (value == 'day') {
                              _customTimeController.text = '1';
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                Text(
                  _selectedUnitType == 'day'
                      ? '1일 이상, 30일 이하로 설정해주세요.'
                      : '5분 이상, 120분 이하로 설정해주세요.',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final value = int.tryParse(_customTimeController.text);
                  if (value != null) {
                    // 선택된 단위에 따라 유효성 검사 및 변환
                    if (_selectedUnitType == 'day') {
                      if (value >= 1 && value <= 30) {
                        this.setState(() {
                          _timeSlotUnit = value * 1440; // 일 -> 분 변환
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('1일 이상, 30일 이하로 설정해주세요.'),
                          ),
                        );
                      }
                    } else { // 분 단위
                      if (value >= 5 && value <= 120) {
                        this.setState(() {
                          _timeSlotUnit = value;
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('5분 이상, 120분 이하로 설정해주세요.'),
                          ),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('유효한 숫자를 입력해주세요.'),
                      ),
                    );
                  }
                },
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: Color(0xFF0062FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // PlanningRoom 객체 생성
  PlanningRoom _createPlanningRoom() {
    return PlanningRoom(
      roomName: _titleController.text,
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _categoryId,
      priority: _selectedPriority?.value,
      timeSlotUnit: _timeSlotUnit,
    );
  }

  // 계획방 생성 및 저장
  Future<void> _savePlanningRoom() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 이름을 입력해주세요')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final planningRoom = _createPlanningRoom();
      final createdRoom = await _planningService.createPlanningRoom(planningRoom);
      
      // 방 생성 성공 시에만 화면 전환
      print('방 생성 성공: roomId=${createdRoom.roomId}, name=${createdRoom.roomName}');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 계획방이 성공적으로 생성되었습니다.')),
        );
        
        // 방장인 경우 roomId가 존재하는지 확인
        if (createdRoom.roomId != null) {
          // 계획방 화면으로 이동
          context.pushReplacement('/planning/room', extra: {
            'planningRoom': createdRoom,
            'participantCount': 1, // 방장만 있으므로 기본값 1
            'userId': createdRoom.createdBy,
          });
        } else {
          // roomId가 없는 경우 에러 처리
          _showErrorWithHelp('생성된 방 ID가 없습니다. 다시 시도해주세요.');
        }
      }
    } catch (e) {
      // 오류 발생 시 화면이 넘어가지 않도록 처리
      _showErrorWithHelp(e.toString().replaceAll('Exception: ', ''));
    }
  }
  
  // 에러 메시지와 도움말 표시
  void _showErrorWithHelp(String message) {
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      // 네트워크 연결 오류인 경우 도움말 버튼 추가
      if (message.contains('서버 연결') || message.contains('네트워크')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '도움말',
              onPressed: () => _showNetworkHelpDialog(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }
  
  // 네트워크 연결 도움말 대화상자
  void _showNetworkHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('네트워크 연결 도움말'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('서버에 연결할 수 없습니다. 다음 사항을 확인해보세요:'),
              SizedBox(height: 16),
              Text('1. 서버 실행 상태 확인'),
              Text('   - Spring Boot 서버가 실행 중인지 확인'),
              Text('   - 서버가 8080 포트를 사용하는지 확인'),
              SizedBox(height: 8),
              Text('2. API 주소 설정 확인'),
              Text('   - 현재 설정: api_config.dart 파일의 baseUrl'),
              Text('   - 실제 기기와 서버가 같은 네트워크에 있는지 확인'),
              SizedBox(height: 8),
              Text('3. 방화벽 설정 확인'),
              Text('   - Windows 방화벽에서 8080 포트 허용'),
              SizedBox(height: 8),
              Text('4. 같은 WiFi 네트워크 확인'),
              Text('   - 서버와 기기가 같은 네트워크에 연결되어 있어야 함'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
          '일정 잡기',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // 일정 이름 (공통 위젯 사용)
                      TitleInputField(
                        controller: _titleController,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 기간 설정
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DateOnlySelector(
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
                      
                      // 시간 단위 선택
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '시간 단위',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectTimeSlotUnit,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getTimeSlotUnitText(_timeSlotUnit),
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0062FF),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
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
                      
                      // 카테고리 & 우선순위
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
                      
                      const SizedBox(height: 60),
                    ],
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
          onSubmitPressed: _savePlanningRoom,
        ),
      ),
    );
  }
} 