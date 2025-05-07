import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../widgets/action_buttons.dart';
import '../widgets/calendar_active_check.dart';

class ScheduleFromSchedulePage extends StatefulWidget {
  final File? initialImage;
  
  const ScheduleFromSchedulePage({super.key, this.initialImage});

  @override
  State<ScheduleFromSchedulePage> createState() => _ScheduleFromSchedulePageState();
}

class _ScheduleFromSchedulePageState extends State<ScheduleFromSchedulePage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  // 더미 데이터 (6개로 늘림)
  final List<Map<String, dynamic>> _scheduleItems = [
    {
      'title': '안녕하냥이ㅇㅇㅇㅇㅇㅇ',
      'dateRange': '2025/12/11 ~ 2025/12/30',
      'timeRange': '21:00 ~ 22:00',
      'isEnabled': false,  // 달력에 미표시
    },
    {
      'title': '안녕하냥이ㅇㅇㅇㅇㅇㅇ',
      'dateRange': '2025/12/11 ~ 2025/12/30',
      'timeRange': '21:00 ~ 22:00',
      'isEnabled': true,  // 달력에 표시
    },
    {
      'title': '안녕하냥이ㅇㅇㅇㅇㅇㅇ',
      'dateRange': '2025/12/11 ~ 2025/12/30',
      'timeRange': '21:00 ~ 22:00',
      'isEnabled': false,  // 달력에 미표시
    },
    {
      'title': '안녕하냥이ㅇㅇㅇㅇㅇㅇ',
      'dateRange': '2025/12/11 ~ 2025/12/30',
      'timeRange': '21:00 ~ 22:00',
      'isEnabled': false,  // 달력에 미표시
    },
    {
      'title': '안녕하냥이ㅇㅇㅇㅇㅇㅇ',
      'dateRange': '2025/12/11 ~ 2025/12/30',
      'timeRange': '21:00 ~ 22:00',
      'isEnabled': true,  // 달력에 표시
    },
    {
      'title': '안녕하냥이ㅇㅇㅇㅇㅇㅇ',
      'dateRange': '2025/12/11 ~ 2025/12/30',
      'timeRange': '21:00 ~ 22:00',
      'isEnabled': false,  // 달력에 미표시
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _selectedImage = widget.initialImage;
    } else {
      _pickImage();
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        // 여기서 나중에 이미지 인식 처리 로직이 추가될 예정
      } else {
        // 이미지 선택을 취소한 경우
        if (_selectedImage == null) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('사진 일정 등록'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _scheduleItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10), // 항목 간 간격 10
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemBuilder: (context, index) {
                final item = _scheduleItems[index];
                return _buildScheduleItem(item, index);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ActionButtons(
          onCancelPressed: () {
            Navigator.of(context).pop();
          },
          onSubmitPressed: () {
            // 다이얼로그로 CalendarActiveCheckWidget 표시
            CalendarActiveCheckWidget.show(
              context, 
              _scheduleItems,
            ).then((result) {
              // 결과 처리
              if (result != null) {
                // TODO: 최종 결과를 백엔드로 전송하는 로직 추가
                Navigator.pop(context);
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 제목, 날짜, 시간 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400, // Regular
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4), // 간격 4
                // 날짜
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      item['dateRange'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600, // SemiBold
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // 간격 4
                // 시간
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      item['timeRange'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600, // SemiBold
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 오른쪽: 토글 스위치
          Transform.scale(
            scale: 0.8, // 토글 크기 줄이기
            child: Switch(
              value: item['isEnabled'],
              onChanged: (value) {
                setState(() {
                  _scheduleItems[index]['isEnabled'] = value;
                });
              },
              activeColor: Colors.white,
              activeTrackColor: Colors.blue,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  // 이미지 업로드 및 텍스트 추출 기능은 나중에 추가 예정
  // Future<void> _uploadImage() async {
  //   // 1. 이미지 선택
  //   // 2. 백엔드로 이미지 전송
  //   // 3. 텍스트 추출 결과 수신
  //   // 4. 추출된 텍스트로 일정 항목 생성
  // }

  // 일정 저장 기능은 나중에 추가 예정
  // Future<void> _saveSchedules() async {
  //   // 1. 활성화된 일정만 필터링
  //   // 2. 백엔드로 저장 요청
  //   // 3. 성공/실패 처리
  // }
} 