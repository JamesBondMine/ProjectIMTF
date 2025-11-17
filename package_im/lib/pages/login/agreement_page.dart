import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class AgreementPage extends StatelessWidget {
  final String title;
  final String content;

  const AgreementPage({
    super.key,
    required this.title,
    required this.content,
  });

  /// 发送邮件
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': title.contains('隐私') 
            ? '关于隐私协议的咨询' 
            : title.contains('用户') 
                ? '关于用户协议的咨询'
                : '应用咨询',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      debugPrint('无法打开邮件应用');
    }
  }

  /// 构建富文本内容（将邮箱转换为可点击链接）
  Widget _buildRichText(BuildContext context) {
    final List<TextSpan> spans = [];
    final emailRegex = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w+\b');
    
    int lastIndex = 0;
    for (final match in emailRegex.allMatches(content)) {
      // 添加邮箱前的普通文本
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: const TextStyle(
            fontSize: 16,
            height: 1.8,
            color: Colors.black87,
          ),
        ));
      }
      
      // 添加可点击的邮箱
      final email = match.group(0)!;
      spans.add(TextSpan(
        text: email,
        style: TextStyle(
          fontSize: 16,
          height: 1.8,
          color: Theme.of(context).primaryColor,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchEmail(email),
      ));
      
      lastIndex = match.end;
    }
    
    // 添加最后剩余的文本
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: const TextStyle(
          fontSize: 16,
          height: 1.8,
          color: Colors.black87,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '更新日期：2025年11月14日',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            _buildRichText(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 隐私协议内容
  static const String privacyContent = '''
我们重视并保护用户的隐私信息。本隐私协议说明了我们如何收集、使用、存储和保护您的个人信息。

1. 信息收集

我们会收集您在使用服务时提供的信息，包括但不限于：
• 账号信息（用户名、密码）
• 个人信息（姓名、手机号、邮箱等）
• 设备信息（设备型号、操作系统版本等）
• 日志信息（IP地址、访问时间、访问页面等）

2. 信息使用

我们会使用收集的信息用于以下目的：
• 提供、维护和改进我们的服务
• 处理您的请求和查询
• 发送服务相关的通知和更新
• 保护账号安全，防止欺诈行为
• 分析服务使用情况，优化用户体验

3. 信息保护

我们采取以下措施保护您的个人信息：
• 使用加密技术传输和存储敏感信息
• 限制员工访问个人信息的权限
• 定期进行安全评估和更新
• 遵守相关法律法规的要求

4. 信息共享

我们不会将您的个人信息出售给第三方。但在以下情况下，我们可能会共享您的信息：
• 获得您的明确同意
• 为提供服务所必需的第三方服务商
• 遵守法律法规的要求
• 保护我们或他人的合法权益

5. 您的权利

您对自己的个人信息享有以下权利：
• 访问和查看您的个人信息
• 更正不准确的个人信息
• 删除您的个人信息
• 撤回授权同意
• 投诉和举报

6. 第三方SDK及权限说明

为了向您提供更好的服务体验，我们的应用集成了以下第三方SDK和系统权限：

6.1 网络通信类
• Dio网络框架
  - 用途：实现HTTP网络请求，用于登录、注册、数据传输等功能
  - 收集信息：网络状态、请求响应数据
  - 开发者：Flutter社区开源项目
  - 隐私政策：https://pub.dev/packages/dio

• WebSocket连接
  - 用途：实现即时通讯功能，保持消息实时同步
  - 收集信息：设备标识、用户ID、消息内容、连接状态
  - 数据传输：全程加密传输

6.2 多媒体处理类
• CachedNetworkImage图片缓存
  - 用途：优化图片加载速度，减少流量消耗
  - 收集信息：图片缓存数据、设备存储信息
  - 存储位置：应用沙盒目录
  - 隐私政策：https://pub.dev/packages/cached_network_image

• ImagePicker图片选择器
  - 用途：选择相册图片或拍照功能
  - 所需权限：相机权限、相册访问权限
  - 收集信息：仅访问用户主动选择的图片
  - 隐私政策：https://pub.dev/packages/image_picker

• ImageGallerySaver图片保存
  - 用途：将聊天图片保存到系统相册
  - 所需权限：相册写入权限
  - 收集信息：无，仅保存用户主动选择的图片
  - 隐私政策：https://pub.dev/packages/image_gallery_saver

• VideoPlayer视频播放器
  - 用途：播放视频消息
  - 收集信息：视频文件元数据（时长、分辨率等）
  - 隐私政策：https://pub.dev/packages/video_player

• FlutterTTS语音合成
  - 用途：文本朗读功能，将文字消息转为语音
  - 收集信息：待朗读的文本内容（不上传服务器）
  - 处理方式：本地设备处理，不涉及网络传输
  - 隐私政策：https://pub.dev/packages/flutter_tts

6.3 系统功能类
• PermissionHandler权限管理
  - 用途：统一管理应用权限申请
  - 所需权限：根据功能按需申请（相机、相册、存储等）
  - 权限使用：仅在用户主动使用相关功能时申请
  - 隐私政策：https://pub.dev/packages/permission_handler

• SharePlus分享功能
  - 用途：分享文字和图片到其他应用
  - 收集信息：仅访问用户主动选择的分享内容
  - 隐私政策：https://pub.dev/packages/share_plus

• PathProvider路径获取
  - 用途：获取应用临时目录和缓存目录
  - 收集信息：无，仅获取系统路径
  - 隐私政策：https://pub.dev/packages/path_provider

• SharedPreferences本地存储
  - 用途：存储应用配置、好友备注等本地数据
  - 存储位置：应用沙盒目录
  - 数据安全：仅应用本身可访问
  - 隐私政策：https://pub.dev/packages/shared_preferences

6.4 权限使用说明
我们会在使用以下权限前向您申请授权：
• 相机权限：用于拍照发送图片或视频
• 相册权限：用于选择相册中的图片或视频
• 存储权限：用于保存图片到相册
• 网络权限：用于消息收发和数据同步

您可以随时在系统设置中关闭这些权限，但可能会影响部分功能的使用。

6.5 数据安全承诺
• 所有SDK均为开源社区广泛使用的成熟组件
• 所有网络传输均采用HTTPS加密协议
• 本地数据存储在应用沙盒内，其他应用无法访问
• 我们不会收集您的通讯录、位置、剪贴板等敏感信息
• 第三方SDK不会在后台自动收集或上传您的个人信息

如有任何疑问，请通过邮箱 shangluo24244@163.com 联系我们了解更多信息。

7. 未成年人保护

我们不会故意收集未满14周岁未成年人的个人信息。如果您是未成年人的监护人，发现我们收集了未成年人的信息，请联系我们。

8. 联系我们

如果您对本隐私协议有任何疑问，或需要行使您的权利，请通过以下方式联系我们：
• 邮箱：shangluo24244@163.com

9. 协议更新

我们可能会不时更新本隐私协议。更新后的协议将在应用内发布，并在重要变更时通知您。''';

  // 用户协议内容
  static const String userContent = '''
欢迎使用我们的服务。在使用前，请仔细阅读本用户协议。

1. 服务条款

1.1 接受条款
使用本服务即表示您同意遵守本协议的所有条款和条件。

1.2 服务内容
我们提供即时通讯服务，包括但不限于文字、语音、视频聊天等功能。

1.3 服务变更
我们保留随时修改或终止服务的权利，恕不另行通知。

2. 账号管理

2.1 账号注册
您需要提供真实、准确、完整的信息来注册账号。

2.2 账号安全
您有责任维护账号和密码的安全性，对账号下的所有活动负责。

2.3 账号使用
一个手机号只能注册一个账号。禁止出租、出借或转让账号。

3. 用户行为规范

您在使用服务时，不得从事以下行为：
• 发布违法、违规、不实信息
• 侵犯他人知识产权或隐私权
• 发送垃圾信息或广告
• 使用外挂、插件等非法工具
• 恶意攻击系统或其他用户
• 进行欺诈、赌博等违法活动

4. 内容规范

4.1 内容发布
您对发布的内容承担全部责任，确保内容合法、真实、准确。

4.2 内容审核
我们有权对用户发布的内容进行审核，删除违规内容。

4.3 知识产权
您发布的原创内容归您所有，但授权我们使用、展示和传播。

5. 隐私保护

我们重视您的隐私保护，具体内容请参阅《隐私协议》。

6. 免责声明

6.1 服务质量
我们尽力提供稳定的服务，但不保证服务不中断或无错误。

6.2 用户内容
我们不对用户发布的内容负责，用户应自行承担相关风险。

6.3 第三方链接
服务中可能包含第三方链接，我们不对第三方内容负责。

7. 违约责任

7.1 违约行为
如您违反本协议，我们有权采取以下措施：
• 警告或限制功能
• 暂停或终止服务
• 删除违规内容
• 追究法律责任

7.2 损害赔偿
因您的违约行为造成损失的，您应承担赔偿责任。

8. 协议修改

我们可能会修改本协议，修改后的协议将在应用内公布。继续使用服务即表示接受修改后的协议。

9. 争议解决

9.1 适用法律
本协议适用中华人民共和国法律。

9.2 争议处理
因本协议产生的争议，双方应友好协商解决；协商不成的，提交我司所在地人民法院诉讼解决。

10. 联系方式

如有任何疑问，请联系我们：
• 邮箱：shangluo24244@163.com

生效日期：2025年11月14日''';
}

