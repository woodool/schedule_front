import 'package:flutter/material.dart';
import '../widgets/title_input.dart';
import '../widgets/date_time_selector.dart';
import '../widgets/repeat_setting_box.dart';
import '../widgets/notification_setting_box.dart';
import '../widgets/action_buttons.dart';

class EditReminderPage extends StatefulWidget {
  const EditReminderPage({super.key});

  @override
  State<EditReminderPage> createState() => _EditReminderPageState();
}

class _EditReminderPageState extends State<EditReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _startDate = DateTime(2023, 12, 12, 22); // 12월 12일 오후 10시
  DateTime _endDate = DateTime(2023, 12, 15, 23);   // 12월 15일 오후 11시
  List<bool> _selectedDays = [false, false, false, false, false, false, false];
  NotificationType _notificationType = NotificationType.none;
  int? _customMinutes;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      TitleInput(
                        controller: _titleController,
                        onChanged: (value) {
                          // TODO: 제목 변경 처리
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DateTimeSelector(
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
                          ),
                          const SizedBox(width: 35),
                          NotificationSettingBox(
                            notificationType: _notificationType,
                            customMinutes: _customMinutes,
                            onTypeChanged: (type) {
                              setState(() {
                                _notificationType = type;
                              });
                            },
                            onCustomMinutesChanged: (minutes) {
                              setState(() {
                                _customMinutes = minutes;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ActionButtons(
                onCancelPressed: () {
                  Navigator.of(context).pop();
                },
                onSubmitPressed: () {
                  // 나중에 DB 연결 시 여기에 리마인더 수정 로직 추가
                  Navigator.of(context).pop();
                },
                cancelText: '취소',
                submitText: '수정',
              ),
            ),
          ],
        ),
      ),
    );
  }
} 