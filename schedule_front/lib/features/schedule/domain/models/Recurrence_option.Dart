enum RecurrenceOption {
  SINGLE,  // 단일
  FUTURE,  // 해당일 및 향후
  ALL      // 전체
}

enum RecurrenceDeleteMode {
  SINGLE,       // 단일
  FUTURE,       // 해당일 및 향후
  ALL           // 전체
}

enum RecurrenceModificationMode {
  SINGLE,            // 단일 일정만 수정
  FUTURE,            // 해당일 및 향후 일정 수정
  ALL,               // 전체 일정 수정
  KEEP_EXCLUDED      // excludedDates에 포함된 일정 제외하고 수정
}

// 상수 정의 (서비스에서 활용 가능)
class RecurrenceConstants {
  // 변경 시 excludedDates 보존 여부 (기본값: true)
  static const bool PRESERVE_EXCLUDED_DATES = true;
}
