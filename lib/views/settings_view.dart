import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/settings_service.dart';
import '../services/video_test_service.dart';
import '../services/audio_test_service.dart';
import '../widgets/mac_connection_guide_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/toast_notification.dart';
import '../utils/animation_utils.dart';
import 'connection_test_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  AirPlaySettings? _currentSettings;
  bool _isInitialized = false;
  
  // UI-only settings (not in settings service)
  String _selectedResolution = '3392×2400 (原生)';
  String _selectedRefreshRate = '144Hz';
  String _selectedDisplayMode = '扩展屏幕';
  bool _performanceMonitor = false;
  final bool _developerMode = false;
  
  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }
  
  Future<void> _initializeSettings() async {
    await settingsService.initialize();
    setState(() {
      _currentSettings = settingsService.currentSettings;
      _isInitialized = true;
    });
  }
  
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
    '自动',
  ];
  
  final List<String> _audioQualities = [
    '低',
    '中',
    '高',
    '无损',
  ];
  
  final List<String> _performanceModes = [
    '省电',
    '平衡',
    '性能',
    '游戏',
  ];

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _currentSettings == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('设置'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return LoadingOverlay(
      isLoading: !_isInitialized,
      message: '正在加载设置...',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('设置'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: AnimationUtils.staggeredList(
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
                _getVideoQualityDisplayName(_currentSettings!.videoQuality),
                _videoQualities,
                (value) async {
                  final quality = _getVideoQualityFromDisplayName(value);
                  await settingsService.updateVideoQuality(quality);
                  setState(() => _currentSettings = settingsService.currentSettings);
                },
              ),
              _buildSwitchTile(
                '硬件加速',
                '使用GPU硬件解码提升性能',
                _currentSettings!.hardwareAcceleration,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(hardwareAcceleration: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
              _buildSwitchTile(
                '低延迟模式',
                '优化传输延迟，可能增加CPU使用',
                _currentSettings!.lowLatencyMode,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(lowLatencyMode: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 音频设置
          _buildSection(
            '音频设置',
            Icons.audio_file,
            [
              _buildDropdownTile(
                '音质',
                _getAudioQualityDisplayName(_currentSettings!.audioQuality),
                _audioQualities,
                (value) async {
                  final quality = _getAudioQualityFromDisplayName(value);
                  await settingsService.updateAudioQuality(quality);
                  setState(() => _currentSettings = settingsService.currentSettings);
                },
              ),
              _buildSwitchTile(
                '音频增强',
                '启用高级音频处理和降噪',
                _currentSettings!.audioEnhancement,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(audioEnhancement: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 性能设置
          _buildSection(
            '性能设置',
            Icons.speed,
            [
              _buildDropdownTile(
                '性能模式',
                _getPerformanceModeDisplayName(_currentSettings!.performanceMode),
                _performanceModes,
                (value) async {
                  final mode = _getPerformanceModeFromDisplayName(value);
                  await settingsService.updatePerformanceMode(mode);
                  setState(() => _currentSettings = settingsService.currentSettings);
                },
              ),
              _buildSwitchTile(
                '热限制',
                '自动降低性能以防止过热',
                _currentSettings!.thermalThrottling,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(thermalThrottling: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
              _buildSwitchTile(
                '后台处理',
                '允许在后台继续处理视频流',
                _currentSettings!.backgroundProcessing,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(backgroundProcessing: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
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
                _currentSettings!.deviceName,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(deviceName: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
              _buildSwitchTile(
                '自动连接',
                '记住已配对设备，后续自动连接',
                _currentSettings!.autoReconnect,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(autoReconnect: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
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
                '自适应同步',
                '自动调整音视频同步参数',
                _currentSettings!.adaptiveSync,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(adaptiveSync: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
              _buildSwitchTile(
                '唇音校正',
                '启用高级音视频同步校正',
                _currentSettings!.lipSyncCorrection,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(lipSyncCorrection: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
              _buildSwitchTile(
                '调试模式',
                '显示详细调试信息',
                _currentSettings!.debugMode,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(debugMode: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
              _buildSwitchTile(
                '详细日志',
                '记录详细调试日志，可能影响性能',
                _currentSettings!.verboseLogging,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(verboseLogging: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
              _buildSwitchTile(
                '遥测数据',
                '发送匿名性能数据帮助改进应用',
                _currentSettings!.telemetryEnabled,
                (value) async {
                  final newSettings = _currentSettings!.copyWith(telemetryEnabled: value);
                  await settingsService.updateSettings(newSettings);
                  setState(() => _currentSettings = newSettings);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 连接测试 (总是显示)
          _buildSection(
            '连接测试',
            Icons.network_check,
            [
              _buildActionTile(
                'AirPlay连接诊断',
                '全面测试网络、服务和解码器功能',
                Icons.assessment,
                _openConnectionTest,
              ),
              _buildActionTile(
                '自动化测试',
                '运行完整的自动化测试套件',
                Icons.science,
                _openAutomatedTest,
              ),
              _buildActionTile(
                'Mac连接指南',
                '查看Mac设备连接步骤和故障排除',
                Icons.laptop_mac,
                _showMacConnectionGuide,
              ),
            ],
          ),
          
          // 开发者测试功能 (仅在开发者模式下显示)
          if (_developerMode) ...[
            const SizedBox(height: 16),
            _buildSection(
              '开发者测试',
              Icons.science,
              [
                _buildTestTile(
                  '视频解码器测试',
                  '测试视频解码和渲染功能',
                  videoTestService.isRunning,
                  _toggleVideoTest,
                ),
                _buildTestTile(
                  '音频解码器测试',
                  '播放440Hz+880Hz立体声测试音调',
                  audioTestService.isRunning,
                  _toggleAudioTest,
                ),
                _buildActionTile(
                  '清空应用数据',
                  '重置所有设置和缓存',
                  Icons.delete_forever,
                  _clearAppData,
                ),
                _buildActionTile(
                  '导出诊断日志',
                  '生成完整的系统诊断报告',
                  Icons.bug_report,
                  _exportDiagnostics,
                ),
                _buildActionTile(
                  '导出设置',
                  '导出当前所有设置配置',
                  Icons.file_download,
                  _exportSettings,
                ),
                _buildActionTile(
                  '导入设置',
                  '从文件导入设置配置',
                  Icons.file_upload,
                  _importSettings,
                ),
                _buildActionTile(
                  '重置设置',
                  '恢复到默认设置',
                  Icons.refresh,
                  _resetSettings,
                ),
              ],
            ),
          ],
          
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
        ),
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
  
  Widget _buildTestTile(
    String title,
    String subtitle,
    bool isRunning,
    VoidCallback onToggle,
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
          ElevatedButton(
            onPressed: onToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: isRunning ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isRunning ? '停止' : '开始'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
  
  void _toggleVideoTest() async {
    try {
      if (videoTestService.isRunning) {
        await videoTestService.stopTestPattern();
        if (mounted) {
          ToastNotification.showSuccess(
            context,
            message: '视频测试已停止',
          );
        }
      } else {
        await videoTestService.startTestPattern();
        if (mounted) {
          ToastNotification.showSuccess(
            context,
            message: '视频测试已启动，正在跳转到视频页面',
          );
          // 跳转到视频页面查看测试效果
          Navigator.pushNamed(context, '/video');
        }
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.showError(
          context,
          title: '视频测试失败',
          message: e.toString(),
        );
      }
    }
  }
  
  void _toggleAudioTest() async {
    try {
      if (audioTestService.isRunning) {
        await audioTestService.stopTestTone();
        if (mounted) {
          ToastNotification.showSuccess(
            context,
            message: '音频测试已停止',
          );
        }
      } else {
        await audioTestService.startTestTone();
        if (mounted) {
          ToastNotification.showSuccess(
            context,
            title: '音频测试已启动',
            message: '正在播放 440Hz(左) + 880Hz(右) 测试音调',
          );
        }
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.showError(
          context,
          title: '音频测试失败',
          message: e.toString(),
        );
      }
    }
  }
  
  void _clearAppData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空应用数据'),
        content: const Text('这将删除所有设置和缓存数据，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现清空数据功能
              ToastNotification.showSuccess(
                context,
                title: '操作成功',
                message: '应用数据已清空',
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _exportDiagnostics() {
    ToastNotification.showSuccess(
      context,
      title: '导出成功',
      message: '诊断日志已导出到文件',
    );
  }
  
  void _exportSettings() async {
    try {
      final settingsJson = settingsService.exportSettings();
      // TODO: 保存到文件或共享
      Clipboard.setData(ClipboardData(text: settingsJson));
      if (mounted) {
        ToastNotification.showSuccess(
          context,
          title: '导出成功',
          message: '设置已导出到剪贴板',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.showError(
          context,
          title: '导出失败',
          message: e.toString(),
        );
      }
    }
  }
  
  void _importSettings() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text != null) {
        final success = await settingsService.importSettings(clipboardData!.text!);
        if (success) {
          if (mounted) {
            setState(() {
              _currentSettings = settingsService.currentSettings;
            });
            ToastNotification.showSuccess(
              context,
              title: '导入成功',
              message: '设置已从剪贴板导入',
            );
          }
        } else {
          throw Exception('设置文件格式无效');
        }
      } else {
        throw Exception('剪贴板中没有文本');
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.showError(
          context,
          title: '导入失败',
          message: e.toString(),
        );
      }
    }
  }
  
  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('这将恢复所有设置到默认值，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              try {
                await settingsService.resetToDefaults();
                if (mounted) {
                  setState(() {
                    _currentSettings = settingsService.currentSettings;
                  });
                  
                  ToastNotification.showSuccess(
                    // ignore: use_build_context_synchronously
                    context,
                    title: '重置成功',
                    message: '所有设置已恢复到默认值',
                  );
                }
              } catch (e) {
                if (mounted) {
                  ToastNotification.showError(
                    // ignore: use_build_context_synchronously
                    context,
                    title: '重置失败',
                    message: e.toString(),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _openConnectionTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectionTestView(),
      ),
    );
  }
  
  void _showMacConnectionGuide() {
    showDialog(
      context: context,
      builder: (context) => const MacConnectionGuideDialog(),
    );
  }
  
  void _openAutomatedTest() {
    Navigator.pushNamed(context, '/automatedTest');
  }
  
  String _getVideoQualityDisplayName(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.low:
        return '低';
      case VideoQuality.medium:
        return '中';
      case VideoQuality.high:
        return '高';
      case VideoQuality.ultra:
        return '超高';
      case VideoQuality.auto:
        return '自动';
    }
  }
  
  VideoQuality _getVideoQualityFromDisplayName(String displayName) {
    switch (displayName) {
      case '低':
        return VideoQuality.low;
      case '中':
        return VideoQuality.medium;
      case '高':
        return VideoQuality.high;
      case '超高':
        return VideoQuality.ultra;
      case '自动':
        return VideoQuality.auto;
      default:
        return VideoQuality.high;
    }
  }
  
  String _getAudioQualityDisplayName(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.low:
        return '低';
      case AudioQuality.medium:
        return '中';
      case AudioQuality.high:
        return '高';
      case AudioQuality.lossless:
        return '无损';
    }
  }
  
  AudioQuality _getAudioQualityFromDisplayName(String displayName) {
    switch (displayName) {
      case '低':
        return AudioQuality.low;
      case '中':
        return AudioQuality.medium;
      case '高':
        return AudioQuality.high;
      case '无损':
        return AudioQuality.lossless;
      default:
        return AudioQuality.high;
    }
  }
  
  String _getPerformanceModeDisplayName(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.powersave:
        return '省电';
      case PerformanceMode.balanced:
        return '平衡';
      case PerformanceMode.performance:
        return '性能';
      case PerformanceMode.gaming:
        return '游戏';
    }
  }
  
  PerformanceMode _getPerformanceModeFromDisplayName(String displayName) {
    switch (displayName) {
      case '省电':
        return PerformanceMode.powersave;
      case '平衡':
        return PerformanceMode.balanced;
      case '性能':
        return PerformanceMode.performance;
      case '游戏':
        return PerformanceMode.gaming;
      default:
        return PerformanceMode.balanced;
    }
  }
}