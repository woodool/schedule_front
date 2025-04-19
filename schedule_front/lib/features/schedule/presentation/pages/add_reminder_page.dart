import 'package:flutter/material.dart';
import 'package:schedule/features/schedule/domain/models/notification_helper.dart';
import '../widgets/title_input.dart';
import '../widgets/date_time_selector.dart';
import '../widgets/repeat_setting_box.dart';
import '../widgets/notification_setting_box.dart';
import '../widgets/action_buttons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'schedule_id_provider.dart';

class AddReminderPage extends ConsumerStatefulWidget {
  const AddReminderPage({super.key});

  @override
  ConsumerState<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends ConsumerState<AddReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
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

    final scheduleId = ref.watch(scheduleIdProvider);

    if (scheduleId == null) {
      return const Center(child: Text("스케줄이 먼저 등록되어야 합니다."));
    }
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
                onSubmitPressed: () async {
                  final title = _titleController.text.trim();

                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('제목을 입력해주세요.')),
                    );
                    return;
                  }

                  final start = _startDate.toIso8601String();
                  final end = _endDate.toIso8601String();
                  final recurrenceDays = <int>[];
                  for (int i = 0; i < _selectedDays.length; i++) {
                    if (_selectedDays[i]) recurrenceDays.add(i);
                  }
                  final isRecurring = recurrenceDays.isNotEmpty;
                  final reminderMinutesBefore = getMinutesFromNotificationType(
                      _notificationType.name, _customMinutes);
                  final body = jsonEncode({
                    'title': title,
                    'startTime': start,
                    'endTime': end,
                    'isRecurring': isRecurring,
                    'recurrenceDays': recurrenceDays,
                    'reminderMinutesBefore': reminderMinutesBefore,
                    'scheduleId': scheduleId,
                  });
                  final response = await http.post(
                    Uri.parse('http://10.0.2.2:8080/api/ReminderDTO'),
                    headers: {'Content-Type': 'application/json'},
                    body: body,
                  );
                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
                    Navigator.of(context).pop();
                  } else {
                    print('리마인더 저장 실패: ${response.body}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('리마인더 저장에 실패했습니다.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
