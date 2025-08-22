import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _deviceName = AppConstants.deviceName;
  String _selectedResolution = '3392×2400 (原生)';
  String _selectedRefreshRate = '144Hz';
  String _selectedDisplayMode = '扩展屏幕';
  String _selectedVideoQuality = '高';
  bool _hardwareAcceleration = true;
  bool _lowLatencyMode = true;
  bool _autoConnect = true;
  bool _performanceMonitor = false;
  bool _logging = false;
  bool _developerMode = false;
  
  final List<String> _resolutions = [
    '1920×1080',
    '2560×1600', 
    '3392×2400 (原生)',
  ];
  
  final List<String> _refreshRates = [
    '60Hz',
    '90Hz',
    '120Hz',
    '144Hz',
  ];
  
  final List<String> _displayModes = [
    '镜像屏幕',
    '扩展屏幕',
  ];
  
  final List<String> _videoQualities = [
    '低',
    '中',
    '高',
    '超高',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // 显示设置
          _buildSection(
            '显示设置',
            Icons.display_settings,
            [
              _buildDropdownTile(
                '分辨率',
                _selectedResolution,
                _resolutions,
                (value) => setState(() => _selectedResolution = value),
              ),
              _buildDropdownTile(
                '刷新率',
                _selectedRefreshRate,
                _refreshRates,
                (value) => setState(() => _selectedRefreshRate = value),
              ),
              _buildDropdownTile(
                '显示模式',
                _selectedDisplayMode,
                _displayModes,
                (value) => setState(() => _selectedDisplayMode = value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 视频设置
          _buildSection(
            '视频设置',
            Icons.video_settings,
            [
              _buildDropdownTile(
                '质量',
                _selectedVideoQuality,
                _videoQualities,
                (value) => setState(() => _selectedVideoQuality = value),
              ),
              _buildSwitchTile(
                '硬件加速',
                '使用GPU硬件解码提升性能',
                _hardwareAcceleration,
                (value) => setState(() => _hardwareAcceleration = value),
              ),
              _buildSwitchTile(
                '低延迟模式',
                '优化传输延迟，可能增加CPU使用',
                _lowLatencyMode,
                (value) => setState(() => _lowLatencyMode = value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 连接设置
          _buildSection(
            '连接设置',
            Icons.wifi,
            [
              _buildTextFieldTile(
                '设备名称',
                _deviceName,
                (value) => setState(() => _deviceName = value),
              ),
              _buildSwitchTile(
                '自动连接',
                '记住已配对设备，后续自动连接',
                _autoConnect,
                (value) => setState(() => _autoConnect = value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 高级设置
          _buildSection(
            '高级设置',
            Icons.build,
            [
              _buildSwitchTile(
                '性能监控',
                '显示实时帧率、延迟等信息',
                _performanceMonitor,
                (value) => setState(() => _performanceMonitor = value),
              ),
              _buildSwitchTile(
                '日志记录',
                '记录调试日志，可能影响性能',
                _logging,
                (value) => setState(() => _logging = value),
              ),
              _buildSwitchTile(
                '开发者模式',
                '显示详细技术信息和调试选项',
                _developerMode,
                (value) => setState(() => _developerMode = value),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 关于信息
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '关于PadCast',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '版本: ${AppConstants.appVersion}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '专为OPPO Pad 4 Pro优化的AirPlay接收端',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: value,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextFieldTile(
    String title,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}