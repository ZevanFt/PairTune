import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/store_api_service.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/shimmer_block.dart';

class StoreOwnedRecordsPage extends StatefulWidget {
  const StoreOwnedRecordsPage({super.key, required this.owner});

  final String owner;

  @override
  State<StoreOwnedRecordsPage> createState() => _StoreOwnedRecordsPageState();
}

class _StoreOwnedRecordsPageState extends State<StoreOwnedRecordsPage> {
  final _store = StoreApiService();
  bool _loading = true;
  String? _error;
  List<OwnedItem> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _store.listOwnedItems(widget.owner);
      setState(() => _list = list);
    } catch (e) {
      setState(() => _error = formatErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('兑换记录')),
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
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              if (_error != null)
                _InfoCard(
                  text: '加载失败：$_error',
                  danger: true,
                ),
              if (_loading && _list.isEmpty) ...[
                const ShimmerBlock(height: 76),
                AppSpace.h8,
                const ShimmerBlock(height: 76),
              ] else ...[
                ..._list.map(_buildRecordCard),
                if (_list.isEmpty) const _InfoCard(text: '暂无兑换记录'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(OwnedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppSurface.subtleCard(shadow: true),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppTheme.primary, size: 18),
          AppSpace.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppText.cardTitle),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt),
                  style: AppText.sectionSubtitle,
                ),
              ],
            ),
          ),
          Text(
            '-${item.pointsSpent}',
            style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: danger
          ? BoxDecoration(
              color: AppTheme.errorBg,
              border: Border.all(color: AppTheme.errorBorder),
              borderRadius: BorderRadius.circular(14),
            )
          : AppSurface.subtleCard(),
      child: Text(
        text,
        style: TextStyle(
          color: danger ? AppTheme.danger : AppTheme.textMuted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

