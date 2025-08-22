import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MacConnectionGuideDialog extends StatelessWidget {
  const MacConnectionGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.laptop_mac, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Mac连接指南',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '准备工作',
                      Icons.checklist,
                      [
                        '确保Mac和Android设备连接到同一WiFi网络',
                        '在PadCast应用中启动AirPlay服务',
                        '运行连接测试确保所有项目通过',
                        '检查防火墙设置允许端口7000/7001/5353',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      '连接方法',
                      Icons.connect_without_contact,
                      [
                        '方法一：系统偏好设置 → 显示器 → 隔空播放显示器',
                        '方法二：控制中心 → 屏幕镜像',
                        '方法三：菜单栏 → 隔空播放图标',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      '故障排除',
                      Icons.build,
                      [
                        '设备未发现：重启路由器mDNS功能，检查WiFi连接',
                        '连接失败：检查端口占用，重启AirPlay服务',
                        '性能问题：降低屏幕分辨率，关闭后台应用',
                        '音频问题：检查Mac音频输出设置',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      '技术信息',
                      Icons.info,
                      [
                        '设备名称：OPPO Pad - PadCast',
                        '支持协议：AirPlay 2.0, RTSP/RTP',
                        '最大分辨率：1920x1080 @ 30fps',
                        '音频支持：立体声 AAC 44.1/48kHz',
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyDebugInfo(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('复制调试信息'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openConnectionTest(context);
                    },
                    icon: const Icon(Icons.assessment),
                    label: const Text('运行连接测试'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16, color: Colors.grey)),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _copyDebugInfo(BuildContext context) {
    const debugInfo = '''
PadCast AirPlay 调试信息
======================
设备名称: OPPO Pad - PadCast
协议版本: AirPlay 2.0
HTTP端口: 7000
RTSP端口: 7001
mDNS端口: 5353

支持功能:
- 屏幕镜像
- H.264视频解码
- AAC音频解码
- 硬件加速

连接故障排除步骤:
1. 检查网络连接 (同一WiFi)
2. 运行PadCast连接测试
3. 检查防火墙设置
4. 重启AirPlay服务
5. 重启Mac AirPlay守护进程

技术支持: 请提供此信息和连接测试结果
''';

    Clipboard.setData(const ClipboardData(text: debugInfo));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('调试信息已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openConnectionTest(BuildContext context) {
    Navigator.pushNamed(context, '/connectionTest');
  }
}