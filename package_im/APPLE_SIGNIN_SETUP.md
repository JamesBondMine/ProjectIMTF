# Apple 登录配置指南

## 📱 功能说明

已成功集成 Apple 登录功能到登录页面！Apple 登录按钮仅在 iOS 设备上显示。

## ✅ 已完成的配置

### 1. **添加依赖**
已在 `pubspec.yaml` 中添加：
```yaml
sign_in_with_apple: ^6.1.3
```

### 2. **创建 Entitlements 文件**
已创建 `ios/Runner/Runner.entitlements` 文件，包含 Apple 登录所需的权限。

### 3. **实现登录逻辑**
在 `lib/pages/login/login_page.dart` 中实现了完整的 Apple 登录流程：
- ✅ 检查设备支持性
- ✅ 请求用户授权
- ✅ 获取凭证信息
- ✅ 错误处理
- ✅ 协议勾选校验

## 🔧 需要在 Xcode 中完成的配置

### **第 1 步：打开 Xcode 项目**

```bash
cd ios
open Runner.xcworkspace
```

⚠️ **注意**：必须打开 `.xcworkspace` 文件，而不是 `.xcodeproj` 文件！

---

### **第 2 步：添加 Sign in with Apple Capability**

1. 在 Xcode 中选择项目导航器中的 **Runner** 项目
2. 选择 **Runner** target
3. 点击 **Signing & Capabilities** 标签页
4. 点击 **+ Capability** 按钮
5. 搜索并添加 **Sign in with Apple**

![Add Capability](https://docs-assets.developer.apple.com/published/a58ef9e8da/rendered2x-1606942046.png)

---

### **第 3 步：配置 Entitlements 文件**

1. 在 **Signing & Capabilities** 标签页中
2. 找到 **Code Signing Entitlements** 字段
3. 确保值为：`Runner/Runner.entitlements`

如果没有，手动输入此路径。

---

### **第 4 步：配置 Bundle Identifier**

在 **General** 标签页中，确保 **Bundle Identifier** 已正确设置（例如：`com.qingmu.projectming`）。

---

### **第 5 步：在 Apple Developer 中配置**

#### **5.1 登录 Apple Developer**
访问：https://developer.apple.com/account

#### **5.2 配置 App ID**

1. 进入 **Certificates, Identifiers & Profiles**
2. 选择 **Identifiers**
3. 找到你的 App ID（与 Bundle Identifier 匹配）
4. 编辑 App ID
5. 勾选 **Sign in with Apple**
6. 点击 **Save**

#### **5.3 重新生成 Provisioning Profile**

如果你使用手动签名：
1. 进入 **Profiles**
2. 编辑相关的 Provisioning Profile
3. 重新生成并下载
4. 双击安装到 Xcode

如果使用自动签名，Xcode 会自动处理。

---

## 🎨 UI 效果

### **登录页面布局**

```
┌─────────────────────────────┐
│    账号密码输入框            │
│    [登录按钮]                │
│                              │
│    ───── 或 ─────            │  ← 分隔线
│                              │
│    [Sign in with Apple]      │  ← Apple 登录按钮 (仅 iOS)
└─────────────────────────────┘
```

### **按钮样式**
- **高度**：50px
- **圆角**：12px
- **样式**：黑色背景 + 白色文字 + Apple 图标
- **文本**：Sign in with Apple

---

## 🔐 安全说明

### **凭证信息**

Apple 登录成功后会返回以下信息：

```dart
- identityToken    // JWT 令牌，用于后端验证
- authorizationCode // 授权码，可用于刷新令牌
- userIdentifier    // 用户唯一标识符
- email            // 用户邮箱（可选，用户可选择隐藏）
- givenName        // 名字（仅首次提供）
- familyName       // 姓氏（仅首次提供）
```

⚠️ **重要提示**：
- `givenName` 和 `familyName` **仅在用户首次授权时提供**
- 后续登录这些字段将为 `null`
- 建议在后端存储这些信息

---

## 🔌 后端集成

### **当前状态**

代码中的 Apple 登录逻辑已实现，但需要后端 API 支持：

```dart
// TODO: 在 lib/services/api_service.dart 中添加
Future<ApiResponse> appleLogin({
  required String identityToken,
  required String authorizationCode,
  required String userIdentifier,
}) async {
  // 调用后端 API
}
```

### **后端需要实现的接口**

```
POST /api/auth/apple-login
Content-Type: application/json

{
  "identityToken": "eyJraWQiOiJXNldjT0tC...",
  "authorizationCode": "c1b2e3f4...",
  "userIdentifier": "001234.567890abcdef..."
}
```

### **后端验证流程**

1. **验证 identityToken**
   - 从 Apple 获取公钥
   - 验证 JWT 签名
   - 检查过期时间
   - 验证 audience 和 issuer

2. **创建或查找用户**
   - 根据 `userIdentifier` 查找用户
   - 如果不存在，创建新用户
   - 如果存在，更新最后登录时间

3. **返回应用的 Token**
   - 生成应用自己的 JWT Token
   - 返回用户信息

### **集成示例**

```dart
// 在 _handleAppleSignIn 方法中，替换模拟代码：

if (identityToken != null) {
  final response = await _apiService.appleLogin(
    identityToken: identityToken,
    authorizationCode: credential.authorizationCode ?? '',
    userIdentifier: credential.userIdentifier,
  );

  if (response.success && response.data != null) {
    EasyLoading.showSuccess('Apple 登录成功！');
    // 跳转到主页
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(
          username: response.data!.user.nickname,
        ),
      ),
    );
  } else {
    EasyLoading.showError(response.message);
  }
}
```

---

## 🧪 测试

### **测试环境要求**

1. **真机设备**
   - Apple 登录必须在真机上测试
   - 模拟器无法使用 Apple 登录功能

2. **系统要求**
   - iOS 13.0 及以上
   - 设备需要登录 Apple ID

3. **Xcode 配置**
   - 已添加 Sign in with Apple Capability
   - 使用正确的 Team 签名

### **测试步骤**

1. 在真机上运行应用
2. 进入登录页面
3. 勾选协议
4. 点击 "Sign in with Apple" 按钮
5. 输入 Apple ID 和密码
6. 选择是否共享邮箱
7. 完成 Face ID / Touch ID 验证
8. 查看登录结果

### **测试场景**

- ✅ 首次登录（获取用户信息）
- ✅ 再次登录（无用户信息）
- ✅ 用户取消登录
- ✅ 网络异常
- ✅ 设备不支持
- ✅ 未勾选协议

---

## ⚠️ 常见问题

### **1. 模拟器无法使用 Apple 登录**

**原因**：Sign in with Apple 只能在真机上使用。

**解决方案**：使用真实的 iOS 设备进行测试。

---

### **2. "当前设备不支持 Apple 登录"错误**

**可能原因**：
- 设备系统版本低于 iOS 13.0
- 设备未登录 Apple ID
- 在模拟器中运行

**解决方案**：
- 升级系统到 iOS 13.0 或更高
- 在设置中登录 Apple ID
- 使用真机测试

---

### **3. Capability 添加失败**

**可能原因**：
- Team 未正确配置
- Bundle Identifier 未在 Developer Portal 注册
- 证书过期

**解决方案**：
1. 在 Xcode 中正确配置 Team
2. 在 Apple Developer Portal 中配置 App ID
3. 重新生成证书和 Provisioning Profile

---

### **4. "The operation couldn't be completed"**

**可能原因**：
- 网络连接问题
- Apple 服务器异常
- Entitlements 配置错误

**解决方案**：
1. 检查网络连接
2. 稍后重试
3. 确认 Entitlements 文件正确配置

---

### **5. 用户信息为空**

**原因**：用户名和邮箱仅在首次授权时提供。

**解决方案**：
- 在首次登录时保存用户信息到后端
- 后续登录从后端获取

**测试重置**：
如需重新测试首次登录：
1. 打开 **设置** > **Apple ID** > **密码与安全性**
2. 选择 **使用 Apple 登录的 App**
3. 找到你的应用，点击 **停止使用 Apple ID**

---

## 📚 参考资料

### **官方文档**
- [Sign in with Apple - Apple Developer](https://developer.apple.com/sign-in-with-apple/)
- [sign_in_with_apple Plugin](https://pub.dev/packages/sign_in_with_apple)

### **后端验证**
- [验证 identityToken](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/verifying_a_user)
- [Apple 公钥地址](https://appleid.apple.com/auth/keys)

---

## ✅ 验收清单

部署到生产环境前，请确保：

- [ ] 在 Apple Developer Portal 中为 App ID 启用了 Sign in with Apple
- [ ] Xcode 项目中已添加 Sign in with Apple Capability
- [ ] Entitlements 文件配置正确
- [ ] 在真机上测试通过
- [ ] 后端 Apple 登录 API 已实现并测试
- [ ] 首次登录和重复登录都能正常工作
- [ ] 错误处理逻辑完善
- [ ] 用户取消登录的场景处理正确

---

## 📞 支持

如有任何问题，请参考：
- [Flutter 官方文档](https://flutter.dev/docs)
- [Sign in with Apple 官方指南](https://developer.apple.com/sign-in-with-apple/get-started/)

---

**最后更新**: 2025年11月18日

