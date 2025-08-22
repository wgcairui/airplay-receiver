# PadCast App Icon Design

## 设计理念

PadCast的应用图标设计体现了其作为AirPlay接收器的核心功能，采用现代化、简洁的设计风格。

### 设计元素

1. **主体 - 平板设备**
   - 中央的平板设备轮廓代表OPPO Pad 4 Pro
   - 圆角矩形设计符合现代设备美学
   - 渐变填充营造立体感和现代感

2. **无线信号波纹**
   - 环绕设备的无线信号波纹表示AirPlay信号接收
   - 多层波纹设计展现信号的强度和连续性
   - 半透明效果增加层次感

3. **AirPlay图标元素**
   - 屏幕中央的小型设备图标代表发送端（iPhone/Mac）
   - 箭头指向平板，直观表达投屏功能
   - 简化的图标设计保持清晰度

4. **信号粒子**
   - 分散的小圆点表示数据传输
   - 增强动感和科技感

### 配色方案

- **主色调**: 蓝色渐变 (#4FC3F7 → #1976D2)
  - 体现科技感和可靠性
  - 符合Material Design规范
  - 与AirPlay品牌调性一致

- **辅助色**: 白色和浅蓝色
  - 提供良好的对比度
  - 保证图标在不同背景下的可读性

### 技术规格

- **源文件**: SVG格式（矢量图）
- **生成分辨率**:
  - mdpi: 48×48px
  - hdpi: 72×72px  
  - xhdpi: 96×96px
  - xxhdpi: 144×144px
  - xxxhdpi: 192×192px

### 设计目标

1. **功能识别性**: 用户能立即理解这是一个无线投屏接收应用
2. **品牌一致性**: 与PadCast应用的整体设计风格保持一致
3. **平台适配性**: 适配Android各种屏幕密度和主题
4. **视觉吸引力**: 现代化设计吸引目标用户群体

## 文件结构

```
assets/icons/
├── app_icon.svg           # 源SVG文件
└── README.md             # 设计说明文档

android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png     # 48×48
├── mipmap-hdpi/ic_launcher.png     # 72×72
├── mipmap-xhdpi/ic_launcher.png    # 96×96
├── mipmap-xxhdpi/ic_launcher.png   # 144×144
└── mipmap-xxxhdpi/ic_launcher.png  # 192×192
```

## 更新记录

- **v1.0.0**: 初始设计，替换默认Flutter图标
  - 采用AirPlay主题设计
  - 生成全套Android分辨率图标
  - 集成到应用构建流程