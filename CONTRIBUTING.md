# 贡献指南

感谢您对 PadCast 项目的关注！我们欢迎各种形式的贡献，包括但不限于：

- 🐛 报告 Bug
- 💡 提出新功能建议
- 📝 改进文档
- 🔧 提交代码修复
- ✨ 开发新功能

## 📋 开始之前

### 环境要求

- Flutter 3.9.0 或更高版本
- Dart 3.9.0 或更高版本
- Android Studio 或 VS Code
- Git

### 项目设置

```bash
# 1. Fork 并克隆仓库
git clone https://github.com/YOUR_USERNAME/padcast.git
cd padcast

# 2. 安装依赖
flutter pub get

# 3. 运行项目确保正常工作
flutter run

# 4. 运行测试确保通过
flutter test
flutter analyze
```

## 🐛 报告问题

在创建新的 Issue 之前，请：

1. **搜索现有的 Issues** 确保问题尚未被报告
2. **使用最新版本** 确认问题在最新版本中仍然存在
3. **提供详细信息** 包括：
   - 设备型号和操作系统版本
   - PadCast 应用版本
   - 重现步骤
   - 预期行为 vs 实际行为
   - 日志输出或截图

### Issue 模板

```markdown
**问题描述**
简洁清晰地描述问题是什么。

**重现步骤**
1. 前往 '...'
2. 点击 '....'
3. 滚动到 '....'
4. 看到错误

**预期行为**
描述你期望发生什么。

**截图**
如果适用，添加截图来帮助解释你的问题。

**设备信息:**
 - 设备: [例如 OPPO Pad 4 Pro]
 - 操作系统: [例如 Android 12]
 - 应用版本: [例如 1.0.0]

**其他上下文**
添加关于问题的任何其他上下文。
```

## 💡 功能建议

我们欢迎新功能建议！请：

1. **检查是否已存在** 搜索现有的 Issues 和 Discussions
2. **描述用例** 解释为什么需要这个功能
3. **提供细节** 包括预期的行为和可能的实现方式

## 🔧 代码贡献

### 工作流程

1. **创建 Issue** (如果还没有的话)
2. **Fork 仓库** 到你的 GitHub 账户
3. **创建分支** 从 `main` 分支创建新的功能分支
4. **编写代码** 遵循项目的编码规范
5. **添加测试** 为新功能或修复添加相应的测试
6. **运行测试** 确保所有测试通过
7. **提交 PR** 创建 Pull Request

### 分支命名规范

```bash
# 功能开发
feature/add-new-codec-support
feature/improve-sync-algorithm

# Bug 修复
fix/audio-sync-issue
fix/network-reconnection-bug

# 文档更新
docs/update-installation-guide
docs/add-api-documentation

# 性能优化
perf/reduce-memory-usage
perf/optimize-video-rendering
```

### 提交信息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```bash
feat: 添加 H.265 编解码器支持
fix: 修复音视频同步偏移问题
docs: 更新安装指南
perf: 优化视频渲染性能
test: 添加网络监控单元测试
refactor: 重构设置服务架构
```

### 代码风格

#### Flutter/Dart 规范

```dart
// ✅ 好的示例
class VideoDecoderService {
  static const int _defaultBufferSize = 10;
  
  Future<void> initialize({
    required String codecType,
    int bufferSize = _defaultBufferSize,
  }) async {
    // 实现细节
  }
}

// ❌ 避免的写法
class videoDecoderService {
  static int defaultBufferSize = 10;
  
  initialize(codecType, bufferSize) async {
    // 缺少类型注解和规范命名
  }
}
```

#### 注释规范

```dart
/// 音视频同步服务
/// 
/// 负责维持音频和视频流之间的精确同步，确保
/// 播放体验的质量。支持动态同步调整和抖动控制。
class AudioVideoSyncService {
  /// 计算音视频时间偏移
  /// 
  /// [audioTimestamp] 音频时间戳（毫秒）
  /// [videoTimestamp] 视频时间戳（毫秒）
  /// 
  /// 返回偏移量，正值表示视频超前，负值表示音频超前
  double calculateOffset(double audioTimestamp, double videoTimestamp) {
    return videoTimestamp - audioTimestamp;
  }
}
```

### 测试要求

#### 必须包含测试的情况

- 新功能开发
- Bug 修复
- API 变更
- 性能优化

#### 测试类型

```dart
// 单元测试示例
import 'package:flutter_test/flutter_test.dart';
import 'package:padcast/services/audio_video_sync_service.dart';

void main() {
  group('AudioVideoSyncService', () {
    late AudioVideoSyncService syncService;
    
    setUp(() {
      syncService = AudioVideoSyncService();
    });
    
    test('should calculate correct offset', () {
      // Arrange
      const audioTimestamp = 1000.0;
      const videoTimestamp = 1050.0;
      
      // Act
      final offset = syncService.calculateOffset(audioTimestamp, videoTimestamp);
      
      // Assert
      expect(offset, equals(50.0));
    });
  });
}
```

#### 测试命令

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/services/audio_video_sync_service_test.dart

# 生成测试覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📝 文档贡献

### 文档类型

- **README.md**: 项目介绍和快速开始
- **API 文档**: 代码内的文档注释
- **用户指南**: 详细的使用说明
- **开发者文档**: 架构设计和开发指南

### 文档写作规范

- 使用清晰简洁的语言
- 提供实际的代码示例
- 包含截图或图表（如适用）
- 保持更新与代码同步

## 🔍 代码审查流程

### Pull Request 要求

1. **描述清楚** 说明变更的目的和影响
2. **关联 Issue** 引用相关的 Issue 编号
3. **测试覆盖** 包含足够的测试
4. **文档更新** 如果需要，更新相关文档

### PR 模板

```markdown
## 变更描述
简要描述这次变更解决了什么问题或添加了什么功能。

## 变更类型
- [ ] 🐛 Bug 修复
- [ ] ✨ 新功能
- [ ] 📝 文档更新
- [ ] 🎨 代码风格改进
- [ ] ♻️ 代码重构
- [ ] ⚡ 性能优化
- [ ] ✅ 测试添加或更新

## 关联 Issue
Fixes #123

## 测试
- [ ] 添加了新的测试
- [ ] 所有现有测试都通过
- [ ] 在设备上手动测试过

## 截图（如适用）

## 检查清单
- [ ] 代码遵循项目风格指南
- [ ] 自我审查了代码变更
- [ ] 添加了必要的注释
- [ ] 更新了相关文档
- [ ] 变更不会产生新的警告
```

## 🎉 认可贡献者

我们使用 [All Contributors](https://allcontributors.org/) 规范来认可贡献者。

贡献类型包括：
- 💻 代码
- 📖 文档
- 🐛 Bug 报告
- 💡 想法和规划
- 🤔 问答解答
- 📢 推广宣传
- 🎨 设计

## 📞 联系我们

如有任何问题或需要帮助，请：

- 创建 [Issue](https://github.com/cairui/padcast/issues)
- 参与 [Discussions](https://github.com/cairui/padcast/discussions)
- 发送邮件到项目维护者

感谢您的贡献！🎉