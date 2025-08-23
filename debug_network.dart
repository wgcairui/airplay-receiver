import 'dart:io';

void main() async {
  print('=== 网络调试信息 ===');
  
  // 1. 显示所有网络接口
  await showNetworkInterfaces();
  
  // 2. 尝试连接到自己的服务
  await testSelfConnection();
  
  // 3. 显示Mac应该使用的连接信息
  showConnectionInfo();
}

Future<void> showNetworkInterfaces() async {
  print('\n📡 当前网络接口:');
  try {
    final interfaces = await NetworkInterface.list();
    for (final interface in interfaces) {
      print('接口: ${interface.name}');
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          print('  IPv4: ${addr.address} (${addr.isLoopback ? "本地回环" : "网络接口"})');
        }
      }
    }
  } catch (e) {
    print('❌ 获取网络接口失败: $e');
  }
}

Future<void> testSelfConnection() async {
  print('\n🔌 测试自连接:');
  
  // 获取本地IP
  final interfaces = await NetworkInterface.list();
  String? localIP;
  
  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        localIP = addr.address;
        break;
      }
    }
    if (localIP != null) break;
  }
  
  if (localIP != null) {
    print('尝试连接到: http://$localIP:7100/info');
    
    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 3);
      
      final request = await httpClient.get(localIP, 7100, '/info');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        print('✅ 自连接成功 - HTTP服务正常运行');
      } else {
        print('❌ 自连接失败 - 状态码: ${response.statusCode}');
      }
      
      httpClient.close();
    } catch (e) {
      print('❌ 自连接异常: $e');
    }
  } else {
    print('❌ 无法找到本地IP地址');
  }
}

void showConnectionInfo() {
  print('\n📋 Mac连接信息:');
  print('如果Mac无法连接，请尝试:');
  print('1. 确保Mac和Android在同一WiFi网络');
  print('2. 在Mac上运行: ping [Android设备IP]');
  print('3. 在Mac浏览器访问: http://[Android设备IP]:7100/info');
  print('4. 检查Mac的防火墙设置');
  print('5. 重启Mac的网络服务:');
  print('   sudo ifconfig en0 down && sudo ifconfig en0 up');
}