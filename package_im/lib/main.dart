import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:package_im/pages/login/login_page.dart';
import 'pages/home_page.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化ApiService（恢复登录状态）
  await ApiService().init();
  
  runApp(const MyApp());
  _configLoading();
}

void _configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = const Color(0xFFAB47BC)
    ..backgroundColor = Colors.white
    ..indicatorColor = const Color(0xFFAB47BC)
    ..textColor = Colors.black87
    ..maskColor = Colors.black.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '趣聊',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFAB47BC), // 梦幻紫色主题
          primary: const Color(0xFFAB47BC),
        ),
        useMaterial3: true,
        // 自定义主题色
        primaryColor: const Color(0xFFAB47BC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFAB47BC),
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashPage(),
      builder: EasyLoading.init(),
    );
  }
}

/// 启动页 - 检查登录状态
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 延迟一下，显示启动页效果
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final apiService = ApiService();
    
    // 检查是否已登录
    if (apiService.isLoggedIn && apiService.currentUser != null) {
      // 已登录，跳转到主页
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(
            username: apiService.currentUser!.nickname,
          ),
        ),
      );
    } else {
      // 未登录，跳转到登录页
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              '趣聊',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
