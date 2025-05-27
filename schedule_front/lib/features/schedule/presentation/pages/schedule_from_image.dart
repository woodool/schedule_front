import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show json, utf8;
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/action_buttons.dart';
import '../widgets/calendar_active_check.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';

class ScheduleFromImagePage extends StatefulWidget {
  final File? initialImage;
  
  const ScheduleFromImagePage({super.key, this.initialImage});

  @override
  State<ScheduleFromImagePage> createState() => _ScheduleFromImagePageState();
}

class _ScheduleFromImagePageState extends State<ScheduleFromImagePage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  // 일정 아이템 리스트
  List<Map<String, dynamic>> _scheduleItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _selectedImage = widget.initialImage;
      _processSelectedImage();
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
          _isLoading = true;
        });
        await _processSelectedImage();
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

  Future<void> _processSelectedImage() async {
    if (_selectedImage == null) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // 이미지 분석 모듈로 이미지 전송하여 일정 추출
      final extractedItems = await _uploadAndProcessImage(_selectedImage!);
      
      setState(() {
        _scheduleItems = extractedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 처리 오류: $e')),
      );
    }
  }

  // 이미지 업로드 및 일정 추출 함수
  Future<List<Map<String, dynamic>>> _uploadAndProcessImage(File image) async {
    try {
      var response;
      
      // 이미지 분석 모듈로 이미지 전송
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConfig.imageAnalysisUrl),
        );
        
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          image.path,
        ));
        
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode != 200) {
          print('이미지 분석 실패, 테스트 데이터 API로 대체합니다...');
          
          // 이미지 분석 실패 시 테스트 데이터 API 사용
          response = await http.get(
            Uri.parse('${ApiConfig.imageAnalysisUrl.substring(0, ApiConfig.imageAnalysisUrl.lastIndexOf('/'))}/test-data'),
          );
          
          if (response.statusCode != 200) {
            throw Exception('테스트 데이터 API도 실패: ${response.statusCode}');
          }
        }
      } catch (uploadError) {
        print('이미지 업로드 오류: $uploadError, 테스트 API로 대체...');
        
        // 오류 발생 시 테스트 데이터 API 사용
        response = await http.get(
          Uri.parse('${ApiConfig.imageAnalysisUrl.substring(0, ApiConfig.imageAnalysisUrl.lastIndexOf('/'))}/test-data'),
        );
      }
      
      // 응답 내용 출력 (디버깅용)
      print('서버 응답 코드: ${response.statusCode}');
      print('서버 응답 데이터: ${response.body}');
      
      // UTF-8 디코딩 명시적 처리
      var responseData = json.decode(utf8.decode(response.bodyBytes));
      
      // 새로운 API 응답 형식 처리 ("schedules" 필드에 결과가 들어 있음)
      var extractedItems = responseData.containsKey('schedules') 
          ? responseData['schedules'] 
          : responseData;
      
      // 특정 형식 확인 및 처리
      print('추출된 데이터 형식: ${extractedItems.runtimeType}');
      
      List<dynamic> itemsList;
      
      // 서버 응답이 List가 아닌 경우의 처리
      if (extractedItems is! List) {
        if (extractedItems is Map<String, dynamic>) {
          // 만약 응답이 {"schedules": [...]} 형식이라면
          if (extractedItems.containsKey('schedules')) {
            itemsList = extractedItems['schedules'] as List;
          } else {
            // 그냥 개별 항목 하나로 왔을 수 있음
            itemsList = [extractedItems];
          }
        } else {
          print('예상치 못한 응답 형식: $extractedItems');
          return _getFallbackDummyData();
        }
      } else {
        itemsList = extractedItems;
      }
      
      print('변환된 항목 수: ${itemsList.length}');
      
      if (itemsList.isEmpty) {
        return _getFallbackDummyData();
      }
      
      // 추출된 일정을 UI 표시 형식으로 변환 (PhotoScheduleDTO와 호환되는 형식)
      return List<Map<String, dynamic>>.from(itemsList.map((item) {
        // 필드 이름 확인 및 표준화
        String title = item['subject'] ?? item['title'] ?? '제목 없음';
        String startTime = item['start_time'] ?? item['startTime'] ?? DateTime.now().toIso8601String();
        String endTime = item['end_time'] ?? item['endTime'] ?? DateTime.now().add(const Duration(hours: 1)).toIso8601String();
        String recurrenceDays = item['recurrenceDays'] ?? '';
        String day = item['day'] ?? '';
        
        // 시작/종료 시간이 ISO 8601 형식인지 확인하고 아니면 변환
        if (!_isIso8601Format(startTime)) {
          startTime = _convertToIso8601(startTime);
        }
        
        if (!_isIso8601Format(endTime)) {
          endTime = _convertToIso8601(endTime);
        }
        
        // day 필드가 있고 recurrenceDays가 없으면 day 값을 기반으로 recurrenceDays 생성
        if (day.isNotEmpty && recurrenceDays.isEmpty) {
          recurrenceDays = _convertDayToPattern(day);
        }
        
        // 반복 시작/종료 날짜 설정 (API에서 제공하는 경우 사용)
        String recurrenceStartDate = item['recurrenceStartDate'] ?? startTime;
        String recurrenceEndDate = item['recurrenceEndDate'] ?? 
            DateTime.parse(startTime).add(const Duration(days: 90)).toIso8601String(); // 기본 3개월
        
        return {
          'title': title,
          'dateRange': '${_formatDate(startTime)} ~ ${_formatDate(endTime)}',
          'timeRange': '${_formatTime(startTime)} ~ ${_formatTime(endTime)}',
          'isEnabled': true,
          'startTime': startTime,
          'endTime': endTime,
          'recurrenceDays': recurrenceDays,
          'recurrenceStartDate': recurrenceStartDate,
          'recurrenceEndDate': recurrenceEndDate,
        };
      }));
    } catch (e) {
      print('이미지 처리 오류: $e');
      return _getFallbackDummyData();
    }
  }
  
  // 문자열이 ISO 8601 형식인지 확인
  bool _isIso8601Format(String dateStr) {
    try {
      DateTime.parse(dateStr);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // 날짜 문자열을 ISO 8601 형식으로 변환
  String _convertToIso8601(String dateStr) {
    try {
      // 여러 형식 시도
      // YYYY-MM-DD HH:MM
      if (dateStr.contains(' ')) {
        final parts = dateStr.split(' ');
        return '${parts[0]}T${parts[1]}:00';
      }
      
      // 현재 날짜와 시간 사용
      final now = DateTime.now();
      return now.toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  // 요일 문자열을 recurrenceDays 패턴으로 변환
  String _convertDayToPattern(String day) {
    List<String> pattern = ['0', '0', '0', '0', '0', '0', '0'];
    
    // 요일에 따라 패턴 설정 (월=0, 화=1, 수=2, 목=3, 금=4, 토=5, 일=6)
    switch (day) {
      case '월': pattern[0] = '1'; break;
      case '화': pattern[1] = '1'; break;
      case '수': pattern[2] = '1'; break;
      case '목': pattern[3] = '1'; break;
      case '금': pattern[4] = '1'; break;
      case '토': pattern[5] = '1'; break;
      case '일': pattern[6] = '1'; break;
    }
    
    return pattern.join(',');
  }

  // 일정 추출 실패 시 사용할 더미 데이터
  List<Map<String, dynamic>> _getFallbackDummyData() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));
    
    return [
      {
        'title': '이미지에서 추출된 일정이 없습니다',
        'dateRange': '일정 추가를 위해 다른 이미지를 선택해보세요',
        'timeRange': '',
        'isEnabled': false,
        'startTime': now.toIso8601String(),
        'endTime': tomorrow.toIso8601String(),
        'recurrenceDays': '',
        'recurrenceStartDate': now.toIso8601String(),
        'recurrenceEndDate': nextWeek.toIso8601String(),
      }
    ];
  }

  // 날짜 포맷팅 함수 (ISO 8601 -> YYYY/MM/DD)
  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final parts = isoDate.split('T');
      if (parts.isEmpty) return '';
      
      final dateParts = parts[0].split('-');
      if (dateParts.length < 3) return parts[0];
      
      return '${dateParts[0]}/${dateParts[1]}/${dateParts[2]}';
    } catch (e) {
      return isoDate;
    }
  }

  // 시간 포맷팅 함수 (ISO 8601 -> HH:MM)
  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final parts = isoDate.split('T');
      if (parts.length < 2) return '';
      
      return parts[1].substring(0, 5);
    } catch (e) {
      return '';
    }
  }

  // 일정 저장 함수
  Future<bool> _saveSchedules(List<Map<String, dynamic>> items) async {
    try {
      // 활성화된 일정만 필터링
      var activeItems = items.where((item) => item['isEnabled']).toList();
      
      if (activeItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택된 일정이 없습니다')),
        );
        return false;
      }
      
      // PhotoScheduleDTO 형식으로 변환 (백엔드 Java DTO와 필드명 완벽히 일치)
      var photoScheduleDTOs = activeItems.map((item) => {
        'title': item['title'],
        'startTime': item['startTime'],
        'endTime': item['endTime'],
        'recurrenceDays': item['recurrenceDays'],
        'recurrenceStartDate': item['recurrenceStartDate'],
        'recurrenceEndDate': item['recurrenceEndDate'],
        'reminderTime': null  // 백엔드의 PhotoScheduleDTO에는 이 필드가 필요함
      }).toList();
      
      // PhotoListRequestDTO 형식으로 래핑 (백엔드 Java 클래스와 필드명 일치)
      var photoListRequestDTO = {
        'photoListScheduleDTO': photoScheduleDTOs
      };
      
      // Firebase 토큰 가져오기 - AuthService 사용
      final idToken = await AuthService.getIdToken();
      
      print('백엔드 전송 데이터: ${json.encode(photoListRequestDTO)}');
      
      // 백엔드 API 호출
      var response = await http.post(
        Uri.parse('${ApiConfig.schedulesEndpoint}/bulk'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken'
        },
        body: json.encode(photoListRequestDTO),
      );
      
      print('백엔드 응답 코드: ${response.statusCode}');
      print('백엔드 응답 내용: ${response.body}');
      
      if (response.statusCode != 200) {
        print('백엔드 오류: ${response.body}');
        throw Exception('서버 오류: ${response.statusCode}');
      }
      
      return true;
    } catch (e) {
      print('일정 저장 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정 저장 중 오류가 발생했습니다: $e')),
      );
      return false;
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
        actions: [
          // 다른 이미지 선택 버튼
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImage,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 선택된 이미지 미리보기
                if (_selectedImage != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                
                Expanded(
                  child: _scheduleItems.isEmpty
                      ? const Center(child: Text('추출된 일정이 없습니다. 다른 이미지를 선택해보세요.'))
                      : ListView.separated(
                          itemCount: _scheduleItems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
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
            if (_scheduleItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('저장할 일정이 없습니다')),
              );
              return;
            }
            
            // 다이얼로그로 CalendarActiveCheckWidget 표시
            CalendarActiveCheckWidget.show(
              context, 
              _scheduleItems,
            ).then((result) async {
              // 결과 처리
              if (result != null) {
                setState(() {
                  _isLoading = true;
                });
                
                // 백엔드로 일정 저장
                final success = await _saveSchedules(result);
                
                setState(() {
                  _isLoading = false;
                });
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('일정이 저장되었습니다')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('일정 저장 실패')),
                  );
                }
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
} 