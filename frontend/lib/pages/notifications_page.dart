import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/account_api_service.dart';
import '../services/health_api_service.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/hero_panel.dart';
import '../widgets/shimmer_block.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.owner});

  final String owner;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _accountApi = AccountApiService();
  final _healthApi = HealthApiService();
  bool _loading = true;
  String? _error;
  BackendHealthStatus? _healthStatus;
  int _unreadCount = 0;
  List<NoticeItem> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NotificationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner != widget.owner) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (list, unreadCount) = await _accountApi.listNotifications(
        widget.owner,
      );
      setState(() {
        _list = list;
        _unreadCount = unreadCount;
      });
    } catch (e) {
      setState(() {
        _error = formatErrorMessage(e);
      });
    } finally {
      final health = await _healthApi.checkHealth();
      if (mounted) {
        setState(() {
          _healthStatus = health;
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _accountApi.markAllNotificationsRead(widget.owner);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${formatErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerLabel = widget.owner == 'me' ? '我的提醒' : '搭档提醒';

    return Scaffold(
      appBar: AppBar(
        title: _buildTitleWithHealth('通知中心'),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _markAllRead,
                child: const Text('已读全部'),
              ),
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
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHero(ownerLabel),
              const SizedBox(height: 14),
              _buildSectionHeader('最新动态', '按时间倒序查看提醒'),
              const SizedBox(height: 8),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildErrorPanel(_error!),
                ),
              if (_loading && _list.isEmpty)
                ...List.generate(
                  4,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: ShimmerBlock(height: 92),
                  ),
                )
              else ...[
                ..._list.map((notice) => _buildNoticeTile(notice)),
                if (_list.isEmpty) _buildEmptyCard('暂无通知，去创建一个新任务吧'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleWithHealth(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHealthDot(),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }

  Widget _buildHealthDot() {
    final status = _healthStatus;
    final online = status?.online == true;
    final color = status == null
        ? Colors.grey
        : (online ? AppTheme.success : AppTheme.danger);
    return Icon(Icons.circle, size: 11, color: color);
  }

  Widget _buildHero(String ownerLabel) {
    return HeroPanel(
      tag: 'NOTIFICATION',
      title: ownerLabel,
      subtitle: '按时间倒序查看任务、积分与协作提醒',
      metrics: [
        HeroMetricData(
          icon: Icons.mark_email_unread_rounded,
          label: '未读',
          value: '$_unreadCount',
        ),
        HeroMetricData(
          icon: Icons.notifications_active_rounded,
          label: '总数',
          value: '${_list.length}',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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

  Widget _buildErrorPanel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        border: Border.all(color: AppTheme.errorBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '加载失败：$text',
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
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

  Widget _buildNoticeTile(NoticeItem notice) {
    final time = DateFormat('MM-dd HH:mm').format(notice.createdAt);
    final (icon, color, badgeText, badgeBg) = switch (notice.type) {
      'task' => (
        Icons.alarm_rounded,
        AppTheme.softBlue,
        '任务',
        AppTheme.softBlue,
      ),
      'exchange' => (
        Icons.redeem_rounded,
        AppTheme.softAmber,
        '兑换',
        AppTheme.softAmber,
      ),
      'relation' => (
        Icons.favorite_rounded,
        AppTheme.softViolet,
        '关系',
        AppTheme.softViolet,
      ),
      _ => (
        Icons.system_update_alt_rounded,
        const Color(0xFFE8F1FF),
        '系统',
        AppTheme.softBlue,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1F2E48),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: notice.isRead
                              ? Colors.grey.shade700
                              : AppTheme.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notice.body,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (notice.isRead)
                      const Icon(Icons.check_rounded, color: AppTheme.success, size: 18)
                    else
                      IconButton(
                        tooltip: '标记已读',
                        onPressed: () async {
                          try {
                            await _accountApi.markNotificationRead(
                              owner: widget.owner,
                              id: notice.id,
                            );
                            await _load();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('操作失败: ${formatErrorMessage(e)}'),
                              ),
                            );
                          }
                        },
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.mark_email_read_rounded, size: 18),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
