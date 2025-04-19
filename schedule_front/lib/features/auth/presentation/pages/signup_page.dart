import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isEmailValid = true;
  bool _isPasswordMatch = true;
  bool _showPasswordError = false;
  bool _isLoading = false;

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

<<<<<<< HEAD
  // Firebase 인증 후 백엔드로 사용자 정보 보내기
  Future<void> _signUpUser() async {
    try {
      // Firebase 인증을 통해 사용자 생성
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      // Firebase UID를 얻음
      String firebaseUid = userCredential.user!.uid;

      // 백엔드로 보내기 위한 데이터 준비
      Map<String, String> userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'firebase_uid': firebaseUid,
        'password': _passwordController.text,
      };

      String apiUrl = 'http://10.0.2.2:8080/api/UserRequestDTO'; 

      // 백엔드로 POST 요청 보내기
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      // 응답 처리
      if (response.statusCode == 200) {
        // 회원가입 성공 처리
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입이 완료되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        // 서버에서 오류 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('서버 오류: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Firebase 인증 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _validateForm() {
=======
  Future<void> _validateForm() async {
>>>>>>> 2ef2b9c686b19cc43987015cb3fe24cb0209d7eb
    setState(() {
      _showPasswordError = true;
      _isPasswordMatch = _passwordController.text == _confirmPasswordController.text;
      _isLoading = true;
    });

    // 모든 필드가 채워져 있는지 확인
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('모든 필드를 입력해주세요'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 이메일 형식 확인
    if (!_validateEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('올바른 이메일 형식이 아닙니다'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 비밀번호 일치 확인
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('비밀번호가 일치하지 않습니다'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Firebase 회원가입
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // 사용자 이름 업데이트
      await userCredential.user?.updateDisplayName(_nameController.text);

      // ID 토큰 가져오기
      final idToken = await userCredential.user?.getIdToken();

      // 백엔드 API 호출
      final response = await http.post(
        Uri.parse('http://192.168.219.101:8080/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        // 회원가입 성공
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입이 완료되었습니다'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // 백엔드 에러
        throw Exception('회원가입 실패: ${response.body}');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다';
          break;
        case 'invalid-email':
          errorMessage = '유효하지 않은 이메일 형식입니다';
          break;
        case 'operation-not-allowed':
          errorMessage = '이메일/비밀번호 로그인이 비활성화되어 있습니다';
          break;
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다. 더 강력한 비밀번호를 사용해주세요';
          break;
        default:
          errorMessage = '회원가입에 실패했습니다. 다시 시도해주세요';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입 중 오류가 발생했습니다. 다시 시도해주세요'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SafeArea(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    // 회원가입 텍스트
                    const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        letterSpacing: -0.025,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 26),
                    // 이름 텍스트
                    Container(
                      width: 315,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        ' 이름',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          letterSpacing: -0.025,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // 이름 입력
                    Container(
                      width: 315,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFF0062FF)),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Image.asset(
                              'assets/images/signup_person.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: '이름을 입력해 주세요',
                                hintStyle: TextStyle(
                                  color: Color(0xFF797979),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                  letterSpacing: -0.025,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                letterSpacing: -0.025,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // 이메일 텍스트
                    Container(
                      width: 315,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        ' 이메일',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          letterSpacing: -0.025,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // 이메일 입력
                    Container(
                      width: 315,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _isEmailValid ? const Color(0xFF0062FF) : Colors.red,
                        ),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Image.asset(
                              'assets/images/signup_mail.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              onChanged: (value) {
                                setState(() {
                                  _isEmailValid = value.isEmpty || _validateEmail(value);
                                });
                              },
                              decoration: InputDecoration(
                                hintText: '이메일을 입력해 주세요',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF797979),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                  letterSpacing: -0.025,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                errorText: _isEmailValid ? null : '올바른 이메일 형식이 아닙니다',
                                errorStyle: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                letterSpacing: -0.025,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // 비밀번호 텍스트
                    Container(
                      width: 315,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        ' 비밀번호',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          letterSpacing: -0.025,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // 비밀번호 입력
                    Container(
                      width: 315,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFF0062FF)),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Image.asset(
                              'assets/images/signup_lock.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: '비밀번호를 입력해 주세요',
                                hintStyle: TextStyle(
                                  color: Color(0xFF797979),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                  letterSpacing: -0.025,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                letterSpacing: -0.025,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // 비밀번호 재확인 텍스트
                    Container(
                      width: 315,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        ' 비밀번호 재확인',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          letterSpacing: -0.025,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // 비밀번호 재확인 입력
                    Container(
                      width: 315,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: (_showPasswordError && !_isPasswordMatch) 
                            ? Colors.red 
                            : const Color(0xFF0062FF),
                        ),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Image.asset(
                              'assets/images/signup_lock.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: '비밀번호를 다시 입력해 주세요',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF797979),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                  letterSpacing: -0.025,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                errorText: (_showPasswordError && !_isPasswordMatch) 
                                  ? '비밀번호가 일치하지 않습니다' 
                                  : null,
                                errorStyle: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                letterSpacing: -0.025,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 90),
                    // 회원가입 버튼
                    GestureDetector(
                      onTap: _validateForm,
                      child: Container(
                        width: 275,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0062FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            '회원가입',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              letterSpacing: -0.025,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // 로그인 링크
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '이미 아이디가 존재하나요? ',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            letterSpacing: -0.025,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              letterSpacing: -0.025,
                              color: Color(0xFF0062FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
} 