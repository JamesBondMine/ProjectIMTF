import 'package:flutter/material.dart';
import 'discover/discover_page.dart';
import 'discover/publish_moment_page.dart';
import 'profile/profile_page.dart';
import 'package:package_im/services/api_service.dart';

/// 主页（底部导航栏）
class HomePage extends StatefulWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _apiService = ApiService();

  // 页面列表（不包含发布页面，因为它是弹出的）
  final List<Widget> _pages = const [
    DiscoverPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // 登录成功后立即建立 WebSocket 连接
    _connectWebSocket();
  }

  @override
  void dispose() {
    // 离开主页时断开 WebSocket（实际上只在退出登录时会触发）
    _apiService.disconnectChatWebSocket();
    super.dispose();
  }

  /// 建立 WebSocket 连接
  Future<void> _connectWebSocket() async {
    try {
      debugPrint('🔌 [HomePage] 登录成功，建立 WebSocket 连接...');
      
      final connected = await _apiService.connectChatWebSocket();
      
      if (connected) {
        debugPrint('✅ [HomePage] WebSocket 连接成功，可接收实时消息');
      } else {
        debugPrint('⚠️ [HomePage] WebSocket 连接失败');
      }
    } catch (e) {
      debugPrint('❌ [HomePage] WebSocket 连接异常: $e');
    }
  }

  /// 跳转到发布页面
  void _navigateToPublish() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PublishMomentPage(),
      ),
    );
    
    // 如果发布成功，刷新发现页
    if (result == true && mounted) {
      // 可以通过 GlobalKey 或其他方式刷新发现页
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: '发现',
              index: 0,
            ),
            const SizedBox(width: 80), // 中间留空给凸出按钮
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: '我的',
              index: 1,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建导航项
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive ? Theme.of(context).primaryColor : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建凸出的发布按钮
  Widget _buildFloatingActionButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _navigateToPublish,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}

