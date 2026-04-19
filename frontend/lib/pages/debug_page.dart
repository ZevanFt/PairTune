import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/backend_health.dart';
import '../services/api_logger.dart';
import '../services/health_api_service.dart';
import '../ui/app_theme.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final _healthApi = HealthApiService();
  BackendHealthStatus? _healthStatus;
  bool _checking = false;
  List<String> _logs = const [];

  @override
  void initState() {
    super.initState();
    _logs = ApiLogger.recent();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _checking = true);
    final status = await _healthApi.checkHealth();
    final logs = ApiLogger.recent(limit: 120);
    if (!mounted) return;
    setState(() {
      _healthStatus = status;
      _logs = logs;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _healthStatus;
    final online = status?.online == true;
    final healthText = status == null
        ? '未检测'
        : (online
              ? '在线 (200 OK)'
              : '${status.statusCode == 0 ? '离线' : status.statusCode} ${status.statusText}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('调试页面'),
        actions: [
          IconButton(
            tooltip: '清空日志',
            onPressed: () {
              ApiLogger.clear();
              setState(() => _logs = const []);
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgMid, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHero(healthText, online),
            const SizedBox(height: 14),
            _buildSectionTitle('诊断控制', '主动发起健康检测并刷新最近请求日志'),
            const SizedBox(height: 8),
            _buildActionPanel(),
            const SizedBox(height: 14),
            _buildSectionTitle('请求日志', '最近 120 条，已按时间倒序'),
            const SizedBox(height: 8),
            if (_logs.isEmpty)
              _buildEmptyCard('暂无日志，点击“运行网络诊断”后查看请求记录')
            else
              ..._logs.reversed.map(_buildLogCard),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(String healthText, bool online) {
    final statusColor = _healthStatus == null
        ? Colors.white70
        : (online ? AppTheme.success : AppTheme.danger);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppTheme.heroStart, AppTheme.heroMid, AppTheme.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F243355),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x2DFFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'DIAGNOSTIC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '联通性检查与日志观察',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip('Base URL', ApiConfig.baseUrl),
              _heroChip('健康状态', healthText, dotColor: statusColor),
              _heroChip('日志条数', '${_logs.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label, String value, {Color? dotColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x2BFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _checking ? null : _runDiagnostics,
            icon: _checking
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(_checking ? '诊断中...' : '运行网络诊断'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ApiLogger.clear();
              setState(() => _logs = const []);
            },
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('清空日志'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLogCard(String line) {
    final isError = line.contains(' xx ') || line.toLowerCase().contains('error');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isError
            ? AppTheme.errorBg.withValues(alpha: 0.92)
            : AppTheme.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError ? AppTheme.errorBorder : AppTheme.panelBorder,
        ),
      ),
      child: SelectableText(
        line,
        style: const TextStyle(
          fontSize: 12,
          height: 1.4,
          color: AppTheme.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
