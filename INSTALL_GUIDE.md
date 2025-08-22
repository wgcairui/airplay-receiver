# PadCast AirPlay 接收器 - 安装指南

## 🚀 全新签名和包名配置

### ✅ 已完成的更改

1. **包名完全更改**：
   - 旧包名：`com.oppo.padcast.padcast`
   - **新包名：`com.airplay.padcast.receiver`**
   - 完全避免与现有应用冲突

2. **全新自定义签名**：
   - 签名文件：`android/app/airplay-padcast-key.jks`
   - 签名别名：`airplay-padcast`
   - 证书信息：`CN=AirPlay PadCast, OU=Mobile Development, O=AirPlay Receiver Apps`
   - 有效期：10000天

3. **独立应用标识**：
   - 应用名称：PadCast
   - 新设计的AirPlay主题图标
   - 完全独立的应用数据和配置

## 📱 安装说明

### 当前APK信息
- **文件路径**：`build/app/outputs/flutter-apk/app-release.apk`
- **文件大小**：49.0MB
- **包名**：`com.airplay.padcast.receiver`
- **签名**：自定义签名（非debug签名）

### 安装步骤

1. **启用未知来源安装**：
   - 在Android设备上进入 设置 > 安全 > 未知来源
   - 或者 设置 > 应用和通知 > 特殊应用访问 > 安装未知应用

2. **传输APK文件**：
   ```bash
   # 通过ADB安装（推荐）
   adb install build/app/outputs/flutter-apk/app-release.apk
   
   # 或者将APK文件复制到设备并手动安装
   adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/
   ```

3. **直接安装**：
   - 在设备上找到APK文件并点击安装
   - 系统会提示安装权限，点击确认

## 🔍 验证安装

安装成功后，您会看到：
- 新的PadCast应用图标（蓝色AirPlay主题）
- 与现有应用完全分离
- 可以同时运行两个版本

## 🔧 技术详情

### 签名信息
```
密钥库：android/app/airplay-padcast-key.jks
别名：airplay-padcast
密码：AirPlay2024（开发使用）
算法：RSA 2048位
有效期：10000天
```

### 包名空间
```
命名空间：com.airplay.padcast.receiver
应用ID：com.airplay.padcast.receiver
```

## ⚠️ 注意事项

1. **完全独立**：此版本与原有应用完全独立，数据不共享
2. **自定义签名**：使用完全自定义的签名，避免任何冲突
3. **新包名**：包名已完全更改，确保唯一性
4. **测试环境**：建议先在测试设备上验证功能

## 🎯 功能特性

- ✅ AirPlay视频接收
- ✅ 硬件加速解码
- ✅ 音视频同步
- ✅ 性能监控优化
- ✅ mDNS服务发现
- ✅ 专为OPPO Pad 4 Pro优化

---

**安装问题？** 如果仍然提示签名冲突，请：
1. 确认完全卸载了旧版本应用
2. 重启设备后再次尝试
3. 检查是否有其他相同包名的应用残留