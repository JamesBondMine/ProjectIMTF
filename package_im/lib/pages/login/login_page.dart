import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:package_im/services/api_service.dart';
import 'package:package_im/pages/home_page.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;
import 'agreement_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isPasswordVisible = false;
  bool _isAgreed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 先检查账号密码是否为空
    if (_accountController.text.trim().isEmpty) {
      EasyLoading.showError('请输入账号');
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      EasyLoading.showError('请输入密码');
      return;
    }

    // 先检查是否勾选协议
    if (!_isAgreed) {
      EasyLoading.showError('请先阅读并同意隐私协议和用户协议');
      return;
    }

    // 验证表单
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 调用真实的登录API
        final response = await _apiService.login(
          usernameOrEmail: _accountController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (response.success && response.data != null) {
            // 登录成功
            EasyLoading.showSuccess('登录成功！');

            // 延迟一下再跳转
            await Future.delayed(const Duration(milliseconds: 500));

            if (mounted) {
              // 跳转到主页，传递用户昵称
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    username: response.data!.user.nickname,
                  ),
                ),
              );
            }
          } else {
            // 登录失败，显示错误信息
            EasyLoading.showError(response.message.isNotEmpty 
                ? response.message 
                : '登录失败，请重试');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // 异常已经在HttpManager中处理并显示
        }
      }
    }
  }

  void _navigateToAgreement(String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AgreementPage(
          title: title,
          content: content,
        ),
      ),
    );
  }

  /// Apple 登录
  Future<void> _handleAppleSignIn() async {
    // 先检查是否勾选协议
    if (!_isAgreed) {
      EasyLoading.showError('请先阅读并同意隐私协议和用户协议');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 检查是否支持 Apple 登录
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (mounted) {
          EasyLoading.showError('当前设备不支持 Apple 登录');
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // 发起 Apple 登录请求
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (mounted) {
        // 获取到 Apple 返回的凭证
        final identityToken = credential.identityToken;
        final appleUserId = credential.userIdentifier;
        
        // 获取用户信息（如果有的话）
        final fullName = credential.givenName != null && credential.familyName != null
            ? '${credential.familyName}${credential.givenName}'
            : null;
        final email = credential.email;

        if (identityToken != null && appleUserId != null) {
          // 调用后端 API 进行 Apple 登录验证
          final response = await _apiService.appleLogin(
            identityToken: identityToken,
            appleUserId: appleUserId,
            email: email,
            nickname: fullName,
          );

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            if (response.success && response.data != null) {
              // Apple 登录成功
              EasyLoading.showSuccess('Apple 登录成功！');
              await Future.delayed(const Duration(milliseconds: 500));

              if (mounted) {
                // 跳转到主页
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      username: response.data?.user.nickname ?? 
                               fullName ?? 
                               'Apple用户',
                    ),
                  ),
                );
              }
            } else {
              // 登录失败
              EasyLoading.showError(response.message.isNotEmpty 
                  ? response.message 
                  : 'Apple 登录失败');
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            EasyLoading.showError('Apple 登录失败，未获取到有效凭证');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (e is SignInWithAppleAuthorizationException) {
          // 用户取消登录
          if (e.code == AuthorizationErrorCode.canceled) {
            EasyLoading.showInfo('已取消 Apple 登录');
          } else {
            EasyLoading.showError('Apple 登录失败: ${e.message}');
          }
        } else {
          EasyLoading.showError('Apple 登录失败，请重试');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: GestureDetector(
        onTap: () {
          // 点击空白处隐藏键盘
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const SizedBox(height: 40),
                // Logo 图标
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '欢迎登录',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '请输入您的账号和密码',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                // 登录卡片
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 账号输入框
                      TextFormField(
                        controller: _accountController,
                        decoration: InputDecoration(
                          labelText: '账号/邮箱',
                          hintText: '请输入账号或邮箱',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入账号或邮箱';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // 密码输入框
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: '密码',
                          hintText: '请输入密码',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入密码';
                          }
                          if (value.length < 6) {
                            return '密码长度至少6个字符';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // 登录按钮
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '登录',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // 分隔线
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '或',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Apple 登录按钮（仅在 iOS 平台显示）
                      if (Platform.isIOS)
                        SignInWithAppleButton(
                          onPressed: _isLoading ? () {} : _handleAppleSignIn,
                          text: 'Sign in with Apple',
                          height: 50,
                          style: SignInWithAppleButtonStyle.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 协议勾选
                Row(
                  children: [
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: _isAgreed,
                        activeColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _isAgreed = value ?? false;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          children: [
                            const TextSpan(text: '我已阅读并同意'),
                            TextSpan(
                              text: '《隐私协议》',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _navigateToAgreement(
                                    '隐私协议',
                                    AgreementPage.privacyContent,
                                  );
                                },
                            ),
                            const TextSpan(text: '和'),
                            TextSpan(
                              text: '《用户协议》',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _navigateToAgreement(
                                    '用户协议',
                                    AgreementPage.userContent,
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // 底部链接
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text(
                        '忘记密码？',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 1,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    TextButton(
                      onPressed: () {
                        // 跳转到注册页面
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text(
                        '立即注册',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

