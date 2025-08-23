import 'dart:io';
import 'dart:convert';

void main() async {
  print('=== 测试服务绑定和网络可访问性 ===');
  
  // 1. 测试不同的绑定地址
  await testBindingMethods();
  
  // 2. 测试端口监听状态
  await testPortListening();
  
  // 3. 提供Android设备诊断建议
  printAndroidDiagnostics();
}

Future<void> testBindingMethods() async {
  print('\n🔧 测试不同的HTTP服务绑定方法:');
  
  // 测试1: 绑定到所有接口 (0.0.0.0)
  await testBinding('所有接口 (0.0.0.0)', InternetAddress.anyIPv4, 7103);
  
  // 测试2: 绑定到localhost
  await testBinding('本地回环 (127.0.0.1)', InternetAddress.loopbackIPv4, 7104);
  
  // 测试3: 绑定到具体IP
  final interfaces = await NetworkInterface.list();
  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        await testBinding('具体IP (${addr.address})', addr, 7105);
        return; // 只测试第一个非回环IP
      }
    }
  }
}

Future<void> testBinding(String description, InternetAddress address, int port) async {
  try {
    print('测试绑定到 $description...');
    
    final server = await HttpServer.bind(address, port);
    print('✅ 成功绑定到 ${server.address.address}:${server.port}');
    
    // 设置简单的处理器
    server.listen((HttpRequest request) {
      print('📥 收到请求来自: ${request.connectionInfo?.remoteAddress}');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"test": "success", "binding": "$description"}')
        ..close();
    });
    
    // 测试自连接
    await Future.delayed(const Duration(milliseconds: 100));
    await testConnection(server.address.address, port, description);
    
    // 如果不是回环地址，也测试从其他地址的连接
    if (!address.isLoopback) {
      await testConnection('192.168.1.116', port, '$description (外部IP)');
    }
    
    await server.close();
    print('🛑 已关闭 $description 测试服务器\n');
    
  } catch (e) {
    print('❌ 绑定失败 $description: $e\n');
  }
}

Future<void> testConnection(String host, int port, String description) async {
  try {
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 3);
    
    final request = await httpClient.get(host, port, '/test');
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('✅ 连接成功 $description ($host:$port)');
    } else {
      print('❌ 连接失败 $description - 状态码: ${response.statusCode}');
    }
    
    httpClient.close();
  } catch (e) {
    print('❌ 连接异常 $description ($host:$port): $e');
  }
}

Future<void> testPortListening() async {
  print('\n🔍 检查端口7100监听状态:');
  
  try {
    // 尝试连接到7100端口，检查是否有服务在监听
    final socket = await Socket.connect('127.0.0.1', 7100, timeout: const Duration(seconds: 2));
    print('✅ 端口7100在localhost上有服务监听');
    socket.close();
  } catch (e) {
    print('❌ 端口7100在localhost上无服务监听: $e');
  }
  
  try {
    // 尝试连接到实际IP地址
    final socket = await Socket.connect('192.168.1.116', 7100, timeout: const Duration(seconds: 2));
    print('✅ 端口7100在网络IP上有服务监听');
    socket.close();
  } catch (e) {
    print('❌ 端口7100在网络IP上无服务监听: $e');
  }
}

void printAndroidDiagnostics() {
  print('\n🤖 Android设备诊断建议:');
  print('');
  print('如果服务能绑定到0.0.0.0但外部无法访问，可能原因:');
  print('1. Android网络安全策略阻止HTTP明文传输');
  print('   → 已添加network_security_config.xml');
  print('2. Android防火墙或SELinux政策阻止端口绑定');
  print('   → 需要root权限或厂商允许');
  print('3. OPPO设备特有的网络限制');
  print('   → 检查应用权限设置中的网络访问权限');
  print('4. WiFi网络隔离（AP隔离）');
  print('   → 确保路由器允许设备间通信');
  print('');
  print('🔧 建议的修复步骤:');
  print('1. 重新构建并安装APK (包含network_security_config.xml)');
  print('2. 在Android设置中检查应用的网络权限');
  print('3. 确保OPPO设备的"应用权限管理"允许网络访问');
  print('4. 测试在同一WiFi下的其他设备是否能相互访问');
}