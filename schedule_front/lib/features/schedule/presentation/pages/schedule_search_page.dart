import 'package:flutter/material.dart';
import '../../domain/models/schedule.dart';
import '../../domain/services/schedule_service.dart';

class ScheduleSearchPage extends StatefulWidget {
  const ScheduleSearchPage({Key? key}) : super(key: key);

  @override
  _ScheduleSearchPageState createState() => _ScheduleSearchPageState();
}

class _ScheduleSearchPageState extends State<ScheduleSearchPage> {
  final _service = ScheduleService();
  List<Schedule> _results = [];

  Future<void> _search(String query) async {
    _results = await _service.searchSchedules(query);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('검색')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              onSubmitted: _search,
              decoration: InputDecoration(hintText: '검색어를 입력하세요'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (c, i) => ListTile(
                title: Text(_results[i].title),
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
