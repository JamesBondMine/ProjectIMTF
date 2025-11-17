import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 表情包服务
class EmojiPackService {
  static const String _storageKey = 'enabled_emoji_packs';

  /// 表情包分类
  static final List<EmojiPack> allPacks = [
    EmojiPack(
      id: 'animals',
      name: '动物世界',
      icon: '🐶',
      coverImage: 'assets/gif/horse-22647_256.gif',
      gifs: [
        'assets/gif/horse-22647_256.gif',
        'assets/gif/ladybug-5068_256.gif',
        'assets/gif/unicorn-16249_256.gif',
      ],
    ),
    EmojiPack(
      id: 'love',
      name: '爱心表白',
      icon: '❤️',
      coverImage: 'assets/gif/love-3955_256.gif',
      gifs: [
        'assets/gif/love-3955_256.gif',
        'assets/gif/cupid-18601_256.gif',
        'assets/gif/flower-11997_256.gif',
        'assets/gif/flowers-11015_256.gif',
      ],
    ),
    EmojiPack(
      id: 'celebration',
      name: '庆祝节日',
      icon: '🎉',
      coverImage: 'assets/gif/halloween-22525_256.gif',
      gifs: [
        'assets/gif/halloween-22525_256.gif',
        'assets/gif/pride-6390_256.gif',
        'assets/gif/tree-10000_256.gif',
      ],
    ),
    EmojiPack(
      id: 'fun',
      name: '趣味表情',
      icon: '🎪',
      coverImage: 'assets/gif/hot-air-balloon-3622_256.gif',
      gifs: [
        'assets/gif/hot-air-balloon-3622_256.gif',
        'assets/gif/swing-6077_256.gif',
        'assets/gif/pinwheel-8829_256.gif',
        'assets/gif/rocket-3972_256.gif',
      ],
    ),
    EmojiPack(
      id: 'tools',
      name: '工具道具',
      icon: '🔨',
      coverImage: 'assets/gif/hammer-8415_256.gif',
      gifs: [
        'assets/gif/hammer-8415_256.gif',
        'assets/gif/download-2486_256.gif',
        'assets/gif/paper-23984_256.gif',
      ],
    ),
    EmojiPack(
      id: 'nature',
      name: '自然风景',
      icon: '🌲',
      coverImage: 'assets/gif/iceland-5543_256.gif',
      gifs: [
        'assets/gif/iceland-5543_256.gif',
        'assets/gif/wind-21844_256.gif',
        'assets/gif/winter-16014_256.gif',
      ],
    ),
    EmojiPack(
      id: 'hot',
      name: '火热表情',
      icon: '🔥',
      coverImage: 'assets/gif/hot-12616_256.gif',
      gifs: [
        'assets/gif/hot-12616_256.gif',
        'assets/gif/car-1803_256.gif',
      ],
    ),
  ];

  /// 获取已启用的表情包ID列表
  Future<List<String>> getEnabledPackIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonString);
        return list.cast<String>();
      }
    } catch (e) {
      print('获取已启用表情包失败: $e');
    }
    // 默认启用第一个表情包
    return ['love'];
  }

  /// 获取已启用的表情包列表
  Future<List<EmojiPack>> getEnabledPacks() async {
    final enabledIds = await getEnabledPackIds();
    return allPacks.where((pack) => enabledIds.contains(pack.id)).toList();
  }

  /// 检查表情包是否已启用
  Future<bool> isPackEnabled(String packId) async {
    final enabledIds = await getEnabledPackIds();
    return enabledIds.contains(packId);
  }

  /// 启用表情包
  Future<void> enablePack(String packId) async {
    try {
      final enabledIds = await getEnabledPackIds();
      if (!enabledIds.contains(packId)) {
        enabledIds.add(packId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, json.encode(enabledIds));
      }
    } catch (e) {
      print('启用表情包失败: $e');
      rethrow;
    }
  }

  /// 禁用表情包
  Future<void> disablePack(String packId) async {
    try {
      final enabledIds = await getEnabledPackIds();
      enabledIds.remove(packId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(enabledIds));
    } catch (e) {
      print('禁用表情包失败: $e');
      rethrow;
    }
  }

  /// 切换表情包启用状态
  Future<bool> togglePack(String packId) async {
    final isEnabled = await isPackEnabled(packId);
    if (isEnabled) {
      await disablePack(packId);
      return false;
    } else {
      await enablePack(packId);
      return true;
    }
  }
}

/// 表情包模型
class EmojiPack {
  final String id;
  final String name;
  final String icon; // emoji 图标
  final String coverImage; // 封面图
  final List<String> gifs; // GIF 列表

  EmojiPack({
    required this.id,
    required this.name,
    required this.icon,
    required this.coverImage,
    required this.gifs,
  });
}

