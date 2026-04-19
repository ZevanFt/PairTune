import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/backend_health.dart';
import '../models/product_item.dart';
import '../providers/api_providers.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/health_indicator.dart';
import '../widgets/loading_state.dart';
import '../widgets/section_header.dart';
import '../widgets/status_panel.dart';
import 'product_form_page.dart';
import 'store_my_products_page.dart';
import 'store_owned_records_page.dart';

class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key});

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  BackendHealthStatus? _healthStatus;

  int _points = 0;
  List<ProductItem> _market = [];

  String get _owner => ref.read(appProvider).owner;
  bool get _duoEnabled => ref.read(appProvider).duoEnabled;
  bool get _isGuest => ref.read(isGuestProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { if (_market.isEmpty) _loading = true; else _refreshing = true; _error = null; });
    try {
      final store = ref.read(storeApiProvider);
      final results = await Future.wait([store.getPoints(_owner), store.listMarketProducts(_owner)]);
      setState(() { _points = results[0] as int; _market = results[1] as List<ProductItem>; });
    } catch (e) {
      setState(() => _error = formatErrorMessage(e));
    } finally {
      final health = await ref.read(healthApiProvider).checkHealth();
      if (mounted) setState(() { _healthStatus = health; _loading = false; _refreshing = false; });
    }
  }

  Future<void> _exchange(ProductItem item) async {
    if (_isGuest) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('体验模式不可兑换，请登录后操作'))); return; }
    try {
      await ref.read(storeApiProvider).exchange(buyer: _owner, productId: item.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('兑换成功：${item.name}')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('兑换失败：${formatErrorMessage(e)}')));
    }
  }

  Future<void> _confirmAndExchange(ProductItem item) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SafeArea(top: false, child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确认兑换', style: AppText.title3),
            const SizedBox(height: 4),
            Text('请确认商品与积分信息', style: AppText.footnote.copyWith(color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: AppText.headline),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  _chip('消耗 ${item.pointsCost} 积分', AppTheme.softViolet),
                  _chip('库存 ${item.stock}', AppTheme.softBlue),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认兑换'))),
            ]),
          ],
        )),
      ),
    );
    if (confirmed == true) await _exchange(item);
  }

  Future<void> _showCreateProductPage() async {
    final draft = await Navigator.push<ProductDraft>(context, MaterialPageRoute(builder: (_) => const ProductFormPage()));
    if (draft == null) return;
    try {
      await ref.read(storeApiProvider).createProduct(publisher: _owner, name: draft.name, description: draft.description, pointsCost: draft.pointsCost, stock: draft.stock);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发布成功')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败：${formatErrorMessage(e)}')));
    }
  }

  Future<void> _exportSnapshot() async {
    try {
      final snapshot = await ref.read(storeApiProvider).exportSnapshot();
      final tasks = (snapshot['tasks'] as List? ?? const []).length;
      final products = (snapshot['products'] as List? ?? const []).length;
      final ledger = (snapshot['ledger'] as List? ?? const []).length;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('快照导出成功：任务 $tasks，商品 $products，流水 $ledger')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败：${formatErrorMessage(e)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);

    return Scaffold(
      appBar: AppBar(
        title: TitleWithHealth(
          title: '积分商城',
          status: _healthStatus ?? const BackendHealthStatus(online: false, statusCode: 0, statusText: '检查中'),
        ),
        actions: [
          if (!_isGuest) ...[
            TextButton.icon(onPressed: _showCreateProductPage, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('发布')),
            IconButton(tooltip: '我发布的商品', onPressed: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => StoreMyProductsPage(owner: _owner))).then((_) => _load()), icon: const Icon(Icons.inventory_2_outlined)),
            IconButton(tooltip: '兑换记录', onPressed: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => StoreOwnedRecordsPage(owner: _owner))).then((_) => _load()), icon: const Icon(Icons.history_rounded)),
            IconButton(tooltip: '导出快照', onPressed: _exportSnapshot, icon: const Icon(Icons.download_outlined)),
          ],
          if (appState.duoEnabled)
            Padding(padding: const EdgeInsets.only(right: 12), child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [ButtonSegment(value: 'me', label: Text('我')), ButtonSegment(value: 'partner', label: Text('搭档'))],
              selected: {appState.owner},
              onSelectionChanged: (v) => ref.read(appProvider.notifier).setOwner(v.first),
            )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            if (_refreshing) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator(minHeight: 2)),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: ErrorPanel(message: _error!, onRetry: _load)),
            _buildPointsCard(),
            const SizedBox(height: AppSpace.lg),
            SectionHeader(title: appState.duoEnabled ? '可兑换商品（搭档发布）' : '奖励区', subtitle: appState.duoEnabled ? '消耗积分并兑换奖励' : '先积累积分并准备奖励'),
            const SizedBox(height: AppSpace.sm),
            if (_loading && _market.isEmpty)
              const LoadingState()
            else if (appState.duoEnabled) ...[
              ..._market.map(_buildMarketItem),
              if (_market.isEmpty) _emptyCard('暂无可兑换商品'),
            ] else
              _emptyCard('单人模式下暂不开放双人兑换，邀请搭档后即可双向兑换。'),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A2B4F), Color(0xFF314772), Color(0xFF3C5484)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: const Text('PAIR REWARD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1.2))),
        const SizedBox(height: 12),
        Text(_owner == 'me' ? '我的积分余额' : '搭档积分余额', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        const Text('用任务积分兑换奖励，保持正向循环', style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 16),
        Row(children: [
          Icon(Icons.stars_rounded, color: Colors.white70, size: 16), const SizedBox(width: 4),
          Text('$_points', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)), const SizedBox(width: 4),
          const Text('当前积分', style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(width: 16),
          Icon(Icons.storefront_rounded, color: Colors.white70, size: 16), const SizedBox(width: 4),
          Text('${_market.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)), const SizedBox(width: 4),
          const Text('可兑换', style: TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildMarketItem(ProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
      decoration: AppSurface.card(),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: AppText.headline),
          const SizedBox(height: 5),
          Wrap(spacing: 6, runSpacing: 6, children: [_chip('库存 ${item.stock}', AppTheme.softBlue), _chip('${item.pointsCost} 积分', AppTheme.softAmber)]),
          if (item.description != null && item.description!.trim().isNotEmpty) ...[const SizedBox(height: 6), Text(item.description!, style: AppText.bodyMuted())],
        ])),
        const SizedBox(width: 10),
        FilledButton.tonal(onPressed: item.stock <= 0 ? null : () => _confirmAndExchange(item), child: Text(item.stock <= 0 ? '已售罄' : '兑换')),
      ]),
    );
  }

  Widget _emptyCard(String text) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), decoration: AppSurface.subtleCard(), child: Text(text, style: AppText.bodyMuted()));

  Widget _chip(String text, Color bg) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)));
}
