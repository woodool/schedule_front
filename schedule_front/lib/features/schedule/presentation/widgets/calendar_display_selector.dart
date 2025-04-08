import 'package:flutter/material.dart';

enum CalendarDisplayType {
  hide,
  show,
}

class CalendarDisplaySelector extends StatelessWidget {
  final CalendarDisplayType selectedType;
  final ValueChanged<CalendarDisplayType>? onTypeSelected;

  const CalendarDisplaySelector({
    super.key,
    required this.selectedType,
    this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => onTypeSelected?.call(CalendarDisplayType.hide),
          child: Container(
            width: 160,
            height: 60,
            child: Center(
              child: Text(
                '달력 미표시',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: selectedType == CalendarDisplayType.hide 
                      ? Colors.black 
                      : Color(0xFF767676),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        GestureDetector(
          onTap: () => onTypeSelected?.call(CalendarDisplayType.show),
          child: Container(
            width: 160,
            height: 60,
            child: Center(
              child: Text(
                '달력 표시',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: selectedType == CalendarDisplayType.show 
                      ? Colors.black 
                      : Color(0xFF767676),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}