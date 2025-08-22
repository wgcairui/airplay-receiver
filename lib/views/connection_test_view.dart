import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/connection_test_service.dart';
import '../controllers/airplay_controller.dart';
import '../widgets/mac_connection_guide_dialog.dart';

class ConnectionTestView extends StatefulWidget {
  const ConnectionTestView({super.key});

  @override
  State<ConnectionTestView> createState() => _ConnectionTestViewState();
}

class _ConnectionTestViewState extends State<ConnectionTestView> {
  List<TestResult> _testResults = [];
  bool _isRunning = false;
  
  @override
  void initState() {
    super.initState();
    
    // 在下一帧设置AirPlay控制器引用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final airplayController = context.read<AirPlayController>();
      connectionTestService.setAirPlayController(airplayController);
    });
    
    // 监听测试结果更新
    connectionTestService.resultsStream.listen((results) {
      if (mounted) {
        setState(() {
          _testResults = results;
          _isRunning = connectionTestService.isRunning;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('连接测试'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (!_isRunning)
            IconButton(
              onPressed: _startTests,
              icon: const Icon(Icons.play_arrow),
              tooltip: '开始测试',
            ),
          if (_isRunning) ...[
            IconButton(
              onPressed: _cancelTests,
              icon: const Icon(Icons.stop),
              tooltip: '取消测试',
            ),
            IconButton(
              onPressed: null,
              icon: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
          IconButton(
            onPressed: _clearResults,
            icon: const Icon(Icons.clear_all),
            tooltip: '清空结果',
          ),
        ],
      ),
      body: Column(
        children: [
          // 测试概览卡片
          Container(
            margin: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assessment,
                          color: Colors.blue[600],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AirPlay 连接诊断',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getOverviewText(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_isRunning && _testResults.isEmpty)
                      Consumer<AirPlayController>(
                        builder: (context, airplayController, child) {
                          final isServiceRunning = airplayController.isServiceRunning;
                          
                          return Column(
                            children: [
                              if (!isServiceRunning) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _startAirPlayService,
                                    icon: const Icon(Icons.power_settings_new),
                                    label: const Text('启动AirPlay服务'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isServiceRunning ? _startTests : null,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('开始测试'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // 测试结果列表
          Expanded(
            child: _testResults.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                    itemCount: _testResults.length,
                    itemBuilder: (context, index) {
                      return _buildTestResultCard(_testResults[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _testResults.isNotEmpty && !_isRunning
          ? FloatingActionButton.extended(
              onPressed: _showTestSummary,
              icon: const Icon(Icons.summarize),
              label: const Text('测试报告'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_find,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '点击开始测试来检测AirPlay功能',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '测试将验证网络连接、服务状态和解码器功能',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestResultCard(TestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildStatusIcon(result.status),
          title: Text(
            result.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.details != null) ...[
                const SizedBox(height: 4),
                Text(
                  result.details!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _getStatusColor(result.status),
                  ),
                ),
              ],
              if (result.duration != null) ...[
                const SizedBox(height: 2),
                Text(
                  '耗时: ${result.duration!.inMilliseconds}ms',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          trailing: result.status == TestStatus.running
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
      ),
    );
  }
  
  Widget _buildStatusIcon(TestStatus status) {
    switch (status) {
      case TestStatus.pending:
        return Icon(Icons.schedule, color: Colors.grey[400], size: 28);
      case TestStatus.running:
        return const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case TestStatus.passed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 28);
      case TestStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 28);
    }
  }
  
  Color _getStatusColor(TestStatus status) {
    switch (status) {
      case TestStatus.pending:
        return Colors.grey;
      case TestStatus.running:
        return Colors.blue;
      case TestStatus.passed:
        return Colors.green;
      case TestStatus.failed:
        return Colors.red;
    }
  }
  
  String _getOverviewText() {
    final airplayController = context.watch<AirPlayController>();
    final isServiceRunning = airplayController.isServiceRunning;
    
    if (_testResults.isEmpty) {
      final serviceStatus = isServiceRunning ? '✓ AirPlay服务运行中' : '⚠ AirPlay服务未启动';
      return '准备进行全面的AirPlay连接测试，包括网络、服务和解码器检测\n$serviceStatus';
    }
    
    final passed = _testResults.where((r) => r.status == TestStatus.passed).length;
    final failed = _testResults.where((r) => r.status == TestStatus.failed).length;
    final running = _testResults.where((r) => r.status == TestStatus.running).length;
    final pending = _testResults.where((r) => r.status == TestStatus.pending).length;
    
    if (_isRunning) {
      return '正在进行测试... ($passed通过, $failed失败, $running进行中, $pending待测试)';
    } else {
      return '测试完成: $passed项通过, $failed项失败';
    }
  }
  
  void _startTests() async {
    try {
      await connectionTestService.runConnectionTests();
      
      if (mounted) {
        final failed = _testResults.where((r) => r.status == TestStatus.failed).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failed == 0 ? '所有测试通过！AirPlay功能正常' : '发现$failed项问题，请检查详细信息',
            ),
            backgroundColor: failed == 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('测试执行失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _clearResults() {
    connectionTestService.clearResults();
    setState(() {
      _testResults = [];
    });
  }
  
  void _cancelTests() {
    connectionTestService.cancelTests();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('测试已取消'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _startAirPlayService() async {
    try {
      final airplayController = context.read<AirPlayController>();
      await airplayController.startAirPlayService();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AirPlay服务启动成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AirPlay服务启动失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _showTestSummary() {
    final summary = connectionTestService.getTestSummary();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assessment, size: 32, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Text(
                    '连接测试报告',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      summary,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Copy summary to clipboard
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        
                        await Clipboard.setData(ClipboardData(text: summary));
                        if (!mounted) return;
                        
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('测试报告已复制到剪贴板'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('复制报告'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showMacConnectionGuide();
                      },
                      icon: const Icon(Icons.laptop_mac),
                      label: const Text('Mac连接指南'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showMacConnectionGuide() {
    showDialog(
      context: context,
      builder: (context) => const MacConnectionGuideDialog(),
    );
  }
}