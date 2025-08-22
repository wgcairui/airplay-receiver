import 'dart:convert';
import 'automated_test_service.dart';

class TestReportGenerator {
  static const String _reportVersion = '1.0';
  
  /// 生成HTML格式的测试报告
  static String generateHtmlReport(TestReport report, {
    bool includeMetrics = true,
    bool includeCharts = false,
  }) {
    final buffer = StringBuffer();
    
    // HTML头部
    buffer.writeln('''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PadCast 自动化测试报告</title>
    <style>
        ${_getHtmlStyles()}
    </style>
</head>
<body>
    <div class="container">
''');
    
    // 报告头部
    buffer.writeln(_generateHtmlHeader(report));
    
    // 执行摘要
    buffer.writeln(_generateHtmlSummary(report));
    
    // 测试结果详情
    buffer.writeln(_generateHtmlResults(report, includeMetrics));
    
    // 性能图表（如果启用）
    if (includeCharts) {
      buffer.writeln(_generateHtmlCharts(report));
    }
    
    // 结论和建议
    buffer.writeln(_generateHtmlConclusions(report));
    
    // HTML尾部
    buffer.writeln('''
    </div>
    ${includeCharts ? '<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>' : ''}
    <script>
        ${_getHtmlScripts()}
    </script>
</body>
</html>
''');
    
    return buffer.toString();
  }
  
  /// 生成JSON格式的测试报告
  static String generateJsonReport(TestReport report, {
    bool includeFullMetrics = true,
    bool pretty = true,
  }) {
    final reportData = {
      'metadata': {
        'report_version': _reportVersion,
        'generated_at': DateTime.now().toIso8601String(),
        'suite_name': report.suiteName,
        'total_duration_ms': report.totalDuration.inMilliseconds,
        'timestamp': report.timestamp.toIso8601String(),
      },
      'summary': {
        'total_tests': report.totalTests,
        'passed_tests': report.passedTests,
        'failed_tests': report.failedTests,
        'skipped_tests': report.skippedTests,
        'success_rate': report.successRate,
        'average_duration_ms': report.results.isNotEmpty
          ? report.results.map((r) => r.duration.inMilliseconds).reduce((a, b) => a + b) / report.results.length
          : 0,
      },
      'results': report.results.map((result) {
        final resultData = {
          'test_name': result.testName,
          'type': result.type.toString(),
          'status': result.status.toString(),
          'duration_ms': result.duration.inMilliseconds,
          'timestamp': result.timestamp.toIso8601String(),
        };
        
        if (result.errorMessage != null) {
          resultData['error_message'] = result.errorMessage!;
        }
        
        if (includeFullMetrics) {
          resultData['metrics'] = result.metrics;
        } else {
          // 只包含关键指标
          resultData['key_metrics'] = _extractKeyMetrics(result.metrics);
        }
        
        return resultData;
      }).toList(),
      'analysis': _generateAnalysis(report),
      'recommendations': _generateRecommendations(report),
    };
    
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(reportData);
    } else {
      return jsonEncode(reportData);
    }
  }
  
  /// 生成Markdown格式的测试报告
  static String generateMarkdownReport(TestReport report) {
    final buffer = StringBuffer();
    
    // 标题
    buffer.writeln('# PadCast 自动化测试报告\n');
    
    // 基本信息
    buffer.writeln('## 测试信息\n');
    buffer.writeln('- **测试套件**: ${report.suiteName}');
    buffer.writeln('- **执行时间**: ${report.timestamp.toString()}');
    buffer.writeln('- **总耗时**: ${(report.totalDuration.inMilliseconds / 1000).toStringAsFixed(1)} 秒');
    buffer.writeln('- **报告版本**: $_reportVersion\n');
    
    // 执行摘要
    buffer.writeln('## 执行摘要\n');
    buffer.writeln('| 指标 | 数值 |');
    buffer.writeln('|------|------|');
    buffer.writeln('| 总测试数 | ${report.totalTests} |');
    buffer.writeln('| 通过数 | ${report.passedTests} |');
    buffer.writeln('| 失败数 | ${report.failedTests} |');
    buffer.writeln('| 跳过数 | ${report.skippedTests} |');
    buffer.writeln('| 成功率 | ${report.successRate.toStringAsFixed(1)}% |');
    
    // 状态分布
    if (report.results.isNotEmpty) {
      final avgDuration = report.results.map((r) => r.duration.inMilliseconds).reduce((a, b) => a + b) / report.results.length;
      buffer.writeln('| 平均耗时 | ${avgDuration.toStringAsFixed(1)} ms |');
    }
    buffer.writeln();
    
    // 测试结果详情
    buffer.writeln('## 测试结果详情\n');
    
    final groupedByType = <TestType, List<TestResult>>{};
    for (final result in report.results) {
      groupedByType.putIfAbsent(result.type, () => []).add(result);
    }
    
    for (final entry in groupedByType.entries) {
      buffer.writeln('### ${_getTestTypeDisplayName(entry.key)}\n');
      
      for (final result in entry.value) {
        final status = result.isSuccess ? '✅' : result.isFailure ? '❌' : '⏭️';
        buffer.writeln('- $status **${result.testName}** (${result.duration.inMilliseconds}ms)');
        
        if (result.errorMessage != null) {
          buffer.writeln('  - 错误: ${result.errorMessage}');
        }
        
        // 关键指标
        final keyMetrics = _extractKeyMetrics(result.metrics);
        if (keyMetrics.isNotEmpty) {
          buffer.writeln('  - 指标: ${keyMetrics.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
        }
      }
      buffer.writeln();
    }
    
    // 分析和建议
    final analysis = _generateAnalysis(report);
    if (analysis.isNotEmpty) {
      buffer.writeln('## 分析\n');
      for (final item in analysis) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }
    
    final recommendations = _generateRecommendations(report);
    if (recommendations.isNotEmpty) {
      buffer.writeln('## 建议\n');
      for (final recommendation in recommendations) {
        buffer.writeln('- $recommendation');
      }
      buffer.writeln();
    }
    
    // 附录
    buffer.writeln('## 附录\n');
    buffer.writeln('本报告由 PadCast 自动化测试框架生成。');
    buffer.writeln('\n---');
    buffer.writeln('*生成时间: ${DateTime.now().toString()}*');
    
    return buffer.toString();
  }
  
  /// 生成CSV格式的测试结果
  static String generateCsvReport(TestReport report) {
    final buffer = StringBuffer();
    
    // CSV头部
    buffer.writeln('测试名称,类型,状态,耗时(ms),错误信息,关键指标');
    
    // 测试结果数据
    for (final result in report.results) {
      final keyMetrics = _extractKeyMetrics(result.metrics);
      final metricsString = keyMetrics.entries.map((e) => '${e.key}=${e.value}').join(';');
      
      buffer.writeln([
        _escapeCsvField(result.testName),
        _getTestTypeDisplayName(result.type),
        _getStatusDisplayName(result.status),
        result.duration.inMilliseconds.toString(),
        _escapeCsvField(result.errorMessage ?? ''),
        _escapeCsvField(metricsString),
      ].join(','));
    }
    
    return buffer.toString();
  }
  
  /// 生成测试覆盖率报告
  static Map<String, dynamic> generateCoverageReport(List<TestReport> reports) {
    final allComponents = <String>{};
    final testedComponents = <String>{};
    final componentTestCounts = <String, int>{};
    
    for (final report in reports) {
      for (final result in report.results) {
        final components = result.metrics['components'] as List<String>? ?? [];
        
        for (final component in components) {
          allComponents.add(component);
          
          if (result.isSuccess) {
            testedComponents.add(component);
          }
          
          componentTestCounts[component] = (componentTestCounts[component] ?? 0) + 1;
        }
      }
    }
    
    // 添加已知组件（即使没有被测试）
    const knownComponents = [
      'airplay_service',
      'network_monitor',
      'performance_monitor',
      'sync_service',
      'video_decoder',
      'audio_decoder',
      'settings_service',
      'logger_service',
    ];
    
    allComponents.addAll(knownComponents);
    
    final coverageData = <String, dynamic>{};
    for (final component in allComponents) {
      coverageData[component] = {
        'tested': testedComponents.contains(component),
        'test_count': componentTestCounts[component] ?? 0,
        'coverage_percentage': testedComponents.contains(component) ? 100.0 : 0.0,
      };
    }
    
    return {
      'overall_coverage': allComponents.isEmpty ? 0.0 : (testedComponents.length / allComponents.length) * 100,
      'total_components': allComponents.length,
      'tested_components': testedComponents.length,
      'untested_components': allComponents.difference(testedComponents).toList(),
      'component_details': coverageData,
      'summary': {
        'most_tested': _getMostTestedComponent(componentTestCounts),
        'least_tested': _getLeastTestedComponent(componentTestCounts, allComponents),
        'recommendations': _generateCoverageRecommendations(allComponents, testedComponents),
      },
    };
  }
  
  /// 生成性能趋势报告
  static Map<String, dynamic> generateTrendReport(List<TestReport> reports) {
    if (reports.isEmpty) return {};
    
    reports.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final trends = <String, List<double>>{};
    final timestamps = <String>[];
    
    for (final report in reports) {
      timestamps.add(report.timestamp.toIso8601String());
      
      // 收集关键指标
      final successRate = report.successRate;
      final avgDuration = report.results.isNotEmpty
        ? report.results.map((r) => r.duration.inMilliseconds).reduce((a, b) => a + b) / report.results.length
        : 0.0;
      
      trends.putIfAbsent('success_rate', () => []).add(successRate);
      trends.putIfAbsent('avg_duration_ms', () => []).add(avgDuration);
      trends.putIfAbsent('total_tests', () => []).add(report.totalTests.toDouble());
    }
    
    // 计算趋势
    final trendAnalysis = <String, dynamic>{};
    for (final entry in trends.entries) {
      final values = entry.value;
      if (values.length >= 2) {
        final trend = _calculateTrend(values);
        trendAnalysis[entry.key] = {
          'values': values,
          'trend': trend,
          'direction': trend > 0.1 ? 'improving' : trend < -0.1 ? 'declining' : 'stable',
          'latest': values.last,
          'average': values.reduce((a, b) => a + b) / values.length,
        };
      }
    }
    
    return {
      'timestamps': timestamps,
      'trends': trendAnalysis,
      'period': {
        'start': reports.first.timestamp.toIso8601String(),
        'end': reports.last.timestamp.toIso8601String(),
        'total_reports': reports.length,
      },
      'insights': _generateTrendInsights(trendAnalysis),
    };
  }
  
  // 私有辅助方法
  
  static String _generateHtmlHeader(TestReport report) {
    return '''
<header class="header">
    <h1>PadCast 自动化测试报告</h1>
    <div class="header-info">
        <div class="info-item">
            <span class="label">测试套件:</span>
            <span class="value">${report.suiteName}</span>
        </div>
        <div class="info-item">
            <span class="label">执行时间:</span>
            <span class="value">${report.timestamp.toString()}</span>
        </div>
        <div class="info-item">
            <span class="label">总耗时:</span>
            <span class="value">${(report.totalDuration.inMilliseconds / 1000).toStringAsFixed(1)} 秒</span>
        </div>
    </div>
</header>
''';
  }
  
  static String _generateHtmlSummary(TestReport report) {
    final successRateClass = report.successRate >= 90 ? 'success' : 
                           report.successRate >= 70 ? 'warning' : 'danger';
    
    return '''
<section class="summary">
    <h2>执行摘要</h2>
    <div class="summary-grid">
        <div class="summary-card">
            <div class="card-header">总测试数</div>
            <div class="card-value">${report.totalTests}</div>
        </div>
        <div class="summary-card success">
            <div class="card-header">通过</div>
            <div class="card-value">${report.passedTests}</div>
        </div>
        <div class="summary-card danger">
            <div class="card-header">失败</div>
            <div class="card-value">${report.failedTests}</div>
        </div>
        <div class="summary-card warning">
            <div class="card-header">跳过</div>
            <div class="card-value">${report.skippedTests}</div>
        </div>
        <div class="summary-card $successRateClass">
            <div class="card-header">成功率</div>
            <div class="card-value">${report.successRate.toStringAsFixed(1)}%</div>
        </div>
    </div>
</section>
''';
  }
  
  static String _generateHtmlResults(TestReport report, bool includeMetrics) {
    final buffer = StringBuffer();
    buffer.writeln('<section class="results">');
    buffer.writeln('<h2>测试结果详情</h2>');
    
    final groupedByType = <TestType, List<TestResult>>{};
    for (final result in report.results) {
      groupedByType.putIfAbsent(result.type, () => []).add(result);
    }
    
    for (final entry in groupedByType.entries) {
      buffer.writeln('<div class="test-type-group">');
      buffer.writeln('<h3>${_getTestTypeDisplayName(entry.key)}</h3>');
      buffer.writeln('<div class="test-results">');
      
      for (final result in entry.value) {
        final statusClass = result.isSuccess ? 'success' : result.isFailure ? 'danger' : 'warning';
        final statusIcon = result.isSuccess ? '✅' : result.isFailure ? '❌' : '⏭️';
        
        buffer.writeln('<div class="test-result $statusClass">');
        buffer.writeln('<div class="result-header">');
        buffer.writeln('<span class="status-icon">$statusIcon</span>');
        buffer.writeln('<span class="test-name">${result.testName}</span>');
        buffer.writeln('<span class="duration">${result.duration.inMilliseconds}ms</span>');
        buffer.writeln('</div>');
        
        if (result.errorMessage != null) {
          buffer.writeln('<div class="error-message">');
          buffer.writeln('<strong>错误:</strong> ${result.errorMessage}');
          buffer.writeln('</div>');
        }
        
        if (includeMetrics && result.metrics.isNotEmpty) {
          buffer.writeln('<div class="metrics">');
          buffer.writeln('<strong>指标:</strong>');
          buffer.writeln('<ul>');
          for (final entry in result.metrics.entries) {
            buffer.writeln('<li>${entry.key}: ${entry.value}</li>');
          }
          buffer.writeln('</ul>');
          buffer.writeln('</div>');
        }
        
        buffer.writeln('</div>');
      }
      
      buffer.writeln('</div>');
      buffer.writeln('</div>');
    }
    
    buffer.writeln('</section>');
    return buffer.toString();
  }
  
  static String _generateHtmlCharts(TestReport report) {
    return '''
<section class="charts">
    <h2>数据图表</h2>
    <div class="chart-container">
        <canvas id="successChart"></canvas>
    </div>
    <div class="chart-container">
        <canvas id="durationChart"></canvas>
    </div>
</section>
''';
  }
  
  static String _generateHtmlConclusions(TestReport report) {
    final analysis = _generateAnalysis(report);
    final recommendations = _generateRecommendations(report);
    
    final buffer = StringBuffer();
    buffer.writeln('<section class="conclusions">');
    
    if (analysis.isNotEmpty) {
      buffer.writeln('<h2>分析</h2>');
      buffer.writeln('<ul>');
      for (final item in analysis) {
        buffer.writeln('<li>$item</li>');
      }
      buffer.writeln('</ul>');
    }
    
    if (recommendations.isNotEmpty) {
      buffer.writeln('<h2>建议</h2>');
      buffer.writeln('<ul class="recommendations">');
      for (final recommendation in recommendations) {
        buffer.writeln('<li>$recommendation</li>');
      }
      buffer.writeln('</ul>');
    }
    
    buffer.writeln('</section>');
    return buffer.toString();
  }
  
  static String _getHtmlStyles() {
    return '''
body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    background-color: #f5f5f5;
}

.container {
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    overflow: hidden;
}

.header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 30px;
    text-align: center;
}

.header h1 {
    margin: 0 0 20px 0;
    font-size: 2.5em;
}

.header-info {
    display: flex;
    justify-content: center;
    gap: 30px;
    flex-wrap: wrap;
}

.info-item {
    display: flex;
    flex-direction: column;
    align-items: center;
}

.label {
    font-size: 0.9em;
    opacity: 0.8;
}

.value {
    font-size: 1.1em;
    font-weight: bold;
    margin-top: 5px;
}

.summary {
    padding: 30px;
    border-bottom: 1px solid #eee;
}

.summary h2 {
    margin-top: 0;
    color: #2c3e50;
}

.summary-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 20px;
    margin-top: 20px;
}

.summary-card {
    background: #f8f9fa;
    border-radius: 8px;
    padding: 20px;
    text-align: center;
    border-left: 4px solid #6c757d;
}

.summary-card.success {
    border-left-color: #28a745;
}

.summary-card.danger {
    border-left-color: #dc3545;
}

.summary-card.warning {
    border-left-color: #ffc107;
}

.card-header {
    font-size: 0.9em;
    color: #6c757d;
    margin-bottom: 10px;
}

.card-value {
    font-size: 2em;
    font-weight: bold;
    color: #2c3e50;
}

.results {
    padding: 30px;
}

.test-type-group {
    margin-bottom: 30px;
}

.test-type-group h3 {
    color: #2c3e50;
    border-bottom: 2px solid #3498db;
    padding-bottom: 10px;
}

.test-result {
    background: #f8f9fa;
    border-radius: 6px;
    padding: 15px;
    margin-bottom: 10px;
    border-left: 4px solid #6c757d;
}

.test-result.success {
    border-left-color: #28a745;
}

.test-result.danger {
    border-left-color: #dc3545;
}

.test-result.warning {
    border-left-color: #ffc107;
}

.result-header {
    display: flex;
    align-items: center;
    gap: 10px;
}

.status-icon {
    font-size: 1.2em;
}

.test-name {
    flex: 1;
    font-weight: 500;
}

.duration {
    color: #6c757d;
    font-size: 0.9em;
}

.error-message {
    margin-top: 10px;
    padding: 10px;
    background: #f8d7da;
    border-radius: 4px;
    color: #721c24;
    font-size: 0.9em;
}

.metrics {
    margin-top: 10px;
    font-size: 0.9em;
}

.metrics ul {
    margin: 5px 0;
    padding-left: 20px;
}

.conclusions {
    padding: 30px;
    background: #f8f9fa;
}

.recommendations li {
    margin-bottom: 10px;
    padding: 10px;
    background: white;
    border-radius: 4px;
    border-left: 3px solid #3498db;
}

.chart-container {
    margin: 20px 0;
    height: 300px;
}

@media (max-width: 768px) {
    .header-info {
        flex-direction: column;
        gap: 15px;
    }
    
    .summary-grid {
        grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    }
    
    .result-header {
        flex-wrap: wrap;
    }
}
''';
  }
  
  static String _getHtmlScripts() {
    return '''
// 简单的交互功能
document.addEventListener('DOMContentLoaded', function() {
    // 添加点击展开/收起功能
    const testResults = document.querySelectorAll('.test-result');
    testResults.forEach(result => {
        const metrics = result.querySelector('.metrics');
        if (metrics) {
            const header = result.querySelector('.result-header');
            header.style.cursor = 'pointer';
            header.addEventListener('click', () => {
                metrics.style.display = metrics.style.display === 'none' ? 'block' : 'none';
            });
            // 默认隐藏
            metrics.style.display = 'none';
        }
    });
});
''';
  }
  
  static Map<String, dynamic> _extractKeyMetrics(Map<String, dynamic> metrics) {
    const keyMetricNames = [
      'cpu_usage_percent',
      'memory_usage_percent',
      'latency_ms',
      'frame_rate',
      'assertions',
      'is_in_sync',
      'sync_difference_ms',
    ];
    
    final keyMetrics = <String, dynamic>{};
    for (final key in keyMetricNames) {
      if (metrics.containsKey(key)) {
        keyMetrics[key] = metrics[key];
      }
    }
    
    return keyMetrics;
  }
  
  static List<String> _generateAnalysis(TestReport report) {
    final analysis = <String>[];
    
    // 成功率分析
    if (report.successRate >= 95) {
      analysis.add('测试成功率优秀 (${report.successRate.toStringAsFixed(1)}%)，系统运行稳定');
    } else if (report.successRate >= 80) {
      analysis.add('测试成功率良好 (${report.successRate.toStringAsFixed(1)}%)，存在少量问题需要关注');
    } else {
      analysis.add('测试成功率偏低 (${report.successRate.toStringAsFixed(1)}%)，建议优先修复失败的测试用例');
    }
    
    // 性能分析
    final performanceTests = report.results.where((r) => r.type == TestType.performance).toList();
    if (performanceTests.isNotEmpty) {
      final failedPerformance = performanceTests.where((r) => r.isFailure).length;
      if (failedPerformance > 0) {
        analysis.add('$failedPerformance 个性能测试失败，可能存在性能问题');
      } else {
        analysis.add('所有性能测试通过，系统性能表现良好');
      }
    }
    
    // 集成测试分析
    final integrationTests = report.results.where((r) => r.type == TestType.integration).toList();
    if (integrationTests.isNotEmpty) {
      final failedIntegration = integrationTests.where((r) => r.isFailure).length;
      if (failedIntegration > 0) {
        analysis.add('$failedIntegration 个集成测试失败，可能存在模块间协作问题');
      }
    }
    
    // 执行时间分析
    if (report.results.isNotEmpty) {
      final totalDuration = report.totalDuration.inSeconds;
      if (totalDuration > 300) { // 5分钟
        analysis.add('测试执行时间较长 ($totalDuration 秒)，建议优化测试效率');
      }
    }
    
    return analysis;
  }
  
  static List<String> _generateRecommendations(TestReport report) {
    final recommendations = <String>[];
    
    // 基于失败测试的建议
    final failedTests = report.results.where((r) => r.isFailure).toList();
    
    if (failedTests.isNotEmpty) {
      recommendations.add('优先修复 ${failedTests.length} 个失败的测试用例');
      
      // 分析失败原因
      final timeoutFailures = failedTests.where((r) => r.status == TestStatus.timeout).length;
      if (timeoutFailures > 0) {
        recommendations.add('$timeoutFailures 个测试超时，考虑增加超时时间或优化测试性能');
      }
      
      // 检查常见错误模式
      final networkErrors = failedTests.where((r) => 
        r.errorMessage?.contains('网络') == true || 
        r.errorMessage?.contains('连接') == true
      ).length;
      
      if (networkErrors > 0) {
        recommendations.add('$networkErrors 个测试出现网络相关错误，检查网络连接和配置');
      }
    }
    
    // 基于跳过测试的建议
    if (report.skippedTests > 0) {
      recommendations.add('有 ${report.skippedTests} 个测试被跳过，考虑实现这些测试以提高覆盖率');
    }
    
    // 性能相关建议
    final performanceTests = report.results.where((r) => r.type == TestType.performance).toList();
    if (performanceTests.isNotEmpty) {
      final slowTests = performanceTests.where((r) => r.duration.inMilliseconds > 5000).toList();
      if (slowTests.isNotEmpty) {
        recommendations.add('${slowTests.length} 个性能测试执行时间超过 5 秒，考虑优化或分解测试');
      }
    }
    
    // 覆盖率建议
    final testedComponents = <String>{};
    for (final result in report.results) {
      if (result.isSuccess) {
        final components = result.metrics['components'] as List<String>? ?? [];
        testedComponents.addAll(components);
      }
    }
    
    if (testedComponents.length < 5) {
      recommendations.add('当前测试覆盖的组件较少，建议增加更多组件的测试用例');
    }
    
    // 通用建议
    if (report.successRate < 100) {
      recommendations.add('定期运行自动化测试，及时发现和修复问题');
      recommendations.add('考虑添加更多的单元测试以提高代码质量');
    }
    
    return recommendations;
  }
  
  static String _getTestTypeDisplayName(TestType type) {
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
  
  static String _getStatusDisplayName(TestStatus status) {
    switch (status) {
      case TestStatus.passed:
        return '通过';
      case TestStatus.failed:
        return '失败';
      case TestStatus.timeout:
        return '超时';
      case TestStatus.skipped:
        return '跳过';
      case TestStatus.running:
        return '运行中';
      case TestStatus.pending:
        return '待执行';
    }
  }
  
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
  
  static String _getMostTestedComponent(Map<String, int> counts) {
    if (counts.isEmpty) return 'none';
    
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
  
  static String _getLeastTestedComponent(Map<String, int> counts, Set<String> allComponents) {
    final untested = allComponents.where((c) => !counts.containsKey(c));
    if (untested.isNotEmpty) return untested.first;
    
    if (counts.isEmpty) return 'none';
    
    return counts.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }
  
  static List<String> _generateCoverageRecommendations(Set<String> allComponents, Set<String> testedComponents) {
    final recommendations = <String>[];
    final untested = allComponents.difference(testedComponents);
    
    if (untested.isNotEmpty) {
      recommendations.add('为未测试的组件添加测试用例: ${untested.join(', ')}');
    }
    
    final coverage = allComponents.isEmpty ? 0.0 : (testedComponents.length / allComponents.length) * 100;
    
    if (coverage < 60) {
      recommendations.add('测试覆盖率较低 (${coverage.toStringAsFixed(1)}%)，建议增加更多测试用例');
    } else if (coverage < 80) {
      recommendations.add('测试覆盖率有待提升 (${coverage.toStringAsFixed(1)}%)，重点关注核心组件');
    }
    
    return recommendations;
  }
  
  static double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    // 简单线性回归计算趋势
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = values;
    
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumXX = x.map((xi) => xi * xi).reduce((a, b) => a + b);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    
    return slope;
  }
  
  static List<String> _generateTrendInsights(Map<String, dynamic> trends) {
    final insights = <String>[];
    
    for (final entry in trends.entries) {
      final trendData = entry.value as Map<String, dynamic>;
      final direction = trendData['direction'] as String;
      final metric = entry.key;
      
      switch (direction) {
        case 'improving':
          insights.add('$metric 呈改善趋势');
          break;
        case 'declining':
          insights.add('$metric 呈下降趋势，需要关注');
          break;
        case 'stable':
          insights.add('$metric 保持稳定');
          break;
      }
    }
    
    return insights;
  }
}