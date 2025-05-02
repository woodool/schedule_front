import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schedule/features/schedule/domain/models/schedule.dart';
import 'package:schedule/features/schedule/domain/models/priority.dart';
import 'package:schedule/features/schedule/domain/services/schedule_service.dart';

class ScheduleSearchPage extends StatefulWidget {
  const ScheduleSearchPage({super.key});

  @override
  State<ScheduleSearchPage> createState() => _ScheduleSearchPageState();
}

class _ScheduleSearchPageState extends State<ScheduleSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScheduleService _scheduleService = ScheduleService();
  List<Schedule> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchSchedules(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 새로 추가한 검색 API 사용
      final results = await _scheduleService.searchSchedules(query);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '검색 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('일정 검색', 
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Pretendard',
                ),
                decoration: InputDecoration(
                  hintText: '일정 검색',
                  hintStyle: const TextStyle(
                    color: Color(0xFF767676),
                    fontFamily: 'Pretendard',
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  _searchSchedules(value);
                },
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Expanded(
                child: _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          '검색 결과가 없습니다',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            color: Color(0xFF767676),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final schedule = _searchResults[index];
                          return _buildSearchResultItem(schedule);
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(Schedule schedule) {
    final priority = Priority.fromValue(schedule.priority);
    final date = DateFormat('yyyy년 MM월 dd일').format(schedule.startTime);
    final time = DateFormat('HH:mm').format(schedule.startTime);
    
    return GestureDetector(
      onTap: () {
        // 일정 수정 페이지로 이동
        Navigator.pushNamed(
          context, 
          '/edit_schedule',
          arguments: schedule,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: priority.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    schedule.title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (schedule.description != null && schedule.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 20),
                child: Text(
                  schedule.description!,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: Color(0xFF767676),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 20),
              child: Text(
                '$date $time',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  color: Color(0xFF767676),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 