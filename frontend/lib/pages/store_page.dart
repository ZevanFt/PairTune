import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/health_api_service.dart';
import '../services/store_api_service.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/hero_panel.dart';
import '../widgets/shimmer_block.dart';
import 'product_form_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({
    super.key,
    required this.owner,
    required this.duoEnabled,
    required this.onOwnerChanged,
  });

  final String owner;
  final bool duoEnabled;
  final ValueChanged<String> onOwnerChanged;

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final _store = StoreApiService();
  final _healthApi = HealthApiService();
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  BackendHealthStatus? _healthStatus;

  int _points = 0;
  List<ProductItem> _market = [];
  List<ProductItem> _mine = [];
  List<OwnedItem> _owned = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner != widget.owner) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      if (_market.isEmpty && _mine.isEmpty && _owned.isEmpty) {
        _loading = true;
      } else {
        _refreshing = true;
      }
      _error = null;
    });

    try {
      final results = await Future.wait([
        _store.getPoints(widget.owner),
        _store.listMarketProducts(widget.owner),
        _store.listMyProducts(widget.owner),
        _store.listOwnedItems(widget.owner),
      ]);

      setState(() {
        _points = results[0] as int;
        _market = results[1] as List<ProductItem>;
        _mine = results[2] as List<ProductItem>;
        _owned = results[3] as List<OwnedItem>;
      });
    } catch (e) {
      setState(() => _error = formatErrorMessage(e));
    } finally {
      final health = await _healthApi.checkHealth();
      if (mounted) {
        setState(() {
          _healthStatus = health;
          _loading = false;
          _refreshing = false;
        });
      }
    }
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

  Future<void> _exchange(ProductItem item) async {
    try {
      await _store.exchange(buyer: widget.owner, productId: item.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('兑换成功：${item.name}')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('兑换失败：${formatErrorMessage(e)}')),
        );
      }
    }
  }

  Future<bool> _confirmExchange(ProductItem item) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '确认兑换',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                '请确认商品与积分信息',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.panelBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _metaChip('消耗 ${item.pointsCost} 积分', AppTheme.softViolet),
                        _metaChip('库存 ${item.stock}', AppTheme.softBlue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('确认兑换'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmAndExchange(ProductItem item) async {
    final confirmed = await _confirmExchange(item);
    if (!confirmed) return;
    await _exchange(item);
  }

  Future<bool> _confirmDelist(ProductItem item) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '下架商品',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                '下架后该商品将不会出现在兑换区',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.panelBorder),
                ),
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('确认下架'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed == true;
  }

  Future<void> _showCreateProductPage() async {
    final draft = await Navigator.push<ProductDraft>(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormPage()),
    );
    if (draft == null) return;

    try {
      await _store.createProduct(
        publisher: widget.owner,
        name: draft.name,
        description: draft.description,
        pointsCost: draft.pointsCost,
        stock: draft.stock,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('发布成功')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败：${formatErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _showEditProductPage(ProductItem item) async {
    final draft = await Navigator.push<ProductDraft>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(initial: item)),
    );
    if (draft == null) return;

    try {
      await _store.updateProduct(
        id: item.id,
        owner: widget.owner,
        name: draft.name,
        description: draft.description,
        pointsCost: draft.pointsCost,
        stock: draft.stock,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('商品更新成功')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('商品更新失败：${formatErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _delistProduct(ProductItem item) async {
    final confirmed = await _confirmDelist(item);
    if (!confirmed) return;

    try {
      await _store.deleteProduct(id: item.id, owner: widget.owner);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('商品已下架')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下架失败：${formatErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _exportSnapshot() async {
    try {
      final snapshot = await _store.exportSnapshot();
      final tasks = (snapshot['tasks'] as List<dynamic>? ?? const []).length;
      final products =
          (snapshot['products'] as List<dynamic>? ?? const []).length;
      final ledger = (snapshot['ledger'] as List<dynamic>? ?? const []).length;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('快照导出成功：任务 $tasks，商品 $products，流水 $ledger')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：${formatErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitleWithHealth('积分商城'),
        actions: [
          TextButton.icon(
            onPressed: _showCreateProductPage,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('发布'),
          ),
          IconButton(
            tooltip: '导出快照',
            onPressed: _exportSnapshot,
            icon: const Icon(Icons.download_outlined),
          ),
          if (widget.duoEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'me', label: Text('我')),
                  ButtonSegment(value: 'partner', label: Text('搭档')),
                ],
                selected: {widget.owner},
                onSelectionChanged: (value) {
                  widget.onOwnerChanged(value.first);
                },
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
              if (_refreshing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildErrorPanel(_error!),
                ),
              _buildPointsCard(),
              const SizedBox(height: 16),
              _buildSectionHeader(
                widget.duoEnabled ? '可兑换商品（搭档发布）' : '奖励区',
                widget.duoEnabled ? '消耗积分并兑换奖励' : '先积累积分并准备奖励',
              ),
              const SizedBox(height: 8),
              if (widget.duoEnabled) ...[
                if (_loading && _market.isEmpty)
                  ..._buildListSkeletons()
                else ...[
                  ..._market.map(_buildMarketItem),
                  if (_market.isEmpty) _buildEmptyCard('暂无可兑换商品'),
                ],
              ] else
                _buildEmptyCard('单人模式下暂不开放双人兑换，邀请搭档后即可双向兑换。'),
              const SizedBox(height: 16),
              _buildSectionHeader('我发布的商品', '维护商品并管理上架状态'),
              const SizedBox(height: 8),
              if (_loading && _mine.isEmpty)
                ..._buildListSkeletons()
              else ...[
                ..._mine.map(_buildMyProductItem),
                if (_mine.isEmpty) _buildEmptyCard('你还没发布商品'),
              ],
              const SizedBox(height: 16),
              _buildSectionHeader('已兑换记录', '追踪每一次积分兑换'),
              const SizedBox(height: 8),
              if (_loading && _owned.isEmpty)
                ..._buildListSkeletons()
              else ...[
                ..._owned.map(_buildOwnedItem),
                if (_owned.isEmpty) _buildEmptyCard('暂无兑换记录'),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildListSkeletons() {
    return [
      const ShimmerBlock(height: 102),
      const SizedBox(height: 8),
      const ShimmerBlock(height: 102),
    ];
  }

  Widget _buildPointsCard() {
    return HeroPanel(
      tag: 'PAIR REWARD',
      title: widget.owner == 'me' ? '我的积分余额' : '搭档积分余额',
      subtitle: '用任务积分兑换奖励，保持正向循环',
      metrics: [
        HeroMetricData(
          icon: Icons.stars_rounded,
          label: '当前积分',
          value: '$_points',
        ),
        HeroMetricData(
          icon: Icons.storefront_rounded,
          label: '可兑换',
          value: '${_market.length}',
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
              style: AppText.sectionTitle,
            ),
            Text(
              subtitle,
              style: AppText.sectionSubtitle,
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
      decoration: AppSurface.subtleCard(),
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

  Widget _buildMarketItem(ProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppSurface.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _metaChip('库存 ${item.stock}', AppTheme.softBlue),
                    _metaChip('${item.pointsCost} 积分', AppTheme.softAmber),
                  ],
                ),
                if (item.description != null && item.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description!,
                    style: AppText.bodyMuted,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(
            onPressed: item.stock <= 0 ? null : () => _confirmAndExchange(item),
            child: Text(item.stock <= 0 ? '已售罄' : '兑换'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProductItem(ProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppSurface.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _metaChip('库存 ${item.stock}', AppTheme.softBlue),
                    _metaChip('${item.pointsCost} 积分', AppTheme.softAmber),
                  ],
                ),
              ],
            ),
          ),
          _productMoreMenu(item),
        ],
      ),
    );
  }

  Widget _buildOwnedItem(OwnedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppSurface.subtleCard(shadow: true),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppText.cardTitle,
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt),
                  style: AppText.sectionSubtitle,
                ),
              ],
            ),
          ),
          Text(
            '-${item.pointsSpent}',
            style: const TextStyle(
              color: AppTheme.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: AppText.chipText,
      ),
    );
  }

  Widget _productMoreMenu(ProductItem item) {
    return PopupMenuButton<String>(
      tooltip: '更多操作',
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      onSelected: (value) {
        if (value == 'edit') {
          _showEditProductPage(item);
        } else if (value == 'delist') {
          _delistProduct(item);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.edit_outlined, size: 18),
            title: Text('编辑商品'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'delist',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.delete_outline, size: 18),
            title: Text('下架商品'),
          ),
        ),
      ],
    );
  }
}
