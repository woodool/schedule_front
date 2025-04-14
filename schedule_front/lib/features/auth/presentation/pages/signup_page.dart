import 'package:flutter/material.dart';

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

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _validateForm() {
    setState(() {
      _showPasswordError = true;
      _isPasswordMatch = _passwordController.text == _confirmPasswordController.text;
    });

    // 모든 필드가 채워져 있는지 확인
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필드를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 이메일 형식 확인
    if (!_validateEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 이메일 형식이 아닙니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 비밀번호 일치 확인
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 일치하지 않습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: 여기에 서버/DB 연동 코드 추가 예정

    // 모든 검증을 통과하면 로그인 페이지로 이동
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('회원가입이 완료되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
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
      body: SingleChildScrollView(
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
    );
  }
} 