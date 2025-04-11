import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEmailValid = true;
  bool _isEmailTouched = false;

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _handleLogin() {
    // 이메일과 비밀번호가 입력되었는지 확인
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일과 비밀번호를 입력해주세요'),
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

    // TODO: 서버/DB 연동 후 실제 로그인 처리 추가
    // 현재는 임시로 홈 화면으로 이동
    // 실제 구현 시에는 아래와 같은 과정이 필요:
    // 1. 서버에 로그인 요청 보내기
    // 2. 서버에서 이메일/비밀번호 검증
    // 3. 성공 시 토큰 등 응답 받기
    // 4. 토큰 저장 후 홈 화면으로 이동

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // TimeHomie 로고 텍스트
                  Container(
                    width: 280,
                    height: 60,
                    alignment: Alignment.center,
                    child: Text(
                      'TimeHomie',
                      style: TextStyle(
                        fontSize: 48,
                        fontFamily: 'DanielBlack',
                        height: 1.2,
                        letterSpacing: 0.015,
                        color: Color(0xFF0062FF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  // 로그인 이미지
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Image.asset(
                      'assets/images/loginpage.png',
                      width: 160,
                      height: 160,
                    ),
                  ),
                  // 하단 컨테이너
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 460,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, -10),
                          blurRadius: 20,
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(30, 28, 30, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 안내 텍스트
                            Container(
                              width: 315,
                              height: 80,
                              alignment: Alignment.center,
                              child: const Text(
                                '자동 일정 배치로 편하게\n모임까지 관리',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  letterSpacing: -0.025,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
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
                                      'assets/images/loginemail.png',
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
                                          _isEmailTouched = true;
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
                            const SizedBox(height: 24),
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
                                      'assets/images/loginpassword.png',
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
                            const SizedBox(height: 48),
                            // 로그인 버튼
                            GestureDetector(
                              onTap: _handleLogin,
                              child: Container(
                                width: 275,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0062FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    '로그인',
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
                            const SizedBox(height: 30),
                            // 회원가입 링크
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '아이디가 없으신가요? ',
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
                                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '회원가입',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 