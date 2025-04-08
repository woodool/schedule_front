import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CategorySettingBox extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String>? onCategoryChanged;

  const CategorySettingBox({
    super.key,
    this.selectedCategory,
    this.onCategoryChanged,
  });

  static const List<String> categories = [
    '업무',
    '학업',
    '약속',
    '운동',
    '취미',
    '-',
  ];

  String _getCategoryText() {
    return selectedCategory ?? '-';
  }

  Future<void> _showCategorySelector(BuildContext context) async {
    String tempCategory = selectedCategory ?? categories.last;
    
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
                        '카테고리 설정',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        tempCategory,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: CupertinoPicker(
                          itemExtent: 44,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              tempCategory = categories[index];
                            });
                          },
                          children: categories.map((category) {
                            return Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
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
                    onCategoryChanged?.call(tempCategory);
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
          '카테고리',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _showCategorySelector(context),
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
              child: Text(
                _getCategoryText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 