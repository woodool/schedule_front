
int? getMinutesFromNotificationType(String type, [int? custom]) {
  switch (type) {
    case 'none':
      return null;
    case '10분 전':
      return 10;
    case '1시간 전':
      return 60;
    case '1일 전':
      return 1440;
    case '사용자 설정':
      return custom;
    default:
      return null;
  }
}
