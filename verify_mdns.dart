import 'dart:io';
import 'dart:convert';

void main() async {
  print('验证mDNS广播和AirPlay服务...');
  
  // 1. 验证HTTP服务是否在正确端口运行
  await verifyHttpService();
  
  // 2. 提供Mac端验证命令
  printMacVerificationCommands();
}

Future<void> verifyHttpService() async {
  try {
    print('\n=== 验证AirPlay HTTP服务 ===');
    
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 5);
    
    // 测试/info端点 - 这是Mac AirPlay发现时会调用的端点
    print('测试 GET http://192.168.1.116:7100/info...');
    final request = await httpClient.get('192.168.1.116', 7100, '/info');
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      
      print('✅ AirPlay HTTP服务正常响应');
      print('设备名称: ${data['name']}');
      print('设备模型: ${data['model']}');
      print('协议版本: ${data['srcvers']}');
      print('功能标志: ${data['features']}');
      print('设备ID: ${data['deviceid']}');
      
      // 检查关键字段
      bool hasRequiredFields = data.containsKey('name') && 
                              data.containsKey('model') && 
                              data.containsKey('features') && 
                              data.containsKey('deviceid');
      
      if (hasRequiredFields) {
        print('✅ 所有必需的AirPlay字段都存在');
      } else {
        print('❌ 缺少必需的AirPlay字段');
      }
      
    } else {
      print('❌ HTTP服务响应异常: ${response.statusCode}');
    }
    
    httpClient.close();
  } catch (e) {
    print('❌ HTTP服务验证失败: $e');
    print('请确保AirPlay服务正在运行');
  }
}

void printMacVerificationCommands() {
  print('\n=== Mac端验证命令 ===');
  print('在Mac终端运行以下命令来验证mDNS广播:');
  print('');
  print('1. 清理mDNS缓存:');
  print('   sudo dscacheutil -flushcache');
  print('   sudo killall -HUP mDNSResponder');
  print('');
  print('2. 查找AirPlay服务:');
  print('   dns-sd -B _airplay._tcp local.');
  print('   # 应该看到: OPPO-Pad---PadCast._airplay._tcp.local');
  print('');
  print('3. 查看服务详情:');
  print('   dns-sd -L "OPPO-Pad---PadCast" _airplay._tcp local.');
  print('   # 应该看到端口7100');
  print('');
  print('4. 测试HTTP连接:');
  print('   curl http://192.168.1.116:7100/info');
  print('   # 应该返回JSON设备信息');
  print('');
  print('5. 重启AirPlay相关服务:');
  print('   sudo launchctl stop com.apple.airportd');
  print('   sudo launchctl start com.apple.airportd');
  print('');
  print('如果以上命令都正常，但Mac仍无法连接，可能是:');
  print('- Mac的AirPlay缓存问题');
  print('- 防火墙阻止连接');
  print('- AirPlay协议兼容性问题');
}