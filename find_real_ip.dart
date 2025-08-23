import 'dart:io';

void main() async {
  print('=== 查找真实的网络接口和IP地址 ===');
  
  // 1. 列出所有网络接口
  await listAllNetworkInterfaces();
  
  // 2. 测试每个IP地址的可达性
  await testConnectivity();
}

Future<void> listAllNetworkInterfaces() async {
  print('\n📡 所有网络接口详情:');
  
  try {
    final interfaces = await NetworkInterface.list(includeLoopback: true);
    for (final interface in interfaces) {
      print('\n接口名: ${interface.name}');
      print('  索引: ${interface.index}');
      
      for (final addr in interface.addresses) {
        String type = addr.type == InternetAddressType.IPv4 ? 'IPv4' : 'IPv6';
        String status = addr.isLoopback ? '回环' : '网络';
        print('  $type: ${addr.address} ($status)');
        
        // 如果是IPv4且非回环，测试AirPlay端口
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          await testAirPlayPort(addr.address);
        }
      }
    }
  } catch (e) {
    print('❌ 获取网络接口失败: $e');
  }
}

Future<void> testAirPlayPort(String ip) async {
  try {
    // 测试端口7100
    print('    测试AirPlay端口7100...');
    final socket = await Socket.connect(ip, 7100, timeout: const Duration(seconds: 1));
    print('    ✅ $ip:7100 可连接');
    socket.close();
  } catch (e) {
    print('    ❌ $ip:7100 无法连接');
  }
  
  try {
    // 测试HTTP GET请求
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 2);
    final request = await httpClient.get(ip, 7100, '/info');
    final response = await request.close();
    print('    ✅ $ip:7100/info HTTP响应: ${response.statusCode}');
    httpClient.close();
  } catch (e) {
    print('    ❌ $ip:7100/info HTTP请求失败');
  }
}

Future<void> testConnectivity() async {
  print('\n🌐 测试常见IP地址的连通性:');
  
  final testIPs = [
    '127.0.0.1',      // localhost
    '192.168.1.119',  // 之前检测到的IP
    '192.168.1.116',  // 之前测试的IP
    '10.0.0.1',       // 可能的内网IP
  ];
  
  for (final ip in testIPs) {
    print('\n测试 $ip:');
    
    try {
      // Ping测试
      final result = await Process.run('ping', ['-c', '1', '-W', '1000', ip]);
      if (result.exitCode == 0) {
        print('  ✅ Ping成功');
        
        // 尝试AirPlay连接
        try {
          final socket = await Socket.connect(ip, 7100, timeout: const Duration(seconds: 1));
          print('  ✅ AirPlay端口7100可连接');
          socket.close();
          
          // 尝试HTTP请求
          final httpClient = HttpClient();
          httpClient.connectionTimeout = const Duration(seconds: 2);
          final request = await httpClient.get(ip, 7100, '/info');
          final response = await request.close();
          if (response.statusCode == 200) {
            print('  ✅ HTTP /info 端点正常响应');
          }
          httpClient.close();
        } catch (e) {
          print('  ❌ AirPlay端口7100连接失败');
        }
      } else {
        print('  ❌ Ping失败');
      }
    } catch (e) {
      print('  ❌ 网络测试异常: $e');
    }
  }
}