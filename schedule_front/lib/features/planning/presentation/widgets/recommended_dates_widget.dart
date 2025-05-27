import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 추천 일자 위젯
/// 일정 계획 시스템이 추천하는 일자 목록을 보여줍니다.
class RecommendedDatesWidget extends StatelessWidget {
  final List<DateTime> recommendedDates;

  const RecommendedDatesWidget({
    Key? key,
    required this.recommendedDates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 날짜별로 중복 제거 (같은 날짜는 하나만 표시)
    final uniqueDates = _getUniqueDates();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 일자',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: uniqueDates.isEmpty
              ? const Center(
                  child: Text(
                    '추천 일자가 없습니다',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: uniqueDates.map((date) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        DateFormat('MM월 dd일 (E)', 'ko_KR').format(date),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
  
  // 중복 없는 날짜 목록 생성
  List<DateTime> _getUniqueDates() {
    // 날짜만 비교하기 위한 맵
    final Map<String, DateTime> uniqueDateMap = {};
    
    // 날짜가 같으면 중복으로 처리
    for (final date in recommendedDates) {
      final dateKey = '${date.year}-${date.month}-${date.day}';
      uniqueDateMap[dateKey] = date;
    }
    
    // 맵의 값들을 리스트로 변환
    return uniqueDateMap.values.toList();
  }
} 