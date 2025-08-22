import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/airplay_controller.dart';
import '../models/connection_state.dart'
    show ConnectionStatus, AirPlayConnectionState;
import '../constants/app_constants.dart';
import '../services/network_monitor_service.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/device_info_widget.dart';
import '../widgets/control_buttons_widget.dart';
import '../widgets/toast_notification.dart';
import '../utils/animation_utils.dart';
import 'settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  AirPlayConnectionState? _lastConnectionState;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
          BouncyButton(
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  PageTransitions.slideTransition(
                    page: const SettingsView(),
                    begin: const Offset(1.0, 0.0),
                  ),
                );
              },
            ),
          ),
          BouncyButton(
            child: IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/debug');
              },
              tooltip: '调试日志',
            ),
          ),
          BouncyButton(
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ToastNotification.showInfo(
                  context,
                  message: '通知功能开发中...',
                );
              },
            ),
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
                AnimationUtils.fadeSlideIn(
                  child:
                      ConnectionStatusWidget(connectionState: connectionState),
                ),

                const SizedBox(height: 48),

                // 设备信息卡片
                AnimationUtils.fadeSlideIn(
                  child: const DeviceInfoWidget(),
                ),

                const SizedBox(height: 32),

                // 等待连接状态图标
                if (!connectionState.isStreaming)
                  AnimationUtils.scaleIn(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: connectionState.status ==
                                  ConnectionStatus.discovering
                              ? _pulseAnimation.value
                              : 1.0,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(
                                  AppConstants.cardRadius),
                              border: Border.all(
                                color: _getStatusColor(connectionState.status)
                                    .withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: connectionState.status ==
                                      ConnectionStatus.discovering
                                  ? [
                                      BoxShadow(
                                        color: _getStatusColor(
                                                connectionState.status)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getStatusIcon(connectionState.status),
                                  size: 64,
                                  color:
                                      _getStatusColor(connectionState.status),
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
                        );
                      },
                    ),
                  ),

                // 流媒体显示区域（占位符）
                if (connectionState.isStreaming)
                  AnimationUtils.scaleIn(
                    curve: Curves.elasticOut,
                    child: Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius:
                            BorderRadius.circular(AppConstants.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimationUtils.rotate(
                              child: const Icon(
                                Icons.cast_connected,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimationUtils.fadeIn(
                              child: const Text(
                                '投屏内容显示区域',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // 控制按钮
                AnimationUtils.fadeSlideIn(
                  child: ControlButtonsWidget(
                    isServiceRunning: controller.isServiceRunning,
                    isServiceStarting: controller.airplayService.isStarting,
                    isServiceStopping: controller.airplayService.isStopping,
                    connectionState: connectionState,
                    onToggleService: () => controller.toggleService(),
                  ),
                ),

                const SizedBox(height: 16),

                // 连接测试快捷按钮
                AnimationUtils.fadeSlideIn(
                  child: SizedBox(
                    width: double.infinity,
                    child: BouncyButton(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/connectionTest');
                        },
                        icon: const Icon(Icons.network_check, size: 20),
                        label: const Text(
                          '连接诊断测试',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.buttonRadius),
                          ),
                          side: BorderSide(
                            color: Colors.blue[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 网络信息
                AnimationUtils.fadeSlideIn(
                  child: _buildNetworkInfoCard(
                      context, controller.networkInfo, connectionState),
                ),
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

  Widget _buildNetworkInfoCard(BuildContext context, AppNetworkInfo networkInfo,
      AirPlayConnectionState connectionState) {
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
            if (networkInfo.isConnected &&
                connectionState.status == ConnectionStatus.disconnected)
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
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
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
    final oldStatus = _lastConnectionState?.status;
    final newStatus = newState.status;

    // 显示状态变化的Toast通知
    if (oldStatus != newStatus) {
      switch (newStatus) {
        case ConnectionStatus.discovering:
          ToastNotification.showInfo(
            context,
            title: '服务已启动',
            message: '正在广播设备信息，等待Mac设备连接...',
          );
          break;
        case ConnectionStatus.connecting:
          ToastNotification.showInfo(
            context,
            title: '设备连接中',
            message: '正在与Mac设备建立连接...',
          );
          break;
        case ConnectionStatus.connected:
          ToastNotification.showSuccess(
            context,
            title: '连接成功',
            message: 'Mac设备已成功连接，等待投屏开始',
          );
          break;
        case ConnectionStatus.streaming:
          ToastNotification.showSuccess(
            context,
            title: '投屏已开始',
            message: '正在接收Mac设备的屏幕内容',
          );
          // 自动跳转到视频页面
          Navigator.pushNamed(context, '/video');
          break;
        case ConnectionStatus.error:
          ToastNotification.showError(
            context,
            title: '连接错误',
            message: '连接过程中出现问题，请检查网络设置',
          );
          break;
        case ConnectionStatus.disconnected:
          if (oldStatus == ConnectionStatus.streaming) {
            ToastNotification.showWarning(
              context,
              title: '投屏已结束',
              message: 'Mac设备已断开连接',
            );
          }
          break;
      }
    }

    _lastConnectionState = newState;
  }
}
