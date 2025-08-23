import 'dart:io';

void main() async {
  print('=== HTTP服务绑定诊断 ===');
  
  // 1. 检查端口占用情况
  await checkPortUsage();
  
  // 2. 尝试创建测试服务器
  await createTestServer();
  
  // 3. 显示诊断建议
  showDiagnosticAdvice();
}

Future<void> checkPortUsage() async {
  print('\n🔍 检查端口7100占用情况:');
  
  try {
    // 尝试绑定到端口7100
    final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 7100);
    print('✅ 端口7100可以绑定 - 没有被占用');
    await serverSocket.close();
  } catch (e) {
    print('❌ 端口7100绑定失败: $e');
    if (e.toString().contains('Address already in use')) {
      print('   → 端口被其他进程占用');
    }
  }
  
  // 测试其他端口
  for (int port in [7101, 7102, 8080]) {
    try {
      final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      print('✅ 端口$port可用');
      await serverSocket.close();
    } catch (e) {
      print('❌ 端口$port不可用: ${e.toString().split(':').first}');
    }
  }
}

Future<void> createTestServer() async {
  print('\n🧪 创建测试HTTP服务器:');
  
  try {
    // 创建简单的HTTP服务器
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 7102);
    print('✅ 测试服务器启动在端口7102');
    
    server.listen((HttpRequest request) {
      print('📥 收到请求: ${request.method} ${request.uri}');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"status": "test server running"}')
        ..close();
    });
    
    // 等待几秒钟
    await Future.delayed(const Duration(seconds: 2));
    
    // 测试自连接
    print('🔌 测试自连接到7102...');
    final httpClient = HttpClient();
    try {
      final request = await httpClient.get('127.0.0.1', 7102, '/test');
      final response = await request.close();
      print('✅ 自连接成功，状态码: ${response.statusCode}');
    } catch (e) {
      print('❌ 自连接失败: $e');
    } finally {
      httpClient.close();
    }
    
    await server.close();
    print('🛑 测试服务器已停止');
    
  } catch (e) {
    print('❌ 创建测试服务器失败: $e');
  }
}

void showDiagnosticAdvice() {
  print('\n💡 诊断建议:');
  print('1. 如果端口7100被占用 → AirPlay服务启动可能失败但未正确报错');
  print('2. 如果测试服务器也无法自连接 → 可能是系统网络限制');
  print('3. 如果只有特定端口问题 → 尝试更换端口');
  print('4. Android设备可能需要特定的网络权限配置');
  
  print('\n🔧 建议的修复步骤:');
  print('1. 重启Android应用的AirPlay服务');
  print('2. 检查Android应用的网络权限');
  print('3. 尝试使用不同的端口号');
  print('4. 在Android设备上运行网络诊断');
}