import 'package:flutter/material.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/reminder.dart';
import '../../domain/services/schedule_service.dart';
import '../../domain/services/reminder_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScheduleService _scheduleService = ScheduleService();
  final ReminderService _reminderService = ReminderService();
  List<Schedule> _schedules = [];
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final schedules = await _scheduleService.getSchedules();
      final reminders = await _reminderService.getReminders();

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 로드 실패: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('일정 관리'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('오류: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_reminders.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              '리마인더',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _reminders.length,
                            itemBuilder: (context, index) {
                              final reminder = _reminders[index];
                              return ListTile(
                                title: Text(
                                  reminder.title,
                                  style: const TextStyle(color: Colors.black),
                                ),
                                subtitle: Text(
                                  '${reminder.startTime} ~ ${reminder.endTime}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.black),
                                  onPressed: () async {
                                    try {
                                      await _reminderService.deleteReminder(
                                        reminder.reminderId.toString(),
                                      );
                                      _loadData();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('리마인더 삭제 실패: $e'),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/edit_reminder',
                                    arguments: reminder,
                                  ).then((value) {
                                    if (value == true) {
                                      _loadData();
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ],
                        if (_schedules.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              '일정',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _schedules.length,
                            itemBuilder: (context, index) {
                              final schedule = _schedules[index];
                              return ListTile(
                                title: Text(
                                  schedule.title,
                                  style: const TextStyle(color: Colors.black),
                                ),
                                subtitle: Text(
                                  '${schedule.startTime} ~ ${schedule.endTime}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                trailing: Text(
                                  schedule.priority != null ? '우선순위: ${schedule.priority}' : '',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/edit_schedule',
                                    arguments: schedule,
                                  ).then((value) {
                                    if (value == true) {
                                      _loadData();
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ],
                        if (_reminders.isEmpty && _schedules.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                '등록된 리마인더와 일정이 없습니다',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: AddButton(
        items: [
          AddButtonItem(
            label: '사진으로 일정 추가',
            iconPath: 'assets/images/image.png',
            onPressed: () {
              // TODO: 사진으로 일정 추가 기능 구현
            },
          ),
          AddButtonItem(
            label: '리마인더 추가',
            iconPath: 'assets/images/reminder.png',
            onPressed: () {
              Navigator.pushNamed(context, '/add_reminder').then((value) {
                if (value == true) _loadData();
              });
            },
          ),
          AddButtonItem(
            label: '일정 추가',
            iconPath: 'assets/images/schedule.png',
            onPressed: () {
              Navigator.pushNamed(context, '/add_schedule').then((value) {
                if (value == true) _loadData();
              });
            },
          ),
        ],
      ),
    );
  }
}
