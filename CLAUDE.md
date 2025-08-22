# CLAUDE.md - PadCast AirPlay Receiver

This file provides guidance to Claude Code (claude.ai/code) when working with the PadCast AirPlay receiver project.

## Commands

### Build
```bash
cd padcast
flutter build apk --release  # Release APK (49.6MB)
flutter build apk --debug    # Debug APK
```

### Test
```bash
cd padcast
flutter test                 # Run Dart unit tests
flutter analyze             # Code analysis (currently clean)
```

### Lint
```bash
cd padcast
flutter analyze             # Static analysis
dart fix --apply            # Auto-fix issues
```

### Development
```bash
cd padcast
flutter run                 # Hot reload development
flutter clean               # Clean build cache
flutter pub get             # Update dependencies
```

## Architecture

### Project Structure
PadCast是一个专为OPPO Pad 4 Pro开发的AirPlay接收器应用，采用Flutter + 原生Android插件架构。

```
padcast/
├── lib/                    # Flutter Dart代码
│   ├── main.dart          # 应用入口
│   ├── controllers/       # MVC控制器层
│   │   └── airplay_controller.dart
│   ├── services/          # 核心服务层
│   │   ├── airplay_service.dart        # 主AirPlay服务
│   │   ├── mdns_service.dart          # mDNS设备发现
│   │   ├── rtsp_service.dart          # RTSP流媒体协议
│   │   ├── video_decoder_service.dart # 视频解码服务
│   │   ├── audio_decoder_service.dart # 音频解码服务
│   │   ├── logger_service.dart        # 日志记录服务
│   │   └── ...
│   ├── views/             # 用户界面页面
│   │   ├── home_view.dart             # 主页面
│   │   ├── video_streaming_view.dart  # 视频播放页面
│   │   ├── debug_log_view.dart        # 调试日志页面
│   │   ├── connection_test_view.dart  # 连接测试页面
│   │   └── settings_view.dart         # 设置页面
│   ├── widgets/           # UI组件
│   │   ├── video_renderer_widget.dart # 视频渲染器
│   │   ├── connection_status_widget.dart
│   │   └── ...
│   └── models/            # 数据模型
│       └── connection_state.dart
├── android/               # Android原生代码
│   └── app/src/main/kotlin/com/airplay/padcast/receiver/
│       ├── MainActivity.kt            # Flutter主活动
│       ├── VideoDecoderPlugin.kt      # 视频解码插件
│       ├── AudioDecoderPlugin.kt      # 音频解码插件
│       └── MdnsPlugin.kt              # mDNS广播插件
└── assets/                # 资源文件
    └── icons/             # 应用图标
```

### Key Components

#### 🎯 核心服务架构
- **AirPlayService**: 统一管理所有AirPlay相关服务的主控制器
- **MdnsService**: 负责mDNS/Bonjour设备发现和服务广播  
- **RtspService**: 处理RTSP流媒体控制协议
- **VideoDecoderService**: H.264视频流解码（Flutter侧）
- **AudioDecoderService**: AAC音频流解码（Flutter侧）
- **LoggerService**: 统一日志记录和调试支持
- **ConnectionTestService**: AirPlay连接诊断和测试系统

#### 🔌 原生插件集成
- **VideoDecoderPlugin**: Android MediaCodec硬件视频解码
- **AudioDecoderPlugin**: Android MediaCodec硬件音频解码
- **MdnsPlugin**: Android多播DNS服务广播

#### 📱 用户界面层
- **HomeView**: 主控制界面，显示连接状态和网络信息
- **VideoStreamingView**: 全屏视频播放界面，支持横屏和性能监控
- **DebugLogView**: 实时日志查看器，支持级别过滤和导出
- **ConnectionTestView**: 连接诊断界面，全面测试AirPlay功能
- **VideoRendererWidget**: 可复用的视频渲染组件

#### 🔄 状态管理
- **Provider**: Flutter官方状态管理解决方案
- **AirPlayController**: 统一的应用状态控制器
- **Stream监听**: 响应式数据流处理

### Technical Specifications

#### 🚀 AirPlay协议支持
- **协议版本**: AirPlay 1.0 (向下兼容)
- **视频编码**: H.264/AVC
- **音频编码**: AAC
- **传输协议**: RTSP/RTP over UDP
- **控制协议**: HTTP REST API

#### 📊 性能指标
- **延迟**: < 100ms (目标)
- **帧率**: 支持30/60fps
- **分辨率**: 最高1920x1080
- **音频**: 44.1kHz/48kHz, 16-bit

#### 🔧 设备兼容性
- **目标设备**: OPPO Pad 4 Pro (13.2英寸)
- **分辨率**: 3392x2400 (7:5比例)
- **Android版本**: Android 11+ (API 30+)
- **源设备**: macOS 10.15+, iOS 9+

### Development Progress

#### ✅ 已完成 (Phase 1)
- [x] Flutter项目架构搭建
- [x] 原生Android插件开发
- [x] mDNS设备发现和广播
- [x] RTSP协议处理
- [x] HTTP AirPlay API端点
- [x] 视频/音频解码器集成
- [x] 用户界面和状态管理
- [x] 日志记录和调试工具
- [x] 应用签名和打包
- [x] 视频解码器原生集成优化
- [x] 音频播放测试功能
- [x] 连接诊断测试系统
- [x] APK构建流程完善

#### 🔄 进行中 (Phase 2)
- [ ] 实际AirPlay连接测试
- [ ] 性能调优和稳定性测试

#### 📋 待开发 (Phase 3)
- [ ] 高级AirPlay功能（镜像、扩展桌面）
- [ ] 多设备连接支持
- [ ] 用户设置和个性化
- [ ] 生产环境部署优化

### Build Information
- **当前版本**: v1.0.0-beta
- **包名**: com.airplay.padcast.receiver
- **APK大小**: 49.6MB (Release)
- **签名**: 自定义密钥库
- **最后构建**: 成功 ✓

### Testing Checklist
- [x] 代码静态分析通过
- [x] APK构建成功
- [x] 应用启动正常
- [x] 连接诊断测试功能
- [x] 视频/音频解码器测试
- [ ] mDNS广播可被发现
- [ ] Mac设备连接测试
- [ ] 视频流传输测试
- [ ] 音频同步测试
- [ ] 性能压力测试

### Known Issues
目前无已知严重问题，应用已具备完整的AirPlay接收器功能架构。