import 'dart:async';
import 'dart:developer' as developer;

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String module;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.module,
    required this.message,
    this.error,
    this.stackTrace,
  });
  
  @override
  String toString() {
    final timeStr = timestamp.toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final moduleStr = module.padRight(15);
    
    var logMessage = '[$timeStr] $levelStr [$moduleStr] $message';
    
    if (error != null) {
      logMessage += '\n  Error: $error';
    }
    
    if (stackTrace != null) {
      logMessage += '\n  Stack: ${stackTrace.toString()}';
    }
    
    return logMessage;
  }
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();
  
  final StreamController<LogEntry> _logController = 
      StreamController<LogEntry>.broadcast();
  
  Stream<LogEntry> get logStream => _logController.stream;
  
  final List<LogEntry> _logs = [];
  static const int _maxLogs = 1000;
  
  List<LogEntry> get logs => List.unmodifiable(_logs);
  
  void debug(String module, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, module, message, error, stackTrace);
  }
  
  void info(String module, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, module, message, error, stackTrace);
  }
  
  void warning(String module, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, module, message, error, stackTrace);
  }
  
  void error(String module, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, module, message, error, stackTrace);
  }
  
  void _log(LogLevel level, String module, String message, Object? error, StackTrace? stackTrace) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      module: module,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    
    // 添加到内存日志
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    
    // 发送到流
    if (!_logController.isClosed) {
      _logController.add(entry);
    }
    
    // 输出到控制台
    print(entry.toString());
    
    // 使用开发者工具日志
    developer.log(
      message,
      name: module,
      level: _getDeveloperLogLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  int _getDeveloperLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 300;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
  
  void clearLogs() {
    _logs.clear();
  }
  
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }
  
  List<LogEntry> getLogsByModule(String module) {
    return _logs.where((log) => log.module == module).toList();
  }
  
  void dispose() {
    _logController.close();
  }
}

// 便捷的全局日志函数
class Log {
  static final LoggerService _logger = LoggerService();
  
  static void d(String module, String message, [Object? error, StackTrace? stackTrace]) {
    _logger.debug(module, message, error, stackTrace);
  }
  
  static void i(String module, String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(module, message, error, stackTrace);
  }
  
  static void w(String module, String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(module, message, error, stackTrace);
  }
  
  static void e(String module, String message, [Object? error, StackTrace? stackTrace]) {
    _logger.error(module, message, error, stackTrace);
  }
}