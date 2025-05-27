// lib/pages/auto_schedule_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/schedule.dart';
import '../../domain/models/auto_schedule_request.dart';
import '../../domain/models//auto_schedule_response.dart';
import '../../domain/services/schedule_service.dart';
import '../../../../core/config/api_config.dart';

class AutoSchedulePage extends StatefulWidget {
  final String token;
  const AutoSchedulePage({Key? key, required this.token}) : super(key: key);

  @override
  _AutoSchedulePageState createState() => _AutoSchedulePageState();
}

class _AutoSchedulePageState extends State<AutoSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _minutesController = TextEditingController();

  List<AutoScheduleResponse> _suggestions = [];
  bool _loading = false;
  String? _error;

  Future<void> _pickTime({required bool isStart}) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  Future<void> _loadSuggestions() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      setState(() => _error = '시작 시간과 종료 시간을 선택하세요.');
      return;
    }

    final req = AutoScheduleRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startTime:
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
      endTime:
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
      customMinutes: int.parse(_minutesController.text.trim()),
    );

    setState(() {
      _loading = true;
      _error = null;
      _suggestions.clear();
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.suggestionsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode(req.toJson()),
      );

      if (response.statusCode == 200) {
        final body = response.body;
        final List data = body.startsWith('[') ? json.decode(body) as List : [];
        setState(() {
          _suggestions = data
              .map((e) => AutoScheduleResponse.fromJson(e))
              .toList();
        });
      } else {
        setState(() => _error = '추천 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = '오류 발생: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirm(AutoScheduleResponse item) async {
    setState(() => _loading = true);

    try {
      final body = {
        'title': item.title,
        'description': item.description,
        'suggestedStart': item.suggestedStart.toIso8601String(),
        'suggestedEnd': item.suggestedEnd.toIso8601String(),
      };
      final response = await http.post(
        Uri.parse(ApiConfig.confirmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final start = item.suggestedStart;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} 일정이 저장되었습니다!',
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('자동 일정 추천')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: '제목'),
                    validator: (v) =>
                        v == null || v.isEmpty ? '제목을 입력하세요.' : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: '설명'),
                    validator: (v) =>
                        v == null || v.isEmpty ? '설명을 입력하세요.' : null,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(isStart: true),
                          child: Text(
                            _startTime == null
                                ? '시작 시간 선택'
                                : '시작: ${_startTime!.format(context)}',
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(isStart: false),
                          child: Text(
                            _endTime == null
                                ? '종료 시간 선택'
                                : '종료: ${_endTime!.format(context)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: '길이(분)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '길이를 입력하세요.';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return '유효한 분 단위를 입력하세요.';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _loadSuggestions,
                    child: Text('추천 받기'),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16),
            if (_loading) CircularProgressIndicator(),
            if (!_loading && _suggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (ctx, i) {
                    final s = _suggestions[i];
                    final start = s.suggestedStart;
                    final end = s.suggestedEnd;
                    final startStr =
                        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                    final endStr =
                        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(startStr),
                        subtitle: Text('~ $endStr'),
                        trailing: Icon(Icons.check_circle_outline),
                        onTap: () => _confirm(s),
                      ),
                    );
                  },
                ),
              ),
            if (!_loading && _suggestions.isEmpty) ...[
              SizedBox(height: 16),
              Text('추천할 빈 시간대가 없습니다.'),
            ],
          ],
        ),
      ),
    );
  }
}
