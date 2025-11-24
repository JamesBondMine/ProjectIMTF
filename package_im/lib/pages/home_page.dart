import 'package:flutter/material.dart';
import 'chat/chat_list_page.dart';
import 'friend/friend_list_page.dart';
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

  // 页面列表
  final List<Widget> _pages = const [
    ChatListPage(),
    FriendListPage(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '聊天',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: '好友',
          ),
        ],
      ),
    );
  }
}

