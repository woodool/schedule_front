import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'labeled_input_field.dart';

class TitleInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final EdgeInsetsGeometry padding;
  final bool isRequired;
  final Function(File?)? onImageSelected;

  const TitleInputField({
    super.key,
    required this.controller,
    this.label = '모임 이름',
    this.hintText = '모임 이름을 입력해 주세요',
    this.padding = const EdgeInsets.only(bottom: 16),
    this.isRequired = true,
    this.onImageSelected,
  });

  @override
  State<TitleInputField> createState() => _TitleInputFieldState();
}

class _TitleInputFieldState extends State<TitleInputField> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(_selectedImage);
        }
      }
    } catch (e) {
      // 이미지 선택 실패 처리
      print('이미지 선택 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LabeledInputField(
      label: widget.label,
      isRequired: widget.isRequired,
      padding: widget.padding,
      child: Row(
        children: [
          // 이미지 선택 버튼
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 텍스트 입력 필드
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
              ),
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  isCollapsed: true,
                ),
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlignVertical: TextAlignVertical.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 