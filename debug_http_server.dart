import 'dart:io';
import 'dart:convert';

void main() async {
  print('=== 启动AirPlay调试HTTP服务器 ===');
  print('监听端口: 7100');
  print('等待Mac连接请求...\n');

  final server = await HttpServer.bind('0.0.0.0', 7100);
  
  server.listen((HttpRequest request) {
    final timestamp = DateTime.now().toString();
    final method = request.method;
    final uri = request.uri.toString();
    final headers = request.headers.toString();
    
    print('[$timestamp] $method $uri');
    print('Headers: ${request.headers.value('user-agent') ?? 'Unknown'}');
    print('Content-Type: ${request.headers.contentType?.toString() ?? 'None'}');
    print('Content-Length: ${request.headers.contentLength ?? 0}');
    
    // 读取请求体
    request.listen(
      (List<int> data) {
        if (data.isNotEmpty) {
          try {
            String body = utf8.decode(data);
            print('Body: $body');
          } catch (e) {
            print('Binary Body: ${data.length} bytes');
          }
        }
      },
      onDone: () {
        // 根据不同的端点返回适当的响应
        if (uri.contains('/info')) {
          _handleInfo(request);
        } else if (uri.contains('/pair-setup')) {
          _handlePairSetup(request);
        } else if (uri.contains('/pair-verify')) {
          _handlePairVerify(request);
        } else if (uri.contains('/setup')) {
          _handleSetup(request);
        } else if (uri.contains('/fp-setup')) {
          _handleFpSetup(request);
        } else if (uri.contains('/reverse')) {
          _handleReverse(request);
        } else {
          _handleDefault(request, uri);
        }
        
        print('Response sent for $method $uri\n');
      },
      onError: (error) {
        print('Error reading request: $error');
      },
    );
  });

  print('HTTP服务器已启动在 http://0.0.0.0:7100');
  print('按 Ctrl+C 停止服务器');
}

void _handleInfo(HttpRequest request) {
  final response = {
    "name": "OPPO Pad - PadCast",
    "model": "OPPO,Pad4Pro", 
    "srcvers": "377.20.1",
    "pi": "198d46fa-1087-4000-8000-f6827dd",
    "vv": 2,
    "features": "0x5A7FFFF7,0x1E",
    "flags": "0x244",
    "statusflags": "0x44",
    "deviceid": "00:00:2d:d1:e1:f8",
    "displays": [{
      "uuid": "00000000-0000-0000-0000-000000000000",
      "width": 3392,
      "height": 2400,
      "refreshRate": 144.0,
      "maxFPS": 144,
    }],
    "protovers": "1.0",
    "pw": "0",
    "da": "true",
    "sv": "false",
    "pk": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
  };

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(response))
    ..close();
    
  print('→ Sent /info response');
}

void _handlePairSetup(HttpRequest request) {
  final response = {
    "status": 0,
    "sessionID": "12345678-1234-1234-1234-123456789ABC"
  };

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(response))
    ..close();
    
  print('→ Sent /pair-setup response');
}

void _handlePairVerify(HttpRequest request) {
  final response = {
    "status": 0,
    "sessionID": "12345678-1234-1234-1234-123456789ABC"
  };

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(response))
    ..close();
    
  print('→ Sent /pair-verify response');
}

void _handleSetup(HttpRequest request) {
  final response = {
    "status": 0,
    "sessionUUID": "12345678-1234-1234-1234-123456789ABC",
    "streams": [{
      "type": 110,
      "dataPort": 7101,
      "controlPort": 7101,
    }]
  };

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(response))
    ..close();
    
  print('→ Sent /setup response');
}

void _handleFpSetup(HttpRequest request) {
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType('application', 'octet-stream')
    ..add([0x00, 0x00, 0x00, 0x00])
    ..close();
    
  print('→ Sent /fp-setup response');
}

void _handleReverse(HttpRequest request) {
  request.response
    ..statusCode = 101  // Switching Protocols
    ..headers.add('Upgrade', 'PTTH/1.0')
    ..headers.add('Connection', 'Upgrade')
    ..close();
    
  print('→ Sent /reverse response');
}

void _handleDefault(HttpRequest request, String uri) {
  request.response
    ..statusCode = HttpStatus.notFound
    ..write('404 - Endpoint not found: $uri')
    ..close();
    
  print('→ Sent 404 for unknown endpoint: $uri');
}