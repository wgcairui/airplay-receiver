enum ConnectionStatus {
  disconnected,
  discovering,
  connecting,
  connected,
  streaming,
  error
}

class AirPlayConnectionState {
  final ConnectionStatus status;
  final String? connectedDeviceName;
  final String? connectedDeviceIP;
  final String? errorMessage;
  final int? currentFPS;
  final int? latencyMs;
  final String? resolution;
  
  const AirPlayConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.connectedDeviceName,
    this.connectedDeviceIP,
    this.errorMessage,
    this.currentFPS,
    this.latencyMs,
    this.resolution,
  });
  
  AirPlayConnectionState copyWith({
    ConnectionStatus? status,
    String? connectedDeviceName,
    String? connectedDeviceIP,
    String? errorMessage,
    int? currentFPS,
    int? latencyMs,
    String? resolution,
  }) {
    return AirPlayConnectionState(
      status: status ?? this.status,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      connectedDeviceIP: connectedDeviceIP ?? this.connectedDeviceIP,
      errorMessage: errorMessage ?? this.errorMessage,
      currentFPS: currentFPS ?? this.currentFPS,
      latencyMs: latencyMs ?? this.latencyMs,
      resolution: resolution ?? this.resolution,
    );
  }
  
  bool get isConnected => status == ConnectionStatus.connected || status == ConnectionStatus.streaming;
  bool get isStreaming => status == ConnectionStatus.streaming;
  bool get hasError => status == ConnectionStatus.error;
  
  String get statusText {
    switch (status) {
      case ConnectionStatus.disconnected:
        return '等待连接...';
      case ConnectionStatus.discovering:
        return '正在发现设备...';
      case ConnectionStatus.connecting:
        return '正在连接...';
      case ConnectionStatus.connected:
        return '已连接';
      case ConnectionStatus.streaming:
        return '投屏中';
      case ConnectionStatus.error:
        return '连接错误';
    }
  }
}