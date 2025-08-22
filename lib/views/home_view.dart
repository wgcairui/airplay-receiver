import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/airplay_controller.dart';
import '../models/connection_state.dart' show ConnectionStatus, AirPlayConnectionState;
import '../constants/app_constants.dart';
import '../services/network_monitor_service.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/device_info_widget.dart';
import '../widgets/control_buttons_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  AirPlayConnectionState? _lastConnectionState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'PadCast',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/debug');
            },
            tooltip: '调试日志',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 实现通知页面
            },
          ),
        ],
      ),
      body: Consumer<AirPlayController>(
        builder: (context, controller, child) {
          final connectionState = controller.connectionState;
          
          // 检测状态变化，自动跳转到视频页面
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleConnectionStateChange(connectionState);
          });
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                
                // 连接状态显示
                ConnectionStatusWidget(connectionState: connectionState),
                
                const SizedBox(height: 48),
                
                // 设备信息卡片
                const DeviceInfoWidget(),
                
                const SizedBox(height: 32),
                
                // 等待连接状态图标
                if (!connectionState.isStreaming)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                      border: Border.all(
                        color: _getStatusColor(connectionState.status).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getStatusIcon(connectionState.status),
                          size: 64,
                          color: _getStatusColor(connectionState.status),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getStatusDescription(connectionState.status),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // 流媒体显示区域（占位符）
                if (connectionState.isStreaming)
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cast_connected,
                            size: 64,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '投屏内容显示区域',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // 控制按钮
                ControlButtonsWidget(
                  isServiceRunning: controller.isServiceRunning,
                  connectionState: connectionState,
                  onToggleService: () => controller.toggleService(),
                ),
                
                const SizedBox(height: 24),
                
                // 网络信息
                _buildNetworkInfoCard(context, controller.networkInfo, connectionState),
              ],
            ),
          );
        },
      ),
    );
  }
  
  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Icons.cast;
      case ConnectionStatus.discovering:
        return Icons.search;
      case ConnectionStatus.connecting:
        return Icons.cast_connected;
      case ConnectionStatus.connected:
        return Icons.cast_connected;
      case ConnectionStatus.streaming:
        return Icons.cast_connected;
      case ConnectionStatus.error:
        return Icons.error_outline;
    }
  }
  
  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.discovering:
        return Colors.blue;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.streaming:
        return Colors.green;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }
  
  String _getStatusDescription(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return '等待Mac设备连接\n在Mac上选择AirPlay到OPPO Pad';
      case ConnectionStatus.discovering:
        return '正在广播设备信息\n请稍候...';
      case ConnectionStatus.connecting:
        return '正在建立连接\n请稍候...';
      case ConnectionStatus.connected:
        return '设备已连接\n准备接收投屏';
      case ConnectionStatus.streaming:
        return ''; // 不显示，因为会显示视频流
      case ConnectionStatus.error:
        return '连接出现问题\n请检查网络设置';
    }
  }
  
  Widget _buildNetworkInfoCard(
    BuildContext context, 
    AppNetworkInfo networkInfo, 
    AirPlayConnectionState connectionState
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // WiFi连接状态
            Row(
              children: [
                Icon(
                  _getNetworkIcon(networkInfo.type),
                  color: networkInfo.isConnected 
                      ? Colors.green[600] 
                      : Colors.red[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNetworkDisplayName(networkInfo),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (networkInfo.ipAddress != null)
                        Text(
                          'IP: ${networkInfo.ipAddress}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // AirPlay服务状态
            Row(
              children: [
                Icon(
                  Icons.cast_connected,
                  color: _getStatusColor(connectionState.status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AirPlay服务: ${connectionState.statusText}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(connectionState.status),
                        ),
                      ),
                      if (connectionState.connectedDeviceIP != null)
                        Text(
                          '连接设备: ${connectionState.connectedDeviceIP}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // 连接提示
            if (networkInfo.isConnected && connectionState.status == ConnectionStatus.disconnected)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, 
                         color: Colors.blue[600], 
                         size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '在Mac上选择"屏幕镜像"，找到并连接OPPO Pad',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  IconData _getNetworkIcon(NetworkType type) {
    switch (type) {
      case NetworkType.wifi:
        return Icons.wifi;
      case NetworkType.ethernet:
        return Icons.settings_ethernet;
      case NetworkType.mobile:
        return Icons.signal_cellular_4_bar;
      case NetworkType.none:
        return Icons.wifi_off;
    }
  }
  
  String _getNetworkDisplayName(AppNetworkInfo networkInfo) {
    if (!networkInfo.isConnected) {
      return '网络未连接';
    }
    
    switch (networkInfo.type) {
      case NetworkType.wifi:
        return networkInfo.ssid ?? 'WiFi已连接';
      case NetworkType.ethernet:
        return '以太网已连接';
      case NetworkType.mobile:
        return '移动网络已连接';
      case NetworkType.none:
        return '网络未连接';
    }
  }
  
  void _handleConnectionStateChange(AirPlayConnectionState newState) {
    // 如果状态从非streaming变为streaming，自动跳转到视频页面
    if (_lastConnectionState?.status != ConnectionStatus.streaming &&
        newState.status == ConnectionStatus.streaming) {
      Navigator.pushNamed(context, '/video');
    }
    
    _lastConnectionState = newState;
  }
}