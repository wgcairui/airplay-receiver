import 'dart:io';
import 'dart:convert';

void main() async {
  print('测试本地HTTP服务...');
  
  // 测试127.0.0.1 (localhost)
  await testLocalhost();
  
  // 测试实际IP地址
  await testActualIP();
}

Future<void> testLocalhost() async {
  try {
    print('\n=== 测试 localhost:7100 ===');
    
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 5);
    
    final request = await httpClient.get('127.0.0.1', 7100, '/info');
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      print('✅ localhost HTTP服务正常');
      print('响应长度: ${body.length} 字符');
    } else {
      print('❌ localhost HTTP服务响应异常: ${response.statusCode}');
    }
    
    httpClient.close();
  } catch (e) {
    print('❌ localhost HTTP服务连接失败: $e');
  }
}

Future<void> testActualIP() async {
  try {
    print('\n=== 测试 192.168.1.116:7100 ===');
    
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 5);
    
    final request = await httpClient.get('192.168.1.116', 7100, '/info');
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      print('✅ 实际IP HTTP服务正常');
      print('响应长度: ${body.length} 字符');
    } else {
      print('❌ 实际IP HTTP服务响应异常: ${response.statusCode}');
    }
    
    httpClient.close();
  } catch (e) {
    print('❌ 实际IP HTTP服务连接失败: $e');
    print('这可能说明服务只绑定到了localhost');
    
    // 检查网络接口
    await checkNetworkInterfaces();
  }
}

Future<void> checkNetworkInterfaces() async {
  print('\n=== 检查网络接口 ===');
  try {
    final interfaces = await NetworkInterface.list();
    for (final interface in interfaces) {
      print('接口: ${interface.name}');
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          print('  IPv4: ${addr.address}');
        }
      }
    }
  } catch (e) {
    print('检查网络接口失败: $e');
  }
}