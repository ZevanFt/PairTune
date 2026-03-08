import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/health_api_service.dart';
import '../services/store_api_service.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/shimmer_block.dart';

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

  Widget _buildHealthBadge() {
    final status = _healthStatus;
    final online = status?.online == true;
    final color = status == null
        ? Colors.grey
        : (online ? AppTheme.success : AppTheme.danger);
    final text = status == null
        ? '检测中'
        : (online
              ? '后端正常'
              : '${status.statusCode == 0 ? '离线' : status.statusCode} ${status.statusText}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E0D6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showProductFormDialog({
    required String title,
    required String submitText,
    required TextEditingController nameController,
    required TextEditingController descController,
    required TextEditingController pointsController,
    required TextEditingController stockController,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _buildDialogShell(
        title: title,
        subtitle: '请完整填写商品信息',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameController, '商品名称'),
            const SizedBox(height: 10),
            _dialogField(descController, '描述'),
            const SizedBox(height: 10),
            _dialogField(
              pointsController,
              '所需积分',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _dialogField(
              stockController,
              '库存',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(submitText),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _buildDialogShell(
        title: title,
        subtitle: '操作后将立即生效',
        content: Text(
          message,
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogShell({
    required String title,
    required String subtitle,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: const Color(0xFFFFFCF8),
      titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      actionsPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
      content: SingleChildScrollView(child: content),
      actions: actions,
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
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

  Future<void> _showCreateProductDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final pointsController = TextEditingController();
    final stockController = TextEditingController();

    final confirmed = await _showProductFormDialog(
      title: '发布商品',
      submitText: '发布',
      nameController: nameController,
      descController: descController,
      pointsController: pointsController,
      stockController: stockController,
    );

    if (confirmed != true) return;

    try {
      await _store.createProduct(
        publisher: widget.owner,
        name: nameController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        pointsCost: int.tryParse(pointsController.text.trim()) ?? 0,
        stock: int.tryParse(stockController.text.trim()) ?? 0,
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

  Future<void> _showEditProductDialog(ProductItem item) async {
    final nameController = TextEditingController(text: item.name);
    final descController = TextEditingController(text: item.description ?? '');
    final pointsController = TextEditingController(text: '${item.pointsCost}');
    final stockController = TextEditingController(text: '${item.stock}');

    final confirmed = await _showProductFormDialog(
      title: '编辑商品',
      submitText: '保存',
      nameController: nameController,
      descController: descController,
      pointsController: pointsController,
      stockController: stockController,
    );

    if (confirmed != true) return;

    try {
      await _store.updateProduct(
        id: item.id,
        owner: widget.owner,
        name: nameController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        pointsCost: int.tryParse(pointsController.text.trim()) ?? 0,
        stock: int.tryParse(stockController.text.trim()) ?? 0,
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
    final confirmed = await _showConfirmDialog(
      title: '下架商品',
      message: '确认下架「${item.name}」吗？',
      confirmText: '确认下架',
    );
    if (confirmed != true) return;

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
        title: const Text('积分商城'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildHealthBadge(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProductDialog,
        label: const Text('发布商品'),
        icon: const Icon(Icons.add_business_outlined),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFBF4), Color(0xFFFFF7F1), Color(0xFFF0F7FF)],
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
                widget.duoEnabled ? '把积分换成你们的奖励' : '先积累积分并发布奖励',
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
              _buildSectionHeader('我发布的商品', '你可以编辑或下架自己发布的奖励'),
              const SizedBox(height: 8),
              if (_loading && _mine.isEmpty)
                ..._buildListSkeletons()
              else ...[
                ..._mine.map(_buildMyProductItem),
                if (_mine.isEmpty) _buildEmptyCard('你还没发布商品'),
              ],
              const SizedBox(height: 16),
              _buildSectionHeader('已兑换记录', '记录每一次积分消费'),
              const SizedBox(height: 8),
              if (_loading && _owned.isEmpty)
                ..._buildListSkeletons()
              else ...[
                ..._owned.map(_buildOwnedItem),
                if (_owned.isEmpty) _buildEmptyCard('暂无兑换记录'),
              ],
              const SizedBox(height: 88),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF16213A), Color(0xFF2D426D), Color(0xFF3E5688)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2C2B3458),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppTheme.sky,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppTheme.ink,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.owner == 'me' ? '我的积分' : '搭档积分',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_points',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x2EFFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PAIR REWARD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
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
        color: Colors.white.withValues(alpha: 0.86),
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

  Widget _buildMarketItem(ProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DFD2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _metaChip('库存 ${item.stock}', const Color(0xFFEAF2FF)),
                    _metaChip('${item.pointsCost} 积分', const Color(0xFFFFF3E2)),
                  ],
                ),
                if (item.description != null && item.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(
            onPressed: item.stock <= 0 ? null : () => _exchange(item),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DFD2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _metaChip('库存 ${item.stock}', const Color(0xFFEAF2FF)),
                    _metaChip('${item.pointsCost} 积分', const Color(0xFFFFF3E2)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '编辑',
            onPressed: () => _showEditProductDialog(item),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '下架',
            onPressed: () => _delistProduct(item),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnedItem(OwnedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9E0D4)),
      ),
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
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
