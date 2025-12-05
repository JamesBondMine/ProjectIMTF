# 趣聊官网

这是趣聊应用的官方网站，使用纯 HTML + CSS + JavaScript 构建。

## 📁 文件结构

```
website/
├── index.html              # 主页面
├── style.css              # 主页面样式
├── script.js              # 主页面脚本
├── privacy.html           # 隐私政策页面
├── terms.html             # 用户协议页面
├── privacy-style.css      # 政策页面样式
├── privacy-script.js      # 政策页面脚本
├── README.md              # 说明文档
└── img/                   # 图片文件夹
    ├── 聊天.PNG
    ├── 动态.PNG
    ├── 好友信息.PNG
    ├── 我的个人信息.PNG
    └── 评论列表.PNG
```

## 🚀 使用方法

### 方法 1：直接打开

1. 双击 `index.html` 文件
2. 网站会在默认浏览器中打开

### 方法 2：使用本地服务器（推荐）

#### 使用 Python：
```bash
# Python 3
cd website
python3 -m http.server 8000

# 然后访问 http://localhost:8000
```

#### 使用 Node.js：
```bash
# 安装 http-server
npm install -g http-server

# 启动服务器
cd website
http-server -p 8000

# 然后访问 http://localhost:8000
```

#### 使用 VS Code Live Server：
1. 安装 Live Server 扩展
2. 右键 `index.html`
3. 选择 "Open with Live Server"

## 🎨 功能特点

- ✅ 响应式设计，适配手机、平板、电脑
- ✅ 平滑滚动和导航
- ✅ 5 张应用截图自动轮播展示
- ✅ 详细的功能介绍卡片，配合实际截图
- ✅ 技术亮点展示区域
- ✅ 优雅的动画效果和交互
- ✅ 现代化的渐变色主题（梦幻紫色系）
- ✅ 无需任何外部依赖，纯原生实现

## 📝 自定义配置

### 修改主题色

编辑 `style.css` 中的 CSS 变量：

```css
:root {
    --primary-color: #AB47BC;      /* 主色 */
    --primary-dark: #8E24AA;       /* 深色 */
    --primary-light: #CE93D8;      /* 浅色 */
    --secondary-color: #7B1FA2;    /* 次要色 */
}
```

### 修改联系邮箱

编辑 `index.html` 中的邮箱地址：
```html
<a href="mailto:xsl0518lx37@icloud.com">xsl0518lx37@icloud.com</a>
```

### 更换截图

1. 将新截图放在 `../Runner/img/` 目录下
2. 在 `index.html` 中更新图片路径
3. 或者直接在 `website` 目录下创建 `images` 文件夹并使用相对路径

### 修改轮播速度

编辑 `script.js`：
```javascript
// 将 5000 改为你想要的毫秒数（例如 3000 = 3秒）
let autoPlayInterval = setInterval(autoPlay, 5000);
```

## 🌐 部署到线上

### 部署到 GitHub Pages：

1. 创建 GitHub 仓库
2. 上传 `website` 文件夹内容
3. 在仓库设置中启用 GitHub Pages
4. 选择 main 分支作为源

### 部署到 Netlify：

1. 注册 Netlify 账号
2. 拖拽 `website` 文件夹到 Netlify
3. 自动生成域名

### 部署到 Vercel：

1. 注册 Vercel 账号
2. 导入 GitHub 仓库
3. 自动部署

## 📱 截图展示

网站使用了 5 张精美的应用截图：

### 1. 聊天.PNG - 即时聊天界面
- 展示位置：首页 Hero 区域、详细功能展示第1张、轮播图第1张
- 功能亮点：实时消息、表情包、已读状态

### 2. 动态.PNG - 动态分享界面
- 展示位置：首页背景、详细功能展示第2张、轮播图第2张
- 功能亮点：瀑布流布局、点赞评论、话题标签

### 3. 好友信息.PNG - 好友详情界面
- 展示位置：详细功能展示第3张、轮播图第3张
- 功能亮点：好友资料、动态展示、互动功能

### 4. 我的个人信息.PNG - 个人中心界面
- 展示位置：详细功能展示第4张、轮播图第4张
- 功能亮点：梦幻渐变、账号管理、隐私设置

### 5. 评论列表.PNG - 评论互动界面
- 展示位置：详细功能展示第5张、轮播图第5张
- 功能亮点：多级评论、@提及、实时通知

## 🔧 浏览器兼容性

- ✅ Chrome/Edge (推荐)
- ✅ Safari
- ✅ Firefox
- ✅ Opera
- ⚠️ IE 11 (部分效果不支持)

## 📄 隐私政策与用户协议

网站包含完整的法律文档：

### 隐私政策 (`privacy.html`)
- ✅ 完整的隐私政策条款
- ✅ 8 个主要章节
- ✅ 侧边栏目录导航
- ✅ 点击标题复制链接
- ✅ 返回顶部按钮
- ✅ 打印功能
- ✅ 响应式设计

### 用户协议 (`terms.html`)
- ✅ 完整的用户协议条款
- ✅ 8 个主要章节
- ✅ 用户行为规范
- ✅ 知识产权声明
- ✅ 免责声明
- ✅ 争议解决条款

## 📱 页面列表

1. **首页** (`index.html`)
   - Hero 区域
   - 核心功能介绍
   - 详细功能展示
   - 技术亮点
   - 截图轮播
   - 下载区域

2. **隐私政策** (`privacy.html`)
   - 信息收集与使用
   - Cookie 使用说明
   - 信息共享条款
   - 数据安全措施
   - 用户权利管理
   - 未成年人保护

3. **用户协议** (`terms.html`)
   - 账号注册规范
   - 用户行为规范
   - 服务内容说明
   - 知识产权声明
   - 免责声明
   - 法律适用条款

## 📄 许可证

© 2025 趣聊. All rights reserved.

