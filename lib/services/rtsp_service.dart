import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../constants/app_constants.dart';
import 'video_decoder_service.dart';
import 'audio_decoder_service.dart';

class RtspService {
  ServerSocket? _serverSocket;
  Socket? _clientSocket;
  RawDatagramSocket? _rtpSocket;
  StreamSubscription? _clientSubscription;
  StreamSubscription? _rtpSubscription;
  VideoDecoderService? _videoDecoderService;
  AudioDecoderService? _audioDecoderService;
  
  final StreamController<RtspMessage> _messageController = 
      StreamController<RtspMessage>.broadcast();
  final StreamController<Uint8List> _videoStreamController = 
      StreamController<Uint8List>.broadcast();
  final StreamController<H264Frame> _h264FrameController = 
      StreamController<H264Frame>.broadcast();
      
  Stream<RtspMessage> get messageStream => _messageController.stream;
  Stream<Uint8List> get videoStream => _videoStreamController.stream;
  Stream<H264Frame> get h264FrameStream => _h264FrameController.stream;
  
  bool _isRunning = false;
  bool _isStreaming = false;
  bool get isRunning => _isRunning;
  bool get isStreaming => _isStreaming;
  
  // RTSP会话状态
  String? _sessionId;
  String? _clientIP;
  final int _rtpPort = 6000;
  
  // RTP状态
  final Map<int, List<int>> _rtpBuffer = {};
  final _h264Assembler = H264Assembler();
  
  void setVideoDecoderService(VideoDecoderService videoDecoderService) {
    _videoDecoderService = videoDecoderService;
  }
  
  void setAudioDecoderService(AudioDecoderService audioDecoderService) {
    _audioDecoderService = audioDecoderService;
  }
  
  Future<void> startRtspServer() async {
    if (_isRunning) return;
    
    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        AppConstants.rtspPort,
      );
      
      print('RTSP服务器启动在端口: ${AppConstants.rtspPort}');
      
      _serverSocket!.listen((Socket client) {
        _handleClientConnection(client);
      });
      
      // 启动RTP接收器
      await _startRtpReceiver();
      
      _isRunning = true;
    } catch (e) {
      print('启动RTSP服务器失败: $e');
      rethrow;
    }
  }
  
  Future<void> _startRtpReceiver() async {
    try {
      _rtpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _rtpPort);
      print('RTP接收器启动在端口: $_rtpPort');
      
      _rtpSubscription = _rtpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _rtpSocket!.receive();
          if (datagram != null) {
            _handleRtpPacket(datagram.data);
          }
        }
      });
    } catch (e) {
      print('启动RTP接收器失败: $e');
    }
  }
  
  Future<void> stopRtspServer() async {
    _clientSubscription?.cancel();
    _clientSocket?.close();
    _rtpSubscription?.cancel();
    _rtpSocket?.close();
    await _serverSocket?.close();
    
    _isRunning = false;
    _isStreaming = false;
    print('RTSP服务器已停止');
  }
  
  void _handleRtpPacket(Uint8List data) {
    if (data.length < 12) return; // RTP头部至少12字节
    
    try {
      // 解析RTP头部
      final rtpHeader = RtpHeader.fromBytes(data);
      final payload = data.sublist(12);
      
      // 处理RTP负载
      if (rtpHeader.payloadType == 96) { // H.264视频
        _processH264RtpPayload(rtpHeader, payload);
      } else if (rtpHeader.payloadType == 97) { // AAC音频
        _processAacRtpPayload(rtpHeader, payload);
      }
    } catch (e) {
      print('处理RTP数据包失败: $e');
    }
  }
  
  void _processH264RtpPayload(RtpHeader header, Uint8List payload) {
    if (payload.isEmpty) return;
    
    final nalUnitType = payload[0] & 0x1F;
    
    // 处理不同类型的RTP负载
    switch (nalUnitType) {
      case 1: case 5: // Single NAL unit packet
        _processSingleNalUnit(header, payload);
        break;
      case 24: // STAP-A (Single-time aggregation packet)
        _processStapA(header, payload);
        break;
      case 28: // FU-A (Fragmentation unit)
        _processFuA(header, payload);
        break;
      default:
        print('未知的NAL单元类型: $nalUnitType');
    }
  }
  
  void _processSingleNalUnit(RtpHeader header, Uint8List payload) {
    // 添加NAL单元开始码
    final nalUnit = Uint8List(4 + payload.length);
    nalUnit.setRange(0, 4, [0x00, 0x00, 0x00, 0x01]);
    nalUnit.setRange(4, nalUnit.length, payload);
    
    // 创建H.264帧
    final frame = H264Frame(
      data: nalUnit,
      timestamp: header.timestamp.toDouble(),
      sequenceNumber: header.sequenceNumber,
      isKeyFrame: (payload[0] & 0x1F) == 5, // IDR frame
    );
    
    _h264FrameController.add(frame);
    _sendToDecoder(frame);
  }
  
  void _processStapA(RtpHeader header, Uint8List payload) {
    int offset = 1; // 跳过STAP-A头部
    
    while (offset < payload.length) {
      if (offset + 2 > payload.length) break;
      
      // 读取NAL单元长度
      final nalLength = (payload[offset] << 8) | payload[offset + 1];
      offset += 2;
      
      if (offset + nalLength > payload.length) break;
      
      // 提取NAL单元
      final nalUnit = payload.sublist(offset, offset + nalLength);
      
      // 添加开始码并处理
      final fullNalUnit = Uint8List(4 + nalUnit.length);
      fullNalUnit.setRange(0, 4, [0x00, 0x00, 0x00, 0x01]);
      fullNalUnit.setRange(4, fullNalUnit.length, nalUnit);
      
      final frame = H264Frame(
        data: fullNalUnit,
        timestamp: header.timestamp.toDouble(),
        sequenceNumber: header.sequenceNumber,
        isKeyFrame: (nalUnit[0] & 0x1F) == 5,
      );
      
      _h264FrameController.add(frame);
      _sendToDecoder(frame);
      
      offset += nalLength;
    }
  }
  
  void _processFuA(RtpHeader header, Uint8List payload) {
    if (payload.length < 2) return;
    
    final fuIndicator = payload[0];
    final fuHeader = payload[1];
    final startBit = (fuHeader & 0x80) != 0;
    final endBit = (fuHeader & 0x40) != 0;
    final nalType = fuHeader & 0x1F;
    
    final sequenceNumber = header.sequenceNumber;
    
    if (startBit) {
      // 开始新的分片
      final nalHeader = (fuIndicator & 0xE0) | nalType;
      _h264Assembler.startFragment(sequenceNumber, [nalHeader]);
    }
    
    // 添加分片数据
    _h264Assembler.addFragment(sequenceNumber, payload.sublist(2));
    
    if (endBit) {
      // 完成分片组装
      final completeNalUnit = _h264Assembler.completeFragment(sequenceNumber);
      if (completeNalUnit != null) {
        // 添加开始码
        final fullNalUnit = Uint8List(4 + completeNalUnit.length);
        fullNalUnit.setRange(0, 4, [0x00, 0x00, 0x00, 0x01]);
        fullNalUnit.setRange(4, fullNalUnit.length, completeNalUnit);
        
        final frame = H264Frame(
          data: fullNalUnit,
          timestamp: header.timestamp.toDouble(),
          sequenceNumber: sequenceNumber,
          isKeyFrame: nalType == 5,
        );
        
        _h264FrameController.add(frame);
        _sendToDecoder(frame);
      }
    }
  }
  
  void _processAacRtpPayload(RtpHeader header, Uint8List payload) {
    if (payload.isEmpty) return;
    
    try {
      // AAC RTP负载通常直接包含AAC帧数据
      // AU-headers (Access Unit headers) 可能存在，但简化处理
      
      // 创建音频帧
      final audioFrame = AacFrame(
        data: payload,
        timestamp: header.timestamp.toDouble(),
        sequenceNumber: header.sequenceNumber,
      );
      
      _sendToAudioDecoder(audioFrame);
    } catch (e) {
      print('处理AAC RTP负载失败: $e');
    }
  }
  
  void _sendToDecoder(H264Frame frame) {
    if (_videoDecoderService != null && _videoDecoderService!.isDecoding) {
      _videoDecoderService!.decodeFrame(frame.data, frame.timestamp);
    }
  }
  
  void _sendToAudioDecoder(AacFrame frame) {
    if (_audioDecoderService != null && _audioDecoderService!.isDecoding) {
      _audioDecoderService!.decodeFrame(frame.data, frame.timestamp);
    }
  }
  
  void _handleClientConnection(Socket client) {
    _clientSocket = client;
    _clientIP = client.remoteAddress.address;
    
    print('RTSP客户端连接: $_clientIP:${client.remotePort}');
    
    _clientSubscription = client.listen(
      (Uint8List data) {
        _handleRtspData(data);
      },
      onError: (error) {
        print('RTSP连接错误: $error');
      },
      onDone: () {
        print('RTSP客户端断开连接');
        _clientSocket = null;
        _clientIP = null;
      },
    );
  }
  
  void _handleRtspData(Uint8List data) {
    try {
      final message = utf8.decode(data);
      final rtspMessage = _parseRtspMessage(message);
      
      if (rtspMessage != null) {
        _messageController.add(rtspMessage);
        _processRtspMessage(rtspMessage);
      }
    } catch (e) {
      print('解析RTSP数据失败: $e');
    }
  }
  
  RtspMessage? _parseRtspMessage(String message) {
    final lines = message.trim().split('\r\n');
    if (lines.isEmpty) return null;
    
    final requestLine = lines[0].split(' ');
    if (requestLine.length < 3) return null;
    
    final method = requestLine[0];
    final uri = requestLine[1];
    final version = requestLine[2];
    
    final headers = <String, String>{};
    String? body;
    
    int bodyStartIndex = -1;
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        bodyStartIndex = i + 1;
        break;
      }
      
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final key = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        headers[key] = value;
      }
    }
    
    if (bodyStartIndex >= 0 && bodyStartIndex < lines.length) {
      body = lines.sublist(bodyStartIndex).join('\r\n');
    }
    
    return RtspMessage(
      method: method,
      uri: uri,
      version: version,
      headers: headers,
      body: body,
    );
  }
  
  void _processRtspMessage(RtspMessage message) {
    switch (message.method) {
      case 'OPTIONS':
        _handleOptions(message);
        break;
      case 'DESCRIBE':
        _handleDescribe(message);
        break;
      case 'SETUP':
        _handleSetup(message);
        break;
      case 'PLAY':
        _handlePlay(message);
        break;
      case 'TEARDOWN':
        _handleTeardown(message);
        break;
      default:
        _sendErrorResponse(message, 501, 'Not Implemented');
    }
  }
  
  void _handleOptions(RtspMessage message) {
    final response = _buildRtspResponse(
      message,
      200,
      'OK',
      {
        'Public': 'OPTIONS, DESCRIBE, SETUP, PLAY, TEARDOWN',
        'Content-Length': '0',
      },
    );
    
    _sendResponse(response);
  }
  
  void _handleDescribe(RtspMessage message) {
    final sdp = _generateSDP();
    
    final response = _buildRtspResponse(
      message,
      200,
      'OK',
      {
        'Content-Type': 'application/sdp',
        'Content-Length': '${utf8.encode(sdp).length}',
      },
      sdp,
    );
    
    _sendResponse(response);
  }
  
  void _handleSetup(RtspMessage message) {
    _sessionId = 'PADCAST_${DateTime.now().millisecondsSinceEpoch}';
    
    final transport = message.headers['Transport'] ?? '';
    final response = _buildRtspResponse(
      message,
      200,
      'OK',
      {
        'Transport': '$transport;server_port=6000-6001',
        'Session': _sessionId!,
        'Content-Length': '0',
      },
    );
    
    _sendResponse(response);
  }
  
  void _handlePlay(RtspMessage message) {
    final response = _buildRtspResponse(
      message,
      200,
      'OK',
      {
        'Session': _sessionId ?? '',
        'Range': 'npt=0.000-',
        'Content-Length': '0',
      },
    );
    
    _sendResponse(response);
    
    // 启动视频流接收和解码
    _startVideoStreaming();
  }
  
  void _handleTeardown(RtspMessage message) {
    final response = _buildRtspResponse(
      message,
      200,
      'OK',
      {
        'Session': _sessionId ?? '',
        'Content-Length': '0',
      },
    );
    
    _sendResponse(response);
    
    // 停止视频流接收和解码
    _stopVideoStreaming();
  }
  
  void _sendErrorResponse(RtspMessage message, int statusCode, String statusText) {
    final response = _buildRtspResponse(
      message,
      statusCode,
      statusText,
      {'Content-Length': '0'},
    );
    
    _sendResponse(response);
  }
  
  String _buildRtspResponse(
    RtspMessage request,
    int statusCode,
    String statusText,
    Map<String, String> headers, [
    String? body,
  ]) {
    final cseq = request.headers['CSeq'] ?? '1';
    
    final responseHeaders = {
      'CSeq': cseq,
      'Server': 'PadCast RTSP Server 1.0',
      ...headers,
    };
    
    final lines = <String>[
      'RTSP/1.0 $statusCode $statusText',
    ];
    
    responseHeaders.forEach((key, value) {
      lines.add('$key: $value');
    });
    
    lines.add(''); // 空行分隔
    
    if (body != null) {
      lines.add(body);
    }
    
    return lines.join('\r\n');
  }
  
  void _sendResponse(String response) {
    if (_clientSocket != null) {
      _clientSocket!.write(response);
      print('RTSP响应发送: ${response.split('\r\n')[0]}');
    }
  }
  
  String _generateSDP() {
    // 生成SDP (Session Description Protocol) 描述
    return '''v=0
o=PadCast 0 0 IN IP4 ${_getLocalIP()}
s=PadCast AirPlay Stream
c=IN IP4 ${_getLocalIP()}
t=0 0
m=video 0 RTP/AVP 96
a=rtpmap:96 H264/90000
a=fmtp:96 packetization-mode=1;profile-level-id=42e01e
a=control:trackID=1
m=audio 0 RTP/AVP 97
a=rtpmap:97 MPEG4-GENERIC/44100/2
a=fmtp:97 streamtype=5;profile-level-id=2;mode=AAC-hbr;config=1210;SizeLength=13;IndexLength=3;IndexDeltaLength=3
a=control:trackID=2''';
  }
  
  void _startVideoStreaming() async {
    if (_isStreaming) return;
    
    try {
      // 启动视频解码器
      if (_videoDecoderService != null) {
        if (!_videoDecoderService!.isInitialized) {
          await _videoDecoderService!.initialize();
        }
        if (!_videoDecoderService!.isDecoding) {
          await _videoDecoderService!.startDecoding();
        }
      }
      
      // 启动音频解码器
      if (_audioDecoderService != null) {
        if (!_audioDecoderService!.isInitialized) {
          await _audioDecoderService!.initialize();
        }
        if (!_audioDecoderService!.isDecoding) {
          await _audioDecoderService!.startDecoding();
        }
      }
      
      _isStreaming = true;
      print('音视频流接收已启动');
    } catch (e) {
      print('启动音视频流接收失败: $e');
    }
  }
  
  void _stopVideoStreaming() async {
    if (!_isStreaming) return;
    
    try {
      // 停止视频解码器
      if (_videoDecoderService != null && _videoDecoderService!.isDecoding) {
        await _videoDecoderService!.stopDecoding();
      }
      
      // 停止音频解码器
      if (_audioDecoderService != null && _audioDecoderService!.isDecoding) {
        await _audioDecoderService!.stopDecoding();
      }
      
      // 清理RTP缓冲区
      _rtpBuffer.clear();
      _h264Assembler.reset();
      
      _isStreaming = false;
      print('音视频流接收已停止');
    } catch (e) {
      print('停止音视频流接收失败: $e');
    }
  }
  
  String _getLocalIP() {
    // 简化实现，实际应该获取真实IP
    return '192.168.1.100';
  }
  
  void dispose() {
    stopRtspServer();
    _messageController.close();
    _videoStreamController.close();
    _h264FrameController.close();
  }
}

class RtspMessage {
  final String method;
  final String uri;
  final String version;
  final Map<String, String> headers;
  final String? body;
  
  const RtspMessage({
    required this.method,
    required this.uri,
    required this.version,
    required this.headers,
    this.body,
  });
  
  @override
  String toString() {
    return 'RtspMessage{method: $method, uri: $uri, headers: $headers}';
  }
}

class RtpHeader {
  final int version;
  final bool padding;
  final bool extension;
  final int csrcCount;
  final bool marker;
  final int payloadType;
  final int sequenceNumber;
  final int timestamp;
  final int ssrc;
  
  const RtpHeader({
    required this.version,
    required this.padding,
    required this.extension,
    required this.csrcCount,
    required this.marker,
    required this.payloadType,
    required this.sequenceNumber,
    required this.timestamp,
    required this.ssrc,
  });
  
  static RtpHeader fromBytes(Uint8List data) {
    if (data.length < 12) {
      throw ArgumentError('RTP header too short');
    }
    
    final byte0 = data[0];
    final byte1 = data[1];
    
    return RtpHeader(
      version: (byte0 >> 6) & 0x3,
      padding: (byte0 & 0x20) != 0,
      extension: (byte0 & 0x10) != 0,
      csrcCount: byte0 & 0xF,
      marker: (byte1 & 0x80) != 0,
      payloadType: byte1 & 0x7F,
      sequenceNumber: (data[2] << 8) | data[3],
      timestamp: (data[4] << 24) | (data[5] << 16) | (data[6] << 8) | data[7],
      ssrc: (data[8] << 24) | (data[9] << 16) | (data[10] << 8) | data[11],
    );
  }
}

class H264Frame {
  final Uint8List data;
  final double timestamp;
  final int sequenceNumber;
  final bool isKeyFrame;
  
  const H264Frame({
    required this.data,
    required this.timestamp,
    required this.sequenceNumber,
    required this.isKeyFrame,
  });
}

class H264Assembler {
  final Map<int, List<int>> _fragments = {};
  
  void startFragment(int sequenceNumber, List<int> nalHeader) {
    _fragments[sequenceNumber] = List<int>.from(nalHeader);
  }
  
  void addFragment(int sequenceNumber, List<int> data) {
    _fragments[sequenceNumber]?.addAll(data);
  }
  
  Uint8List? completeFragment(int sequenceNumber) {
    final fragmentData = _fragments.remove(sequenceNumber);
    if (fragmentData != null) {
      return Uint8List.fromList(fragmentData);
    }
    return null;
  }
  
  void reset() {
    _fragments.clear();
  }
}

class AacFrame {
  final Uint8List data;
  final double timestamp;
  final int sequenceNumber;
  
  const AacFrame({
    required this.data,
    required this.timestamp,
    required this.sequenceNumber,
  });
}