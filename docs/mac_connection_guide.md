# Mac AirPlay 连接测试指南

## 准备工作

### 1. 确保网络环境
- Mac 和 Android 设备连接到同一个 WiFi 网络
- 确保路由器支持组播 (mDNS/Bonjour)
- 防火墙设置允许以下端口：
  - 7000 (HTTP AirPlay 服务)
  - 7001 (RTSP 流媒体控制)
  - 5353 (mDNS 服务发现)

### 2. PadCast 应用设置
1. 打开 PadCast 应用
2. 进入设置页面
3. 点击"连接测试"按钮
4. 确保所有测试项目都通过 ✅
5. 启动 AirPlay 服务

## 连接步骤

### 方法一：通过系统偏好设置
1. 在 Mac 上打开"系统偏好设置"
2. 选择"显示器"
3. 点击"隔空播放显示器"下拉菜单
4. 查找"OPPO Pad - PadCast"设备
5. 选择设备进行连接

### 方法二：通过控制中心
1. 点击 Mac 菜单栏右上角的控制中心图标
2. 点击"屏幕镜像"按钮
3. 在可用设备列表中找到"OPPO Pad - PadCast"
4. 点击连接

### 方法三：通过 Finder
1. 打开 Finder
2. 在侧边栏的"网络"部分查找 AirPlay 设备
3. 点击"OPPO Pad - PadCast"
4. 选择屏幕镜像选项

## 测试项目

### 基础连接测试
- [ ] Mac 能发现 PadCast 设备
- [ ] 成功建立 AirPlay 连接
- [ ] 状态指示灯显示"已连接"

### 屏幕镜像测试
- [ ] Mac 桌面正确显示在 Android 设备上
- [ ] 屏幕比例和分辨率适配正确
- [ ] 鼠标移动和点击同步
- [ ] 窗口拖拽和调整大小正常

### 性能测试
- [ ] 延迟低于 100ms (理想状态 < 50ms)
- [ ] 帧率稳定在 15-30 FPS
- [ ] 没有明显的视频撕裂或卡顿
- [ ] 音频同步正确 (如果支持)

### 稳定性测试
- [ ] 连续播放 10 分钟无断线
- [ ] 网络波动时能自动恢复
- [ ] 正常断开连接不会导致应用崩溃

## 故障排除

### 设备未被发现
1. 检查 WiFi 连接状态
2. 重启路由器的 mDNS 功能
3. 在 PadCast 中重新启动 AirPlay 服务
4. 检查防火墙设置

### 连接失败
1. 查看 PadCast 连接测试结果
2. 检查端口 7000/7001 是否被占用
3. 尝试重启 Mac 的 AirPlay 功能：
   ```bash
   sudo launchctl unload /System/Library/LaunchDaemons/com.apple.airplay.daemon.plist
   sudo launchctl load /System/Library/LaunchDaemons/com.apple.airplay.daemon.plist
   ```

### 性能问题
1. 降低 Mac 屏幕分辨率
2. 关闭不必要的后台应用
3. 确保 Android 设备有足够的可用内存
4. 检查网络带宽和信号强度

### 音频问题
1. 检查 Mac 音频输出设置
2. 确保 PadCast 有音频录制权限
3. 调整音频同步设置

## 高级调试

### 网络抓包
使用 Wireshark 捕获网络包来分析连接问题：
```bash
# 捕获 mDNS 流量
sudo tcpdump -i en0 port 5353

# 捕获 AirPlay 流量
sudo tcpdump -i en0 port 7000 or port 7001
```

### 日志分析
在 PadCast 中查看详细日志：
1. 进入设置 → 调试日志
2. 设置日志级别为"详细"
3. 重现问题并导出日志
4. 分析连接建立和数据传输过程

### 性能监控
监控关键指标：
- 网络延迟 (ping 时间)
- 吞吐量 (视频数据传输速率)
- CPU 使用率 (Android 设备)
- 内存使用情况

## 已知限制

### 当前版本限制
- 仅支持屏幕镜像（不支持媒体播放）
- 音频同步可能存在轻微延迟
- 最大分辨率支持 1920x1080
- 帧率限制在 30 FPS

### Mac 系统兼容性
- macOS 10.15+ (推荐 macOS 12+)
- 支持 Intel 和 Apple Silicon Mac
- 某些企业网络环境可能需要额外配置

## 反馈和报告

如果遇到问题，请提供以下信息：
1. Mac 型号和 macOS 版本
2. Android 设备型号和系统版本
3. 网络环境 (路由器型号、网络拓扑)
4. 具体错误现象和重现步骤
5. PadCast 连接测试结果截图
6. 相关日志文件

## 更新记录

- v1.0.0: 基础 AirPlay 接收功能
- v1.1.0: 改进设备发现和连接稳定性
- v1.2.0: 性能优化和错误处理增强