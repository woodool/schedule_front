import 'package:flutter/material.dart';
import '../../../schedule/presentation/widgets/action_buttons.dart';
import '../../../common_widgets/date_only_selector.dart';
import '../../../common_widgets/category_setting_box.dart';
import '../../../common_widgets/priority_setting_box.dart';
import '../../../common_widgets/title_input_field.dart';
import '../../../schedule/domain/models/priority.dart';
import '../../domain/models/planning_room.dart';
import '../../domain/services/planning_service.dart';

class EditPlanningPage extends StatefulWidget {
  final PlanningRoom planningRoom;
  
  const EditPlanningPage({
    super.key,
    required this.planningRoom,
  });

  @override
  State<EditPlanningPage> createState() => _EditPlanningPageState();
}

class _EditPlanningPageState extends State<EditPlanningPage> {
  final TextEditingController _titleController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  late String _selectedCategory;
  late int? _categoryId;
  late Priority? _selectedPriority;
  late int _timeSlotUnit;
  final TextEditingController _customTimeController = TextEditingController();
  final PlanningService _planningService = PlanningService();
  bool _isLoading = false;

  // 시간 옵션과 일 옵션을 분리
  final List<int> _timeSlotOptions = [30, 60, 120]; // 30분, 1시간, 2시간
  final List<int> _daySlotOptions = [1, 2, 3]; // 1일, 2일, 3일

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }
  
  void _initializeFields() {
    // 계획방 정보로 필드 초기화
    _titleController.text = widget.planningRoom.roomName;
    _startDate = widget.planningRoom.startDate;
    _endDate = widget.planningRoom.endDate;
    _categoryId = widget.planningRoom.categoryId;
    _selectedPriority = Priority.fromValue(widget.planningRoom.priority);
    _timeSlotUnit = widget.planningRoom.timeSlotUnit;
    
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
    } else {
      _selectedCategory = '-';
    }
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

  // 수정된 PlanningRoom 객체 생성
  PlanningRoom _createUpdatedPlanningRoom() {
    return PlanningRoom(
      roomId: widget.planningRoom.roomId,
      roomName: _titleController.text,
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _categoryId,
      priority: _selectedPriority?.value,
      timeSlotUnit: _timeSlotUnit,
      inviteCode: widget.planningRoom.inviteCode,
      createdBy: widget.planningRoom.createdBy,
      createdAt: widget.planningRoom.createdAt,
    );
  }

  // 계획방 수정 및 저장
  Future<void> _updatePlanningRoom() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 이름을 입력해주세요')),
      );
      return;
    }
    
    if (widget.planningRoom.roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효하지 않은 일정 계획방입니다')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedPlanningRoom = _createUpdatedPlanningRoom();
      final result = await _planningService.updatePlanningRoom(
        widget.planningRoom.roomId!, 
        updatedPlanningRoom
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        // 수정된 PlanningRoom 객체를 반환 (이전 화면에서 처리)
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정 계획방 수정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          '일정 수정',
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
          onSubmitPressed: _updatePlanningRoom,
          submitText: '수정',
        ),
      ),
    );
  }
} 