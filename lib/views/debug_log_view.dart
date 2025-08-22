import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/logger_service.dart';
import '../constants/app_constants.dart';

class DebugLogView extends StatefulWidget {
  const DebugLogView({super.key});

  @override
  State<DebugLogView> createState() => _DebugLogViewState();
}

class _DebugLogViewState extends State<DebugLogView> {
  final LoggerService _logger = LoggerService();
  final ScrollController _scrollController = ScrollController();
  LogLevel? _filterLevel;
  String? _filterModule;
  bool _autoScroll = true;
  
  final Set<String> _modules = <String>{};

  @override
  void initState() {
    super.initState();
    _updateModules();
    
    // 监听新日志
    _logger.logStream.listen((_) {
      _updateModules();
      if (_autoScroll && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }
      setState(() {});
    });
  }

  void _updateModules() {
    _modules.clear();
    _modules.addAll(_logger.logs.map((log) => log.module).toSet());
  }

  List<LogEntry> get _filteredLogs {
    var logs = _logger.logs;
    
    if (_filterLevel != null) {
      logs = logs.where((log) => log.level == _filterLevel).toList();
    }
    
    if (_filterModule != null) {
      logs = logs.where((log) => log.module == _filterModule).toList();
    }
    
    return logs;
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试日志'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // 自动滚动开关
          IconButton(
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll ? '关闭自动滚动' : '开启自动滚动',
          ),
          // 清空日志
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              _logger.clearLogs();
              setState(() {});
            },
            tooltip: '清空日志',
          ),
          // 导出日志
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportLogs,
            tooltip: '导出日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 过滤器区域
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                // 日志级别过滤
                Expanded(
                  child: DropdownButtonFormField<LogLevel?>(
                    value: _filterLevel,
                    decoration: const InputDecoration(
                      labelText: '日志级别',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<LogLevel?>(
                        value: null,
                        child: Text('全部'),
                      ),
                      ...LogLevel.values.map((level) => DropdownMenuItem(
                        value: level,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getLevelColor(level),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(level.name.toUpperCase()),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterLevel = value;
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 模块过滤
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _filterModule,
                    decoration: const InputDecoration(
                      labelText: '模块',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部'),
                      ),
                      ..._modules.map((module) => DropdownMenuItem(
                        value: module,
                        child: Text(module),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterModule = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // 日志列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return _buildLogItem(log);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(LogEntry log) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getLevelColor(log.level).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getLevelColor(log.level).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getLevelColor(log.level),
            shape: BoxShape.circle,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getLevelColor(log.level),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.level.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.module,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(log.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Text(
          log.message,
          style: const TextStyle(fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          if (log.error != null || log.stackTrace != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message: ${log.message}',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                  if (log.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${log.error}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                  if (log.stackTrace != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Stack Trace:\n${log.stackTrace}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  void _exportLogs() {
    final logs = _filteredLogs;
    final logText = logs.map((log) => log.toString()).join('\n');
    
    Clipboard.setData(ClipboardData(text: logText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日志已复制到剪贴板')),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}