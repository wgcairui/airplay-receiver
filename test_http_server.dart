import 'dart:io';
import 'dart:convert';

void main() async {
  print('测试本地AirPlay HTTP服务...');
  
  // 测试端口7000的HTTP服务
  await testHttpService();
  
  // 测试端口7001的RTSP服务
  await testRtspService();
}

Future<void> testHttpService() async {
  try {
    print('\n=== 测试HTTP服务 (端口7000) ===');
    
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 5);
    
    // 测试/info端点
    print('测试 GET /info...');
    final request = await httpClient.get('127.0.0.1', 7000, '/info');
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      print('✅ HTTP服务正常响应');
      print('Status: ${response.statusCode}');
      print('Response: ${body.substring(0, 200)}...');
    } else {
      print('❌ HTTP服务响应异常: ${response.statusCode}');
    }
    
    httpClient.close();
  } catch (e) {
    print('❌ HTTP服务连接失败: $e');
    print('可能的原因:');
    print('1. AirPlay服务未启动');
    print('2. 端口7000被其他程序占用');
    print('3. 防火墙阻止连接');
  }
}

Future<void> testRtspService() async {
  try {
    print('\n=== 测试RTSP服务 (端口7001) ===');
    
    final socket = await Socket.connect('127.0.0.1', 7001,
        timeout: const Duration(seconds: 5));
    
    print('✅ RTSP端口可连接');
    
    // 发送简单的RTSP OPTIONS请求
    socket.write('OPTIONS * RTSP/1.0\r\nCSeq: 1\r\n\r\n');
    
    // 等待响应
    final response = await socket.timeout(const Duration(seconds: 3)).take(1).join();
    
    if (response.isNotEmpty) {
      print('✅ RTSP服务有响应');
      print('Response: $response');
    } else {
      print('⚠️  RTSP服务无响应');
    }
    
    socket.destroy();
  } catch (e) {
    print('❌ RTSP服务连接失败: $e');
    print('可能的原因:');
    print('1. AirPlay服务未启动');
    print('2. 端口7001被其他程序占用');
    print('3. RTSP服务初始化失败');
  }
}