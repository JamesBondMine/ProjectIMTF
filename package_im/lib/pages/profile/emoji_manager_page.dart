import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/emoji_pack_service.dart';

/// 表情管理页面
class EmojiManagerPage extends StatefulWidget {
  const EmojiManagerPage({super.key});

  @override
  State<EmojiManagerPage> createState() => _EmojiManagerPageState();
}

class _EmojiManagerPageState extends State<EmojiManagerPage> {
  final _emojiPackService = EmojiPackService();
  List<String> _enabledPackIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnabledPacks();
  }

  /// 加载已启用的表情包
  Future<void> _loadEnabledPacks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final enabledIds = await _emojiPackService.getEnabledPackIds();
      setState(() {
        _enabledPackIds = enabledIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      EasyLoading.showError('加载失败: $e');
    }
  }

  /// 切换表情包启用状态
  Future<void> _togglePack(String packId) async {
    try {
      final isEnabled = await _emojiPackService.togglePack(packId);
      setState(() {
        if (isEnabled) {
          _enabledPackIds.add(packId);
        } else {
          _enabledPackIds.remove(packId);
        }
      });
      EasyLoading.showSuccess(isEnabled ? '已启用' : '已禁用');
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('表情管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: EmojiPackService.allPacks.length,
              itemBuilder: (context, index) {
                final pack = EmojiPackService.allPacks[index];
                final isEnabled = _enabledPackIds.contains(pack.id);
                return _buildPackCard(pack, isEnabled);
              },
            ),
    );
  }

  /// 构建表情包卡片
  Widget _buildPackCard(EmojiPack pack, bool isEnabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 封面图
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEnabled
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                pack.coverImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 名称和数量
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pack.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pack.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '共 ${pack.gifs.length} 个表情',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 启用/禁用按钮
          ElevatedButton(
            onPressed: () => _togglePack(pack.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled
                  ? Colors.grey[300]
                  : Theme.of(context).primaryColor,
              foregroundColor: isEnabled ? Colors.black87 : Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isEnabled ? '已启用' : '启用',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

