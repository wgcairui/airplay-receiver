import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../constants/app_constants.dart';
import '../services/automated_test_service.dart';
import '../services/airplay_service.dart';
import '../services/network_monitor_service.dart';
import '../services/performance_monitor_service.dart';
import '../services/audio_video_sync_service.dart';
import '../services/video_decoder_service.dart';
import '../services/audio_decoder_service.dart';

class AutomatedTestView extends StatefulWidget {
  const AutomatedTestView({super.key});

  @override
  State<AutomatedTestView> createState() => _AutomatedTestViewState();
}

class _AutomatedTestViewState extends State<AutomatedTestView> {
  late AutomatedTestService _testService;
  bool _isInitialized = false;

  TestSuite? _selectedSuite;
  TestReport? _currentReport;
  List<TestResult> _currentResults = [];
  List<String> _testLogs = [];
  bool _isRunning = false;

  final List<TestSuite> _availableSuites = [];

  @override
  void initState() {
    super.initState();
    _initializeTestService();
  }

  Future<void> _initializeTestService() async {
    try {
      // 获取所有必要的服务实例
      // 注意：在实际应用中，这些服务应该通过依赖注入获取
      final airplayService = AirPlayService(); // 这里需要实际的服务实例
      final networkMonitor = NetworkMonitorService();
      final performanceMonitor = PerformanceMonitorService();
      final syncService = AudioVideoSyncService();
      final videoDecoder = VideoDecoderService();
      final audioDecoder = AudioDecoderService();

      _testService = AutomatedTestService(
        airplayService: airplayService,
        networkMonitor: networkMonitor,
        performanceMonitor: performanceMonitor,
        syncService: syncService,
        videoDecoder: videoDecoder,
        audioDecoder: audioDecoder,
      );

      // 创建测试套件
      _availableSuites.addAll([
        _testService.createBasicTestSuite(),
        _testService.createPerformanceTestSuite(),
        _testService.createIntegrationTestSuite(),
        _testService.createRegressionTestSuite(),
      ]);

      // 监听测试结果
      _testService.testResultStream.listen((result) {
        setState(() {
          _currentResults.add(result);
        });
      });

      // 监听测试报告
      _testService.testReportStream.listen((report) {
        setState(() {
          _currentReport = report;
          _isRunning = false;
        });
      });

      // 监听测试日志
      _testService.testLogStream.listen((log) {
        setState(() {
          _testLogs.add(log);
          // 限制日志数量
          if (_testLogs.length > 1000) {
            _testLogs.removeAt(0);
          }
        });
      });

      setState(() {
        _isInitialized = true;
        _selectedSuite = _availableSuites.first;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('初始化测试服务失败: $e')),
      );
    }
  }

  @override
  void dispose() {
    _testService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('自动化测试'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('自动化测试'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_isRunning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopTests,
              tooltip: '停止测试',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearResults,
            tooltip: '清除结果',
          ),
        ],
      ),
      body: Column(
        children: [
          // 测试套件选择和控制面板
          _buildControlPanel(),

          // 测试结果区域
          Expanded(
            child: Row(
              children: [
                // 左侧：测试结果列表
                Expanded(
                  flex: 2,
                  child: _buildTestResults(),
                ),

                // 右侧：测试日志和报告
                Expanded(
                  flex: 1,
                  child: _buildTestLogs(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: Colors.blue[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                '测试套件选择',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // 测试套件下拉选择
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<TestSuite>(
                  // ignore: deprecated_member_use
                  value: _selectedSuite,
                  decoration: const InputDecoration(
                    labelText: '选择测试套件',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _availableSuites.map((suite) {
                    return DropdownMenuItem<TestSuite>(
                      value: suite,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            suite.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${suite.testCases.length} 个测试用例',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _isRunning
                      ? null
                      : (suite) {
                          setState(() {
                            _selectedSuite = suite;
                          });
                        },
                ),
              ),

              const SizedBox(width: 16),

              // 运行按钮
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _runSelectedSuite,
                icon: _isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isRunning ? '运行中...' : '运行测试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),

              const SizedBox(width: 8),

              // 导出报告按钮
              OutlinedButton.icon(
                onPressed: _currentReport != null ? _exportReport : null,
                icon: const Icon(Icons.file_download),
                label: const Text('导出报告'),
              ),
            ],
          ),

          // 测试套件信息
          if (_selectedSuite != null) ...[
            const SizedBox(height: 12),
            _buildSuiteInfo(_selectedSuite!),
          ],
        ],
      ),
    );
  }

  Widget _buildSuiteInfo(TestSuite suite) {
    final testTypeCount = <TestType, int>{};
    for (final testCase in suite.testCases) {
      testTypeCount[testCase.type] = (testTypeCount[testCase.type] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '测试套件详情',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                  '总计', '${suite.testCases.length} 个测试', Colors.grey),
              const SizedBox(width: 8),
              if (testTypeCount[TestType.unit] != null)
                _buildInfoChip(
                    '单元测试', '${testTypeCount[TestType.unit]}', Colors.green),
              const SizedBox(width: 8),
              if (testTypeCount[TestType.integration] != null)
                _buildInfoChip('集成测试', '${testTypeCount[TestType.integration]}',
                    Colors.orange),
              const SizedBox(width: 8),
              if (testTypeCount[TestType.performance] != null)
                _buildInfoChip('性能测试', '${testTypeCount[TestType.performance]}',
                    Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和统计
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  '测试结果',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),

                // 统计信息
                if (_currentResults.isNotEmpty) ...[
                  _buildStatusChip(
                    '通过',
                    _currentResults.where((r) => r.isSuccess).length,
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    '失败',
                    _currentResults.where((r) => r.isFailure).length,
                    Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    '总计',
                    _currentResults.length,
                    Colors.grey,
                  ),
                ],
              ],
            ),
          ),

          // 测试结果列表
          Expanded(
            child: _currentResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '暂无测试结果',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '选择测试套件并点击运行开始测试',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _currentResults.length,
                    itemBuilder: (context, index) {
                      final result = _currentResults[index];
                      return _buildTestResultItem(result);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTestResultItem(TestResult result) {
    IconData statusIcon;
    Color statusColor;

    switch (result.status) {
      case TestStatus.passed:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case TestStatus.failed:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        break;
      case TestStatus.timeout:
        statusIcon = Icons.access_time;
        statusColor = Colors.orange;
        break;
      case TestStatus.skipped:
        statusIcon = Icons.skip_next;
        statusColor = Colors.grey;
        break;
      case TestStatus.running:
        statusIcon = Icons.play_circle;
        statusColor = Colors.blue;
        break;
      case TestStatus.pending:
        statusIcon = Icons.pending;
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1,
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          result.testName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTestTypeColor(result.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getTestTypeDisplayName(result.type),
                style: TextStyle(
                  fontSize: 10,
                  color: _getTestTypeColor(result.type),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${result.duration.inMilliseconds}ms',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基本信息
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                          '状态', result.status.toString().split('.').last),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                          '耗时', '${result.duration.inMilliseconds}ms'),
                    ),
                    Expanded(
                      child:
                          _buildMetricItem('时间', _formatTime(result.timestamp)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 错误信息
                if (result.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '错误信息',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.errorMessage!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 指标信息
                if (result.metrics.isNotEmpty) ...[
                  const Text(
                    '测试指标',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.metrics.entries.map((entry) {
                      return _buildMetricChip(
                          entry.key, entry.value.toString());
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        '$key: $value',
        style: TextStyle(
          fontSize: 11,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildTestLogs() {
    return Container(
      margin: const EdgeInsets.only(
        top: AppConstants.defaultPadding,
        right: AppConstants.defaultPadding,
        bottom: AppConstants.defaultPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  '测试日志',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearLogs,
                  tooltip: '清除日志',
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // 日志内容
          Expanded(
            child: _testLogs.isEmpty
                ? const Center(
                    child: Text(
                      '暂无日志',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _testLogs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          _testLogs[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 测试报告摘要
          if (_currentReport != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: _buildReportSummary(_currentReport!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportSummary(TestReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assessment, color: Colors.blue[600], size: 16),
            const SizedBox(width: 4),
            const Text(
              '测试报告摘要',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                '成功率',
                '${report.successRate.toStringAsFixed(1)}%',
                report.successRate >= 90
                    ? Colors.green
                    : report.successRate >= 70
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
            Expanded(
              child: _buildSummaryItem(
                '总耗时',
                '${(report.totalDuration.inMilliseconds / 1000).toStringAsFixed(1)}s',
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                '通过',
                '${report.passedTests}',
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildSummaryItem(
                '失败',
                '${report.failedTests}',
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTestTypeColor(TestType type) {
    switch (type) {
      case TestType.unit:
        return Colors.green;
      case TestType.integration:
        return Colors.orange;
      case TestType.performance:
        return Colors.purple;
      case TestType.stress:
        return Colors.red;
      case TestType.endToEnd:
        return Colors.blue;
      case TestType.regression:
        return Colors.brown;
    }
  }

  String _getTestTypeDisplayName(TestType type) {
    switch (type) {
      case TestType.unit:
        return '单元测试';
      case TestType.integration:
        return '集成测试';
      case TestType.performance:
        return '性能测试';
      case TestType.stress:
        return '压力测试';
      case TestType.endToEnd:
        return '端到端测试';
      case TestType.regression:
        return '回归测试';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  void _runSelectedSuite() async {
    if (_selectedSuite == null || _isRunning) return;

    setState(() {
      _isRunning = true;
      _currentResults = [];
      _currentReport = null;
      _testLogs = [];
    });

    try {
      await _testService.runTestSuite(_selectedSuite!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('运行测试套件失败: $e')),
        );
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  void _stopTests() {
    _testService.stopTestSuite();
    setState(() {
      _isRunning = false;
    });
  }

  void _clearResults() {
    setState(() {
      _currentResults = [];
      _currentReport = null;
    });
  }

  void _clearLogs() {
    setState(() {
      _testLogs = [];
    });
  }

  void _exportReport() async {
    if (_currentReport == null) return;

    try {
      final reportJson = jsonEncode(_currentReport!.toJson());
      await Clipboard.setData(ClipboardData(text: reportJson));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('测试报告已复制到剪贴板')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出报告失败: $e')),
        );
      }
    }
  }
}
