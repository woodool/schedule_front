import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CategorySettingBox extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String>? onCategoryChanged;
  final ValueChanged<int?>? onCategoryIdChanged;
  final int? categoryId;

  const CategorySettingBox({
    super.key,
    this.selectedCategory,
    this.onCategoryChanged,
    this.onCategoryIdChanged,
    this.categoryId,
  });

  static const List<String> categories = [
    '업무',
    '학업',
    '약속',
    '운동',
    '취미',
    '-',
  ];

  // 카테고리 이름과 ID 매핑 맵
  static const Map<String, int> categoryToId = {
    '업무': 14,
    '학업': 15,
    '약속': 16,
    '운동': 17,
    '취미': 18,
    '-': 19,
  };
  
  // ID에서 카테고리 이름으로 변환하는 맵
  static const Map<int, String> idToCategory = {
    14: '업무',
    15: '학업',
    16: '약속',
    17: '운동',
    18: '취미',
    19: '-',
  };

  int? _getCategoryId(String category) {
    return categoryToId[category];
  }

  String _getCategoryNameById(int? id) {
    return id != null ? (idToCategory[id] ?? '-') : '-';
  }

  String _getCategoryText() {
    if (categoryId != null) {
      return _getCategoryNameById(categoryId);
    }
    return selectedCategory ?? '-';
  }

  Future<void> _showCategorySelector(BuildContext context) async {
    String tempCategory = selectedCategory ?? '-';
    
    int initialIndex = categories.indexOf(tempCategory);
    if (initialIndex < 0) initialIndex = categories.length - 1;
    
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
                          scrollController: FixedExtentScrollController(initialItem: initialIndex),
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
                                style: TextStyle(fontSize: 20),
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
                    onCategoryIdChanged?.call(_getCategoryId(tempCategory));
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