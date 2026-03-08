import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/account_api_service.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/shimmer_block.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.owner});

  final String owner;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _accountApi = AccountApiService();
  bool _loading = true;
  String? _error;
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
      if (mounted) {
        setState(() {
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
        title: const Text('通知中心'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonal(
              onPressed: _markAllRead,
              child: const Text('全部已读'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFBF4), Color(0xFFFFF6F0), Color(0xFFF1F7FF)],
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
              _buildSectionHeader('最新动态', '按时间倒序展示提醒事件'),
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

  Widget _buildHero(String ownerLabel) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF17284A), Color(0xFF314772), Color(0xFF3C527F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A273C63),
            blurRadius: 22,
            offset: Offset(0, 10),
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
              'NOTIFICATION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ownerLabel,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricChip('未读', '$_unreadCount'),
              const SizedBox(width: 8),
              _metricChip('总数', '${_list.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x2BFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
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

  Widget _buildErrorPanel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        border: Border.all(color: const Color(0xFFF0C5C5)),
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
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DDD1)),
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
        const Color(0xFFFFF0D8),
        '任务',
        const Color(0xFFFFF3E2),
      ),
      'exchange' => (
        Icons.redeem_rounded,
        const Color(0xFFE8F6E8),
        '兑换',
        const Color(0xFFEAF8EF),
      ),
      'relation' => (
        Icons.favorite_rounded,
        const Color(0xFFFDE7F0),
        '关系',
        const Color(0xFFFDEDF5),
      ),
      _ => (
        Icons.system_update_alt_rounded,
        const Color(0xFFE8F1FF),
        '系统',
        const Color(0xFFEAF2FF),
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1B2948)),
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
                              : const Color(0xFF192948),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 11,
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
                      const Icon(Icons.check_rounded, color: AppTheme.success)
                    else
                      TextButton.icon(
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
                        icon: const Icon(Icons.mark_email_read_rounded, size: 18),
                        label: const Text('标记已读'),
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
