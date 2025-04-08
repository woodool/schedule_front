import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../domain/models/priority.dart';

class PrioritySettingBox extends StatelessWidget {
  final Priority? selectedPriority;
  final ValueChanged<Priority>? onPriorityChanged;

  const PrioritySettingBox({
    super.key,
    this.selectedPriority,
    this.onPriorityChanged,
  });

  String _getPriorityText() {
    if (selectedPriority == null) return '-';
    return selectedPriority!.name;
  }

  Color _getPriorityColor() {
    if (selectedPriority == null) return Colors.grey;
    return selectedPriority!.color;
  }

  Widget _buildPriorityBox(Color color, {double width = 84, double height = 22}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Future<void> _showPrioritySelector(BuildContext context) async {
    Priority tempPriority = selectedPriority ?? Priority.values.last;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: 300,
                height: 320,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '우선순위 설정',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: _buildPriorityBox(tempPriority.color, width: 120, height: 30),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: CupertinoPicker(
                          itemExtent: 44,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              tempPriority = Priority.values[index];
                            });
                          },
                          children: Priority.values.map((priority) {
                            return Center(
                              child: _buildPriorityBox(priority.color, width: 100, height: 26),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    onPriorityChanged?.call(tempPriority);
                    Navigator.of(context).pop();
                  },
                  child: Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '우선순위',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _showPrioritySelector(context),
          child: Container(
            width: 140,
            height: 60,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: Colors.black,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: _buildPriorityBox(_getPriorityColor()),
            ),
          ),
        ),
      ],
    );
  }
} 