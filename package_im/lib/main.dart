import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_im/pages/login/login_page.dart';
import 'pages/home_page.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置屏幕方向（iPhone竖屏，iPad支持所有方向以满足苹果多任务要求）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
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
    ..progressColor = const Color(0xFF00BCD4)  // 青色
    ..backgroundColor = Colors.white
    ..indicatorColor = const Color(0xFF00BCD4)  // 青色
    ..textColor = Colors.black
    ..maskColor = Colors.black.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '蜻蜓翼',
      debugShowCheckedModeBanner: false,
      // 本地化配置
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 中文简体
        Locale('en', 'US'), // 英文
      ],
      locale: const Locale('zh', 'CN'), // 默认语言
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BCD4),  // Material Cyan - 青色
          primary: const Color(0xFF00BCD4),
        ),
        primaryColor: const Color(0xFF00BCD4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00BCD4),  // 青色 AppBar
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
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
      // 已登录，从服务器刷新用户信息
      try {
        await apiService.getCurrentUserInfo();
      } catch (e) {
        debugPrint('刷新用户信息失败: $e');
        // 即使刷新失败，也继续使用本地缓存的用户信息
      }
      
      if (!mounted) return;
      
      // 跳转到主页
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
              '蜻蜓翼',
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
