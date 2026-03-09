import 'package:flutter/material.dart';

import '../services/store_api_service.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/shimmer_block.dart';
import 'product_form_page.dart';

class StoreMyProductsPage extends StatefulWidget {
  const StoreMyProductsPage({super.key, required this.owner});

  final String owner;

  @override
  State<StoreMyProductsPage> createState() => _StoreMyProductsPageState();
}

class _StoreMyProductsPageState extends State<StoreMyProductsPage> {
  final _store = StoreApiService();
  bool _loading = true;
  String? _error;
  List<ProductItem> _list = [];

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
      final list = await _store.listMyProducts(widget.owner);
      setState(() => _list = list);
    } catch (e) {
      setState(() => _error = formatErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
              AppSpace.h4,
              const Text(
                '下架后该商品将不会出现在兑换区',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              AppSpace.h12,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: AppSurface.subtleCard(alpha: 1),
                child: Text(item.name, style: AppText.cardTitle),
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
                  AppSpace.w10,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我发布的商品'),
        actions: [
          TextButton.icon(
            onPressed: _showCreateProductPage,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('发布'),
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
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              if (_error != null)
                _InfoCard(
                  text: '加载失败：$_error',
                  danger: true,
                ),
              if (_loading && _list.isEmpty) ...[
                const ShimmerBlock(height: 92),
                AppSpace.h8,
                const ShimmerBlock(height: 92),
              ] else ...[
                ..._list.map(_buildProductCard),
                if (_list.isEmpty) const _InfoCard(text: '你还没有发布商品'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppSurface.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppText.cardTitle),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip('库存 ${item.stock}', AppTheme.softBlue),
                    _chip('${item.pointsCost} 积分', AppTheme.softAmber),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditProductPage(item);
              } else {
                _delistProduct(item);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined, size: 18),
                  title: Text('编辑商品'),
                ),
              ),
              PopupMenuItem(
                value: 'delist',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline, size: 18),
                  title: Text('下架商品'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: AppText.chipText),
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

