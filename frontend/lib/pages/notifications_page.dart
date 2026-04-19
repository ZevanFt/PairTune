import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/backend_health.dart';
import '../models/notice_item.dart';
import '../providers/api_providers.dart';
import '../providers/app_provider.dart';
import '../ui/app_space.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/health_indicator.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_panel.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _loading = true;
  String? _error;
  BackendHealthStatus? _healthStatus;
  int _unreadCount = 0;
  List<NoticeItem> _list = [];

  String get _owner => ref.read(appProvider).owner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final (list, unread) = await ref.read(accountApiProvider).listNotifications(_owner);
      final health = await ref.read(healthApiProvider).checkHealth();
      if (mounted) setState(() { _list = list; _unreadCount = unread; _healthStatus = health; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _error = formatErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _markRead(NoticeItem item) async {
    try {
      await ref.read(accountApiProvider).markNotificationRead(owner: _owner, id: item.id);
      await _load();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(accountApiProvider).markAllNotificationsRead(_owner);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TitleWithHealth(
          title: '通知中心',
          status: _healthStatus ?? const BackendHealthStatus(online: false, statusCode: 0, statusText: '检查中'),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text('全部已读 ($_unreadCount)'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            if (_error != null) ...[
              ErrorPanel(message: _error!, onRetry: _load),
              const SizedBox(height: AppSpace.md),
            ],
            if (_loading)
              const LoadingState()
            else if (_list.isEmpty)
              const EmptyState(icon: Icons.notifications_none_rounded, message: '暂无通知')
            else
              ..._list.map(_buildNoticeTile),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeTile(NoticeItem item) {
    final timeStr = DateFormat('MM-dd HH:mm').format(item.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: item.isRead ? AppTheme.surfaceMuted : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: item.isRead ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: item.isRead ? null : [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.06), offset: const Offset(0, 1), blurRadius: 4)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: item.isRead ? null : () => _markRead(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (!item.isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8), decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                Expanded(child: Text(item.title, style: AppText.headline.copyWith(color: item.isRead ? AppTheme.textMuted : AppTheme.ink))),
                Text(timeStr, style: AppText.caption.copyWith(color: AppTheme.textMuted)),
              ]),
              const SizedBox(height: 6),
              Text(item.body, style: AppText.bodyMuted(), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
