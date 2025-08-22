# 📦 PadCast 构建指南

本文档提供了从源码构建 PadCast 应用的详细说明。

## 📋 前提条件

### 必需软件

1. **Flutter SDK** (版本 3.24.5 或更高)
   ```bash
   flutter --version
   # 确保版本 >= 3.24.5
   ```

2. **Dart SDK** (版本 3.9.0 或更高)
   ```bash
   dart --version
   # 确保版本 >= 3.9.0
   ```

3. **Android Studio** 或 **VS Code**
   - Android Studio: 包含 Android SDK 和模拟器
   - VS Code: 需要 Flutter 和 Dart 插件

4. **Git**
   ```bash
   git --version
   ```

### Android 开发环境

1. **Android SDK** (API Level 26+)
2. **Android SDK Build-Tools**
3. **Android SDK Platform-Tools**
4. **Android SDK Command-line Tools**

### 验证环境

运行 Flutter 环境检查：
```bash
flutter doctor
```

确保所有项目都显示 ✓，或解决任何警告/错误。

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/cairui/padcast.git
cd padcast
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 验证项目

```bash
# 检查代码质量
flutter analyze

# 运行测试
flutter test

# 检查格式
dart format --output=none --set-exit-if-changed .
```

## 🏗️ 构建类型

### 开发构建 (Debug)

用于开发和调试，包含调试信息：

```bash
# 构建 Debug APK
flutter build apk --debug

# 构建 Debug APK（分架构）
flutter build apk --debug --split-per-abi

# 直接运行到设备
flutter run
```

**输出位置**: `build/app/outputs/flutter-apk/app-debug.apk`

### 发布构建 (Release)

优化的生产版本：

```bash
# 构建 Release APK
flutter build apk --release

# 构建 Release APK（分架构）
flutter build apk --release --split-per-abi

# 构建 App Bundle（Google Play）
flutter build appbundle --release
```

**输出位置**: 
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### 预览构建 (Profile)

性能分析版本：

```bash
# 构建 Profile APK
flutter build apk --profile

# 运行 Profile 模式
flutter run --profile
```

## 📱 目标平台

### Android

#### 支持的架构
- **arm64-v8a** (推荐，64位 ARM)
- **armeabi-v7a** (32位 ARM)
- **x86_64** (64位 x86，模拟器)

#### 最低要求
- **Android API Level**: 26 (Android 8.0)
- **目标 API Level**: 34 (Android 14)
- **内存**: 至少 2GB RAM
- **存储**: 至少 100MB 可用空间

#### 分架构构建
```bash
# 构建所有架构的 APK
flutter build apk --release --split-per-abi

# 生成的文件：
# - app-arm64-v8a-release.apk (推荐)
# - app-armeabi-v7a-release.apk
# - app-x86_64-release.apk
```

### Web (实验性)

```bash
# 构建 Web 应用
flutter build web --release

# 本地预览
flutter run -d chrome
```

**输出位置**: `build/web/`

## 🔧 构建配置

### 版本配置

编辑 `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

- **1.0.0**: 版本名称 (versionName)
- **+1**: 构建号 (versionCode)

### 应用签名

#### Debug 签名
Flutter 自动使用 debug keystore，无需配置。

#### Release 签名

1. **生成签名密钥**:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **配置签名**:
创建 `android/key.properties`:
```properties
storePassword=您的密钥库密码
keyPassword=您的密钥密码
keyAlias=upload
storeFile=您的密钥库文件路径
```

3. **更新 build.gradle**:
编辑 `android/app/build.gradle`，添加签名配置。

### 混淆配置

Release 构建默认启用代码混淆。配置文件：
- `android/app/proguard-rules.pro`
- `android/app/build.gradle`

## 🚀 自动化构建

### GitHub Actions

项目已配置 GitHub Actions 自动构建。查看 `.github/workflows/ci.yml`。

#### 触发条件
- 推送到 `main` 或 `develop` 分支
- 创建 Pull Request
- 发布 Release

#### 构建产物
- **APK 文件**: 自动上传到 Actions Artifacts
- **测试报告**: 单元测试和覆盖率报告
- **分析报告**: 代码质量和安全扫描

### 本地自动化脚本

创建 `scripts/build.sh`:
```bash
#!/bin/bash
set -e

echo "🔍 检查代码质量..."
flutter analyze

echo "🧪 运行测试..."
flutter test

echo "📦 构建 Release APK..."
flutter build apk --release --split-per-abi

echo "✅ 构建完成！"
echo "📱 APK 位置: build/app/outputs/flutter-apk/"
ls -la build/app/outputs/flutter-apk/*.apk
```

使用方法：
```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

## 📊 构建优化

### 减少 APK 大小

1. **启用 R8 代码收缩**:
```gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

2. **分架构构建**:
```bash
flutter build apk --release --split-per-abi
```

3. **移除未使用的图标**:
```bash
flutter build apk --release --tree-shake-icons
```

### 提升构建速度

1. **启用 Gradle 缓存**:
```properties
# gradle.properties
org.gradle.caching=true
org.gradle.parallel=true
org.gradle.configureondemand=true
```

2. **使用本地依赖缓存**:
```bash
flutter pub get --offline  # 使用缓存
```

## 🐛 常见问题

### 构建失败

1. **Gradle 版本问题**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

2. **依赖冲突**:
```bash
flutter pub deps
flutter pub upgrade
```

3. **Android SDK 问题**:
```bash
flutter doctor --android-licenses
```

### 性能问题

1. **内存不足**:
```bash
# 增加 Gradle 堆内存
export GRADLE_OPTS="-Xmx4g"
```

2. **构建缓存**:
```bash
flutter clean
flutter pub get
```

### 签名问题

1. **密钥库路径错误**:
   - 确保 `key.properties` 中的路径正确
   - 使用绝对路径或相对于项目根目录的路径

2. **密码错误**:
   - 检查 `storePassword` 和 `keyPassword`
   - 确保没有额外的空格或特殊字符

## 📋 构建检查清单

发布前确认：

- [ ] 代码通过 `flutter analyze` 检查
- [ ] 所有测试通过 `flutter test`
- [ ] 版本号已更新 (`pubspec.yaml`)
- [ ] Release APK 构建成功
- [ ] APK 在目标设备上正常运行
- [ ] 性能测试通过
- [ ] 网络连接功能正常
- [ ] AirPlay 连接功能正常
- [ ] 更新日志已准备 (`CHANGELOG.md`)

## 📞 支持

如果遇到构建问题：

1. 查看 [故障排除文档](docs/troubleshooting.md)
2. 搜索现有 [Issues](https://github.com/cairui/padcast/issues)
3. 创建新的 [Issue](https://github.com/cairui/padcast/issues/new)

## 📚 相关文档

- [Flutter 官方构建指南](https://flutter.dev/docs/deployment/android)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)
- [代码签名](https://flutter.dev/docs/deployment/android#signing-the-app)
- [性能优化](https://flutter.dev/docs/perf)

---

**祝您构建愉快！** 🎉